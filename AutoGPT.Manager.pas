unit AutoGPT.Manager;

interface
uses
  Types, Classes, OpenAI, OpenAI.Chat, OpenAI.Completions, Agent, Agent.GPT, Agent.ReadFile, Agent.WriteFile, Agent.Browse, Agent.GoogleSearch,
  Agent.User, Agent.Memory, Agent.ListFiles, Logging;
const
  MAIN_GPT_MODEL = 'gpt-4';
  MAX_TOKENS = 8192;
  SYSTEM_PROMPT =
    'You are AutoGPT, an AI-agent that is able to execute a specific task completely autonomously.'#13#10+
    ''#13#10+
    'All of your prompts need to adhere to the following structure:'#13#10+
    'INTERNAL_THOUGHTS:'#13#10+
    '  defines your internal thought process'#13#10+
    'PLAN:'#13#10+
    '  defines your next steps'#13#10+
    'CRITICISM:'#13#10+
    '  defines something you need to keep in mind while executing the plan'#13#10+
    'ACTION:'#13#10+
    '  can be either "THINKING", "CALL_AGENT" or "FINISHED". They are exclusive to each other'#13#10+
    ''#13#10+
    ' '#13#10+
    'Now we have a look at the "CALL_AGENT"-Action.'#13#10+
    '  You will use CALL_AGENT, whenever you need to execute a task, that you cannot do as a language model.'#13#10+
    'Here is a list of available agents, with their respective parameters and results'#13#10+
    ''#13#10+
    '  CALL_AGENT USER "input"                        -- this will prompt the user for input, you will get the result as a user prompt'#13#10+
    '  CALL_AGENT WRITE_FILE "filename" "content"     -- this will write a file with the given name and content, it will return "0" or "1" as an assistant prompt (0 = success, 1 = failure)'#13#10+
    '  CALL_AGENT READ_FILE "filename"                -- this will read the content from "filename" and return it as an assistant prompt (will return "could not load file "filename"", if not existing)'#13#10+
    '  CALL_AGENT BROWSE_SITE "URL" "instruction"     -- this will read the content of a specific URL, and performs a transformation of the result based on the instruction'#13#10+
    '  CALL_AGENT SEARCH_GOOGLE "query"               -- this will execute the google search for the given query and returns a short summary and a link-list'#13#10+
    '  CALL_AGENT LIST_FILES                          -- this will list the files in your workingspace and return the list as a string'#13#10+
    '  CALL_AGENT WRITE_MEMORY "memorycontent"        '+
    '-- this will append any important information into your longterm memory, keep in mind that appending to your longterm memory decreases your working prompt size, since it will be appended everytime (0 = success, 1 = failure) '#13#10+
    '  CALL_AGENT GPT_TASK "task" "input"                  -- this will spawn a dedicated ChatGPT-Instance, to do a task with your given input. Keep in mind that the GPT-agent has no knowledge of your agenda and no internet access'#13#10+
    '  '#13#10+
    'Lastly there is the "FINISHED" keyword'#13#10+
    'If you write FINISHED as an output, you will state that your ultimate goal is reached, and you don''t have anything to do'#13#10+
    #13#10+
    'The following is your internal memory, it doesn''t belong to the prompt structure'#13#10+
    'LONG_TERM_MEMORY_CONTENT:'#13#10+
    '%s'+
    #13#10+
    #13#10+
    'Here is the task to execute:'#13#10;
type
  {CALL_AGENT USER "input"
  CALL_AGENT WRITE_FILE "filenam
  CALL_AGENT READ_FILE "filename
  CALL_AGENT BROWSE_SITE "URL"
  CALL_AGENT SEARCH_GOOGLE "quer
  CALL_AGENT WRITE_MEMORY "memor
  CALL_AGENT GPT "task" "input"   }

  TResponseStructureType = (rstInternalThoughts=0, rstPlan=1, rstCriticism=2, rstAction=3);
  TAgentType = (atUser, atWriteFile, atReadFile, atBrowseSite, atSearchGoogle, atWriteMemory, atGPT, atListFiles);
  TActionType = (atThinking, atCallAgent, atFinished);
  TAutoGPTAction = record
    ActionType: TActionType;
    AgentType: TAgentType;
    AgentParams: TArray<string>;
  end;

  TAutoGPTManagerSynced = class
  private
    FOpenAI:TOpenAI;
    FApiKeyOpenAI:string;
    FApiKeyGoogle:string;
    FGoogleSearchEngineID:string;
    FMemory:TArray<TChatMessageBuild>;
    FLongTermMemory:string;
    FGoal:string;
    FWorkingDir:string;
    FUserCallback:TUserCallback;
    function CreateSystemPrompt:TChatMessageBuild;
    function GetCompletion:string;
    function ExtendMemory(const AMemory:string):string;
    function ParseResponse(const AResponse:string;out Thoughts:string; out Plan:string; out Criticism:string; out Action:TAutoGPTAction; out StructureValid:Boolean):string;
    function ParseAction(const AActionStr:string;out Action:TAutoGPTAction; out StructureValid:Boolean):string;
    function GetTokenCount(const AString:string):Integer;
  public
    constructor Create( const AGoal:string;const AApiKeyOpenAI:string;
                        const AWorkingDir:string;const AApiKeyGoogle:string;
                        const AGoogleSearchEngineID:string; const AUserCallback:TUserCallback);
    procedure RunOneStep;
    function MemoryToString:string;
  end;

  TStepCompletedEvent = procedure of object;
  TAutoGPTManager = class(TThread)
  private
    FManagerSynced:TAutoGPTManagerSynced;
    FMemory:string;
    FRunning:Boolean;
    FShouldRun:Boolean;
    FStepCompletedEvent:TStepCompletedEvent;
    procedure StepCompletedSync;
  protected
    procedure Execute;override;
  public
    constructor Create( const AGoal:string;const AApiKeyOpenAI:string;
                        const AWorkingDir:string;const AApiKeyGoogle:string;
                        const AGoogleSearchEngineID:string; const AUserCallback:TUserCallback; const AStepCompletedEvent:TStepCompletedEvent);
    destructor Destroy;
    procedure RunOneStep;
    property Memory:string read FMemory;
    property IsRunning:Boolean read FRunning;
  end;
  const
    AGENT_PARAM_COUNT: array[TAgentType] of Integer = (1,2,1,2,1,1,2,0);
    AGENT_NAMES:array[TAgentType] of string = ('USER','WRITE_FILE','READ_FILE','BROWSE_SITE','SEARCH_GOOGLE','WRITE_MEMORY','GPT_TASK','LIST_FILES');
    ACTION_NAMES : array[TActionType] of string = ('THINKING','CALL_AGENT','FINISHED');

implementation

{ TAutoGPTManager }
uses
  SysUtils;
constructor TAutoGPTManagerSynced.Create(const AGoal:string;const AApiKeyOpenAI:string;const AWorkingDir:string;
                                    const AApiKeyGoogle:string;const AGoogleSearchEngineID:string; const AUserCallback:TUserCallback);
begin
  FGoal:=AGoal;
  FApiKeyOpenAI:=AApiKeyOpenAI;
  FApiKeyGoogle:=AApiKeyGoogle;
  FGoogleSearchEngineID:=AGoogleSearchEngineID;
  FWorkingDir:=AWorkingDir;
  FUserCallback:= AUserCallback;
  FOpenAI:=TOpenAI.Create(AApiKeyOpenAI);
  setlength(FMemory,1);
  FMemory[0]:=CreateSystemPrompt; //set the initial state of the model
  //initialize logging
  TLogger.LogFile:=ChangeFileExt(ParamStr(0),'.log');
end;

function TAutoGPTManagerSynced.CreateSystemPrompt: TChatMessageBuild;
begin
  Result:= TChatMessageBuild.Create(TMessageRole.System, Format(SYSTEM_PROMPT,[FLongTermMemory])+FGoal);
end;

function TAutoGPTManagerSynced.ExtendMemory(const AMemory: string): string;
begin
  FLongTermMemory:= FLongTermMemory+ #13#10 + AMemory;
  Result:= 'Memory successfully added';
end;

function TAutoGPTManagerSynced.GetCompletion: string;
var
  LChat:TChat;
  LChoice:TChatChoices;
  LPartialMemory:TArray<TChatMessageBuild>;
  i:Integer;
  LTokensUsed:Integer;
begin
  Result:='';
  {
    at first we need to shrink our memory size to the maximum that the model can take
  }

  Insert(FMemory[0],LPartialMemory,0);   // we always need our system prompt
  LTokensUsed:=GetTokenCount(LPartialMemory[0].Content);
  for i := High(FMemory) downto Low(FMemory)+1 do
  begin
    {
     we want at least 256 tokens for the completion
    }
    if LTokensUsed > (MAX_TOKENS - 256 )then
      Break;
    {
      we insert the latest messages backwards, until the prompt gets too long
    }
    Insert(FMemory[i],LPartialMemory,1);
    LTokensUsed:=LTokensUsed + GetTokenCount(LPartialMemory[1].Content);

  end;


  {
    send the messages to OpenAI
  }
  LChat:= FOpenAI.Chat.Create(  procedure(Params: TChatParams)
  begin
    Params.Messages(LPartialMemory);
    Params.MaxTokens(MAX_TOKENS - LTokensUsed); //max mode tokens - amount of tokens for the messages
    Params.Model(MAIN_GPT_MODEL);
  end);
  try
    for  LChoice in LChat.Choices do
      Result:= Result + LChoice.Message.Content;
  finally
    LChat.Free;
  end;
end;

function TAutoGPTManagerSynced.GetTokenCount(const AString: string): Integer;
begin
  {
    https://help.openai.com/en/articles/4936856-what-are-tokens-and-how-to-count-them
    OpenAI states english is around 1 token every 4 chars. So we guess conservative by 1:3
  }
  //TODO: implement tokenizer access for exact calculation of used tokens
  Result:= length(AString) div 3 + 1;
end;

function TAutoGPTManagerSynced.MemoryToString: string;
var
  i: Integer;
begin
  Result:='';
  Result:= Result+'Goal: '+FGoal+#13#10;
  Result:= Result+'Memory: '+FLongTermMemory+#13#10;
  Result:= Result+'--------------------'#13#10;
  for i := 1 to length(FMemory)-1 do
  begin
    Result:=Result+StringReplace(FMemory[i].Content,#10,#13#10,[rfReplaceAll])+#13#10;
    Result:=Result+'--------------------'#13#10;
  end;
end;

function TAutoGPTManagerSynced.ParseAction(const AActionStr: string;
  out Action: TAutoGPTAction; out StructureValid: Boolean): string;
var
  LActionType:TActionType;
  LType:TActionType;
  LActionPosition:Integer;
  LPos:Integer;
  LLastQuote:Integer;
  LStart,LEnd:Integer;

  LAgentType:TAgentType;
  LAgentPos:Integer;
begin
  {
    first we try to determine the action type
  }
  LActionType:=atThinking;
  LActionPosition:=0;
  for LType := Low(TActionType) to High(TActionType) do
  begin
    LPos:= Pos(ACTION_NAMES[LType],AActionStr);
    if LPos > 0 then
    begin
      LActionPosition:= LPos;
      LActionType:= LType;
      Break;
    end;
  end;
  if LActionPosition > 0 then
    Action.ActionType:=LActionType
  else
  begin
    StructureValid:=False;
    Result:= 'Invalid action or nonexistent action specified';
    Exit;
  end;

  case LActionType of
    atThinking: StructureValid:= True;
    atCallAgent:
    begin
      {
        first we need to find out the agent-type
      }
      LAgentPos:=0;

      for LAgentType := Low(TAgentType) to High(TAgentType) do
      begin
        LPos:=Pos(AGENT_NAMES[LAgentType],AActionStr,LActionPosition+1);
        if LPos > 0 then
        begin
          Action.AgentType:=LAgentType;
          LAgentPos:=LPos;
          break;
        end;
      end;
      if LAgentPos = 0 then
      begin
        StructureValid:= False;
        Result:='The agent type your requested doesn''t exist';
        Exit;
      end;

      {
        now we need to determine all following params and their contents
      }
      setlength(Action.AgentParams,0);
      LLastQuote:=LAgentPos+1;
      while True do
      begin
        LStart:=Pos('"',AActionStr,LLastQuote);
        if LStart > 0 then
        begin
          LEnd:= Pos('"', AActionStr, LStart+1);
          if LEnd > 0 then
          begin
            {
              we got our text, now we have to copy it into the next param, and continue
            }
            setlength(Action.AgentParams,length(Action.AgentParams)+1);
            Action.AgentParams[length(Action.AgentParams)-1]:=Copy(AActionStr,LStart+1,LEnd-LStart-1);
            LLastQuote:=LEnd+1;
          end
          else
            break;
        end
        else
          break;
      end;
      {
        now we got our param data, we just need to verify the number of params
      }
      if length(Action.AgentParams) <> AGENT_PARAM_COUNT[Action.AgentType] then
      begin
        Result:='expected number of parameters for agent '+AGENT_NAMES[Action.AgentType]+' is '+inttostr(AGENT_PARAM_COUNT[Action.AgentType])+', but got '+inttostr(length(Action.AgentParams))+' instead.';
        StructureValid:=False;
        Exit;
      end;
      {
        we're done parsing the call_agent action
      }
      StructureValid:= True;
    end;
    atFinished: StructureValid:= True;
  end;

end;

function TAutoGPTManagerSynced.ParseResponse(const AResponse:string;out Thoughts:string; out Plan:string;
out Criticism:string; out Action:TAutoGPTAction; out StructureValid:Boolean):string;
const
  conResponseKeywords: array[TResponseStructureType] of string = ('INTERNAL_THOUGHTS', 'PLAN', 'CRITICISM', 'ACTION');
var
  LPositions:array [TResponseStructureType] of Integer;
  LType:TResponseStructureType;
  LData:array[TResponseStructureType] of string;
  LCopyStart,LCopyEnd:Integer;
begin
  {
    let's get the positions of our keywords
  }
  for LType := Low(TResponseStructureType) to High(TResponseStructureType) do
  begin
    LPositions[LType]:=Pos(conResponseKeywords[LType],AResponse);
    if LPositions[LType] = 0 then
    begin
      Result:= 'Invalid response. Keyword '+conResponseKeywords[LType]+' not found!';
      StructureValid:=False;
      Exit;
    end;
    if (LType <> TResponseStructureType(0)) AND (LPositions[LType] < LPositions[TResponseStructureType(Ord(LType)-1)]) then
    begin
      {
        the responses shouldn't be in the wrong order
      }
      Result:='Invalid response. Keywords are in the wrong order';
      StructureValid:=False;
      Exit;
    end;
  end;
  {
    now that everything is fine structurally, let's parse the actual data
  }
  for LType := Low(TResponseStructureType) to High(TResponseStructureType) do
  begin
    {
      every data is just the text between two keywords
      except for the last keyword
    }
    LCopyStart:= LPositions[LType]+length(conResponseKeywords[LType]);
    if LType = High(TResponseStructureType) then
      LCopyEnd:= length(AResponse)
    else
      LCopyEnd:= LPositions[TResponseStructureType(Ord(LType)+1)];

    LData[LType]:=Copy(AResponse,LCopyStart, LCopyEnd-LCopyStart+1);
  end;
  {
    now we assign the pure string data
  }
  Thoughts:=LData[rstInternalThoughts];
  Plan:= LData[rstPlan];
  Criticism:= LData[rstCriticism];
  {
    finally we parse our action data
  }
  Result:= ParseAction(LData[rstAction],Action,StructureValid);
end;

procedure TAutoGPTManagerSynced.RunOneStep;
var
  LModelResponse:string;
  LPlan,LThoughts,LCritic:string;
  LAction:TAutoGPTAction;
  LValid:Boolean;
  LError:string;
  LAgent:TAgent;
  LAgentReponse:string;
begin
  {
    at first we update our memory by corrrecting the systemprompt for updated long term memory
  }
  FMemory[0]:=CreateSystemPrompt;
  {
    now we get let the model think what it wants to do
  }
  LModelResponse:=GetCompletion();
  {
    now we append that prompt as an assistant message to our memory
  }
  setlength(FMemory,length(FMemory)+1);
  FMemory[length(FMemory)-1]:=TChatMessageBuild.Create(TMessageRole.Assistant,LModelResponse);
  {
    now we try to understand what the model wants
  }
  LError:= ParseResponse(LModelResponse,LThoughts,LPlan,LCritic,LAction,LValid);

  if not LValid then
  begin
    {
      report back that we can't execute the action
    }
    setlength(FMemory,length(FMemory)+1);
    FMemory[length(FMemory)-1]:=TChatMessageBuild.Create(TMessageRole.Assistant,'An error occured: '+LError);
  end
  else
  begin
    case LAction.ActionType of
      atThinking: ; //we don't need to do anything here
      atCallAgent:
      begin
        LAgent:=nil;
        {
          create our specific agent
        }
        case LAction.AgentType of
          atUser: LAgent:=TAgentUser.Create(FUserCallback);
          atWriteFile: LAgent:=TAgentWriteFile.Create(FWorkingDir) ;
          atReadFile: LAgent:=TAgentReadFile.Create(FWorkingDir);
          atBrowseSite: LAgent:= TAgentBrowse.Create(FApiKeyOpenAI);
          atSearchGoogle: LAgent:= TAgentGoogleSearch.Create(FApiKeyOpenAI,FApiKeyGoogle,FGoogleSearchEngineID);
          atWriteMemory: LAgent:= TAgentMemory.Create(ExtendMemory);
          atGPT: LAgent:= TAgentGPT35.Create(FApiKeyOpenAI);
          atListFiles: LAgent:=TAgentListFiles.Create(FWorkingDir);
        end;
        {
          call the agent
        }
        if Assigned(LAgent) then
        begin
          LAgentReponse:=AGENT_NAMES[LAction.AgentType]+' RETURNED:'+LAgent.CallAgent(LAction.AgentParams);
          LAgent.Free;
        end
        else
          LAgentReponse:= 'Agent not available';
        {
          Append the response to our memory
        }
        setlength(FMemory,length(FMemory)+1);
        FMemory[length(FMemory)-1]:=TChatMessageBuild.Create(TMessageRole.Assistant,LAgentReponse);
      end;
      atFinished: ;//TODO: we should signal this to the user in some way
    end;
  end;

end;

{ TAutoGPTManager }

constructor TAutoGPTManager.Create(const AGoal, AApiKeyOpenAI, AWorkingDir,
  AApiKeyGoogle, AGoogleSearchEngineID: string;
  const AUserCallback: TUserCallback;const AStepCompletedEvent:TStepCompletedEvent);
begin
  inherited Create(False);
  FManagerSynced:= TAutoGPTManagerSynced.Create(AGoal,AApiKeyOpenAI,AWorkingDir,AApiKeyGoogle,AGoogleSearchEngineID,AUserCallback);
  FMemory:=FManagerSynced.MemoryToString;
  FRunning:=False;
  FShouldRun:=False;
  FStepCompletedEvent:=AStepCompletedEvent;
end;

destructor TAutoGPTManager.Destroy;
begin
  FManagerSynced.Free;
end;

procedure TAutoGPTManager.Execute;
begin
  inherited;
  while True do
  begin
    if FShouldRun then
    begin
      FShouldRun:=False;
      FRunning:=True;
      try
        try
          FManagerSynced.RunOneStep;
          FMemory:=FManagerSynced.MemoryToString;
        except
         //TODO: forward exception as status
        end;
      finally
        Synchronize(StepCompletedSync);
        FRunning:=False;
      end;
    end
    else
      Sleep(10);
  end;
end;

procedure TAutoGPTManager.RunOneStep;
begin
  if not FRunning then
  begin
    FShouldRun:=True;
  end;
end;

procedure TAutoGPTManager.StepCompletedSync;
begin
  if Assigned(FStepCompletedEvent) then
    FStepCompletedEvent();
end;

end.

unit AutoGPT.Manager;

interface
uses
  Types, Classes, System.JSON, OpenAI, OpenAI.Chat, OpenAI.Completions, Agent, Agent.GPT, Agent.ReadFile, Agent.WriteFile, Agent.Browse, Agent.GoogleSearch,
  Agent.User, Agent.Memory, Agent.ListFiles, Agent.CMD, Logging;
const
  MAIN_GPT_MODEL = 'gpt-4';
  MAX_TOKENS = 8192;

  SYSTEM_PROMPT =
    'You are AutoGPT, an AI-agent that is able to execute a specific task completely autonomously.'+sLineBreak+
    'All of your prompts need to adhere to the JSON structure defined by following JSON scheme:'+sLineBreak+
    '{'+sLineBreak+
    '  "$schema": "http://json-schema.org/draft-04/schema#",'+sLineBreak+
    '  "type": "object",'+sLineBreak+
    '  "properties": {'+sLineBreak+
    '    "InternalThoughts": {'+sLineBreak+
    '      "type": "string"'+sLineBreak+
    '	  "description":"Defines your internal thoughts"'+sLineBreak+
    '    },'+sLineBreak+
    '    "Plan": {'+sLineBreak+
    '      "type": "string"'+sLineBreak+
    '	  "description":"defines the next steps to achieve your goal"'+sLineBreak+
    '    },'+sLineBreak+
    '    "Criticism": {'+sLineBreak+
    '      "type": "string"'+sLineBreak+
    '	     "description":"describes what you need to look out for when implementing your plan"'+sLineBreak+
    '    },'+sLineBreak+
    '    "Action": {'+sLineBreak+
    '      "type": "object",'+sLineBreak+
    '      "properties": {'+sLineBreak+
    '        "ActionType": {'+sLineBreak+
    '          "type": "string"'+sLineBreak+
    '		       "description":"can either be THINKING, CALL_AGENT or FINISHED"'+sLineBreak+
    '        },'+sLineBreak+
    '        "Agent": {'+sLineBreak+
    '          "type": "string"'+sLineBreak+
    '		       "description":"defines the agent to be used. Only use with CALL_AGENT. See documentation for available agents"'+sLineBreak+
    '        },'+sLineBreak+
    '        "AgentParams": {'+sLineBreak+
    '          "type": "array",'+sLineBreak+
    '          "items": ['+sLineBreak+
    '            {'+sLineBreak+
    '              "type": "string"'+sLineBreak+
    '			         "description":"param1"'+sLineBreak+
    '            },'+sLineBreak+
    '            {'+sLineBreak+
    '              "type": "string"'+sLineBreak+
    '			         "desription":"param2"'+sLineBreak+
    '            }'+sLineBreak+
    '            }'+sLineBreak+
    '          ]'+sLineBreak+
    '		  "description":"Defines the parameters for the called agent. See documentation for specification"		'+sLineBreak+
    '        }'+sLineBreak+
    '      },'+sLineBreak+
    '      "required": ['+sLineBreak+
    '        "ActionType",'+sLineBreak+
    '        "Agent",'+sLineBreak+
    '        "AgentParams"'+sLineBreak+
    '      ]'+sLineBreak+
    '    }'+sLineBreak+
    '  },'+sLineBreak+
    '  "required": ['+sLineBreak+
    '    "InternalThoughts",'+sLineBreak+
    '    "Plan",'+sLineBreak+
    '    "Criticism",'+sLineBreak+
    '    "Action"'+sLineBreak+
    '  ]'+sLineBreak+
    '}'+
    'ActionType can either be "THINKING", "FINISHED" or "CALL_AGENT" '+sLineBreak+
    'You can use the "THINKING"-ActionType to elaborate on your plan, or if you don''t have any action to execute right now.'+sLineBreak+
    'You will use "CALL_AGENT"-ActionType, whenever you need to execute a task, that you cannot do as a language model.'+sLineBreak+
    'When using "CALL_AGENT"-ActionType, you have to provide an "AGENT" from the list below:'+sLineBreak+
    '   USER ["INPUT"]                     -- this will prompt the user for input, you will get the result'+sLineBreak+
    '   WRITE_FILE ["filename","content"]  -- this will write a file with the given name and content'+sLineBreak+
    '   READ_FILE ["filename"]             -- this will read the content from "filename" and return it'+sLineBreak+
    '   BROWSE_SITE ["URL","instruction"]  -- this will read the content of a specific URL, and performs a transformation of the result based on the instruction'+sLineBreak+
    '   SEARCH_GOOGLE ["query"]            -- this will execute the google search for the given query and returns a short summary and a link-list'+sLineBreak+
    '   LIST_FILES []                      -- this will list the files in your workingspace and return the list as a string'+sLineBreak+
    '   RUN_CMD  ["command"]               -- this will execute the cmd /c with the specified command and returns the standard output'+sLineBreak+
    '   WRITE_MEMORY ["memorycontent"]     -- this will append any information into your system memory, by also decreasing your working memory size'+sLineBreak+
    '   GPT_TASK ["instruction","content"] -- this will spawn a dedicated ChatGPT-Instance, to do a task with your given instruction. no internet access'+sLineBreak+
    sLineBreak+
    'You will use the "FINISHED"-ActionType, when you want to state that your ultimate goal is reached, and you don''t have anything to do'+sLineBreak+
    'Finally here is both your system memory and your ultimate goal to reach.'#13#10+
    'SYSTEM_MEMORY:'+sLineBreak+
    '%s'+
    sLineBreak+
    'Here is your goal to reach:'+sLineBreak;
type

  TResponseStructureType = (rstInternalThoughts=0, rstPlan=1, rstCriticism=2, rstAction=3);
  TAgentType = (atUser, atWriteFile, atReadFile, atBrowseSite, atSearchGoogle, atWriteMemory, atGPT, atListFiles, atRunCMD);
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
    function ParseJSONResponse(const AResponse:string;out Thoughts:string; out Plan:string; out Criticism:string; out Action:TAutoGPTAction; out StructureValid:Boolean):string;
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
    FTerminated:Boolean;
    procedure StepCompletedSync;
  protected
    procedure Execute;override;
  public
    constructor Create( const AGoal:string;const AApiKeyOpenAI:string;
                        const AWorkingDir:string;const AApiKeyGoogle:string;
                        const AGoogleSearchEngineID:string; const AUserCallback:TUserCallback; const AStepCompletedEvent:TStepCompletedEvent);
    destructor Destroy;override;
    procedure RunOneStep;
    procedure Terminate;
    property Memory:string read FMemory;
    property IsRunning:Boolean read FRunning;
  end;
  const
    AGENT_PARAM_COUNT: array[TAgentType] of Integer = (1,2,1,2,1,1,2,0,1);
    AGENT_NAMES:array[TAgentType] of string = ('USER','WRITE_FILE','READ_FILE','BROWSE_SITE','SEARCH_GOOGLE','WRITE_MEMORY','GPT_TASK','LIST_FILES','RUN_CMD');
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

function TAutoGPTManagerSynced.ParseJSONResponse(const AResponse:string;out Thoughts:string; out Plan:string; out Criticism:string; out Action:TAutoGPTAction; out StructureValid:Boolean): string;
var
  LJSONResponse: TJSONValue;
  LJSONAction:TJSONObject;
  LActionType:string;
  LType:TActionType;
  LActionTypeEnum:TActionType;
  LActionTypeFound:Boolean;
  LAgentType:string;
  LAgentTypeFound:Boolean;
  LAgentTypeEnum:TAgentType;
  LAgentName:string;
  LJSONParams:TJSONArray;
  LJSONParam:TJSONValue;
  LJSONParamStr:string;

begin
    LJSONResponse := TJSONObject.ParseJSONValue(AResponse);
    {
      parse the response
    }
    if not (LJSONResponse is TJSONObject) then
    begin
      StructureValid:=False;
      Result:='Error: This response is not valie JSON object.';
      Exit;
    end;
    if not LJSONResponse.TryGetValue<string>('InternalThoughts',Thoughts) then
    begin
      StructureValid:=False;
      Result:='Error: JSON response does not contain "InternalThoughts".';
      Exit;
    end;
    if not LJSONResponse.TryGetValue<string>('Plan',Plan) then
    begin
      StructureValid:=False;
      Result:='Error: JSON response does not contain "Plan".';
      Exit;
    end;
    if not LJSONResponse.TryGetValue<string>('Criticism',Criticism) then
    begin
      StructureValid:=False;
      Result:='Error: JSON response does not contain "Criticism".';
      Exit;
    end;
    if not LJSONResponse.TryGetValue<TJSONObject>('Action',LJSONAction) then
    begin
      StructureValid:=False;
      Result:='Error: JSON repsonse does not contain an Action".';
      Exit;
    end;
    {
      parse the action type
    }
    if not LJSONAction.TryGetValue<string>('ActionType',LActionType) then
    begin
      StructureValid:=False;
      Result:='Error: Action does not contain an ActionType.';
      Exit;
    end;
    LActionTypeFound:=False;
    for LType := Low(TActionType) to High(TActionType) do
    begin
      if LowerCase(ACTION_NAMES[LType]) = LowerCase(LActionType) then
      begin
        LActionTypeEnum:= LType;
        LActionTypeFound:=True;
        break;
      end;
    end;
    if not LActionTypeFound then
    begin
      StructureValid:= False;
      Result:='Error: "'+LActionType+'" is not a valid ActionType.';
      Exit;
    end;
    Action.ActionType:=LActionTypeEnum;
    case LActionTypeEnum of
      atThinking:
        StructureValid:= True;
      atFinished:
        StructureValid:= True;
      atCallAgent:
        begin
          {
            parse the agent type
          }
          if not LJSONAction.TryGetValue<string>('Agent',LAgentType) then
          begin
            StructureValid:= False;
            Result:='Error: You have to provide an agent when using CALL_AGENT';
            Exit;
          end;
          LAgentTypeFound:=False;
          for LAgentTypeEnum := Low(TAgentType) to High(TAgentType) do
          begin
            if LowerCase(AGENT_NAMES[LAgentTypeEnum]) = LowerCase(LAgentType) then
            begin
              Action.AgentType:= LAgentTypeEnum;
              LAgentTypeFound:=True;
              Break;
            end;
          end;
          if not LAgentTypeFound then
          begin
            StructureValid:=False;
            Result:='Error: "'+LAgentType+'" is not a valid Agent.';
            Exit;
          end;

          if not LJSONAction.TryGetValue<TJSONArray>('AgentParams',LJSONParams) then
          begin
            StructureValid:=False;
            Result:='Error: you have to provide the "AgentParams" type when using an agent.';
            Exit;
          end;

          if LJSONParams.Count <> AGENT_PARAM_COUNT[LAgentTypeEnum] then
          begin
            StructureValid:= False;
            Result:='Error: "'+LAgentType+'" expects '+inttostr(AGENT_PARAM_COUNT[LAgentTypeEnum])+' params, but got '+inttostr(LJSONParams.Count)+' instead.';
            Exit;
          end;

          for LJSONParam in LJSONParams do
          begin
            LJSONParam.TryGetValue<string>(LJSONParamStr);
            Insert(LJSONParamStr,Action.AgentParams,length(Action.AgentParams));
          end;

          StructureValid:=True;
        end;
    end;
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
  LError:= ParseJSONResponse(LModelResponse,LThoughts,LPlan,LCritic,LAction,LValid);

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
          atRunCMD: LAgent:=TAgentCMD.Create;
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
  FTerminated:=False;
  FShouldRun:=False;
  FStepCompletedEvent:=AStepCompletedEvent;
end;

destructor TAutoGPTManager.Destroy;
begin
  Terminate;
  FManagerSynced.Free;
end;

procedure TAutoGPTManager.Execute;
begin
  inherited;
  while not FTerminated do
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

procedure TAutoGPTManager.Terminate;
begin
  FTerminated:= True;
end;

end.

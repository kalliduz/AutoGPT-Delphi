unit Agent.GPT;

interface
uses
  Agent, OpenAI, OpenAI.Chat, OpenAI.Completions;

type
  TAgentGPT = class(TAgent)
  private
    FOpenAI:TOpenAI;
    function GetModel:string;virtual;abstract;
  protected
    function CallAgentInternal(AParams:TAgentParams):string;override;
  public
    constructor Create(const AAPIKey:string);
    destructor Destroy;

  end;

  TAgentGPT35 = class(TAgentGPT)
  private
    function GetModel:string;override;
  end;
  TAgentGPT4 = class(TAgentGPT)
  private
    function GetModel:string;override;
  end;

implementation

{ TAgentGPT }
uses
  SysUtils;


function TAgentGPT.CallAgentInternal(AParams: TAgentParams): string;
var
  LChat:TChat;
  LChoice:TChatChoices;
  LMessages:TArray<TChatMessageBuild>;
begin
  inherited;
  Result:='';
  {
    prepare the message
  }
  setlength(LMessages,1);
  LMessages[0]:=TChatMessageBuild.Create(TMessageRole.User,AParams[0] + #13#10 + AParams[1]);

  {
    send the message to OpenAI
  }
  LChat:= FOpenAI.Chat.Create(  procedure(Params: TChatParams)
  begin
    Params.Messages(LMessages);
    Params.MaxTokens(1024); //TODO: should be configurable
    Params.Model(GetModel());
  end);
  try
    for  LChoice in LChat.Choices do
      Result:= Result + LChoice.Message.Content;
  finally
    LChat.Free;
  end;
end;

constructor TAgentGPT.Create(const AAPIKey: string);
begin
  FOpenAI:=TOpenAI.Create(AAPIKey);
end;


destructor TAgentGPT.Destroy;
begin
  inherited;
  FOpenAI.Free;
end;

{ TAgentGPT35 }

function TAgentGPT35.GetModel: string;
begin
  Result:= 'gpt-3.5-turbo';
end;

{ TAgentGPT4 }

function TAgentGPT4.GetModel: string;
begin
  Result:= 'gpt-4';
end;

end.

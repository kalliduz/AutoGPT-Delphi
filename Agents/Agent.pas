unit Agent;

interface
uses
  Logging,AutoGPT.Options;

type
  TCallback = function(const AMessage:string):string of object;
  TAgentEnvironment = record
    WorkingDir:string;
    OpenAIApiKey:string;
    GoogleSearchAPIKey:string;
    GoogleSearchEngineID:string;
    UserCallback:TCallback;
    MemoryCallback:TCallback;
  end;

  TAgentParams = TArray<string>;
  TAgent = class
  protected
    FAgentEnvironment:TAgentEnvironment;
    procedure LogDebugMessage(const AMessage:string);
    function CallAgentInternal(AParams:TAgentParams):string;virtual;abstract;
  public
    function CallAgent(AParams:TAgentParams):string;
    constructor Create(const AAgentEnvironment:TAgentEnvironment);
  end;

implementation

{ TAgent }

function TAgent.CallAgent(AParams: TAgentParams): string;
var
  i:Integer;
  LParams:string;
begin
  LParams:='';
  for i := Low(AParams) to High(AParams) do
    LParams:= LParams + '"'+AParams[i]+'" ';
  LogDebugMessage('CallAgent Params: '+LParams);
  Result:= CallAgentInternal(AParams);
  LogDebugMessage('returned Result = '+Result);
end;

constructor TAgent.Create(const AAgentEnvironment:TAgentEnvironment);
begin
  FAgentEnvironment:=AAgentEnvironment;
end;

procedure TAgent.LogDebugMessage(const AMessage: string);
begin
  TLogger.LogMessage(llDebug,'Agent "'+ClassName+'": '+AMessage);
end;

end.

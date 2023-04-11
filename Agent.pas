unit Agent;

interface
uses
  Logging;

type
  TAgentParams = TArray<string>;
  TAgent = class
  protected
    procedure LogDebugMessage(const AMessage:string);
    function CallAgentInternal(AParams:TAgentParams):string;virtual;abstract;
  public
    function CallAgent(AParams:TAgentParams):string;
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

procedure TAgent.LogDebugMessage(const AMessage: string);
begin
  TLogger.LogMessage(llDebug,'Agent "'+ClassName+'": '+AMessage);
end;

end.

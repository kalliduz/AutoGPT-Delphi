unit Agent.Memory;

interface
uses
  Agent;

type
  TAgentMemory = class(TAgent)
  protected
    function CallAgentInternal(AParams:TAgentParams):string;override;
  public
  end;

implementation

{ TAgentMemory }

function TAgentMemory.CallAgentInternal(AParams: TAgentParams): string;
begin
  inherited;
  if Assigned(FAgentEnvironment.MemoryCallback) then
    Result:=FAgentEnvironment.MemoryCallback(AParams[0])
  else
    Result:= 'No access function to memory. Aborting';
end;
end.

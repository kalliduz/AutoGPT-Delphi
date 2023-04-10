unit Agent.Memory;

interface
uses
  Agent;

type
  TMemoryCallback = function (const ANewMemory:string):string of object;
  TAgentMemory = class(TAgent)
  private
    FMemoryCallback: TMemoryCallback;
  public
    function CallAgent(AParams:TAgentParams):string;override;
    constructor Create(AMemoryCallback:TMemoryCallback);
  end;

implementation

{ TAgentMemory }

function TAgentMemory.CallAgent(AParams: TAgentParams): string;
begin
  if Assigned(FMemoryCallback) then
    Result:=FMemoryCallback(AParams[0])
  else
    Result:= 'No access function to memory. Aborting';
end;

constructor TAgentMemory.Create(AMemoryCallback: TMemoryCallback);
begin
  FMemoryCallback:= AMemoryCallback;
end;

end.

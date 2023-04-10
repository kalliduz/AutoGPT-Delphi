unit Agent;

interface

type
  TAgentParams = TArray<string>;
  TAgent = class
  public
    function CallAgent(AParams:TAgentParams):string;virtual;abstract;
  end;

implementation

end.

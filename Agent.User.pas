unit Agent.User;

interface
uses
  Agent;

type

  TUserCallback = function(const AMessage:string):string of object;
  TAgentUser = class(TAgent)
  private
    FUserCallback:TUserCallback;
  public
    constructor Create(AUserCallback:TUserCallback);
    function CallAgent(AParams:TAgentParams):string;override;
  end;


implementation

{ TAgentUser }

function TAgentUser.CallAgent(AParams: TAgentParams): string;
begin
  if Assigned(FUserCallback) then
    Result:= FUserCallback(AParams[0])
  else
    Result:= 'The user didn''t provide any feedback';
end;

constructor TAgentUser.Create(AUserCallback: TUserCallback);
begin
  FUserCallback:= AUserCallback;
end;

end.

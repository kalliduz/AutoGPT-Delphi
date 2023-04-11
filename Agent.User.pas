unit Agent.User;

interface
uses
  Agent, SysUtils;

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
    Result:= FUserCallback(StringReplace(AParams[0],'\n',#13#10,[rfReplaceAll]))
  else
    Result:= 'The user didn''t provide any feedback';
end;

constructor TAgentUser.Create(AUserCallback: TUserCallback);
begin
  FUserCallback:= AUserCallback;
end;

end.

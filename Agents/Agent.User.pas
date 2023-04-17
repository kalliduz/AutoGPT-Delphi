unit Agent.User;

interface
uses
  Agent, SysUtils;

type


  TAgentUser = class(TAgent)
  protected
    function CallAgentInternal(AParams:TAgentParams):string;override;
  public
  end;


implementation

{ TAgentUser }

function TAgentUser.CallAgentInternal(AParams: TAgentParams): string;
begin
  inherited;
  if Assigned(FAgentEnvironment.UserCallback) then
    Result:= FAgentEnvironment.UserCallback(StringReplace(AParams[0],'\n',#13#10,[rfReplaceAll]))
  else
    Result:= 'The user didn''t provide any feedback';
end;

end.

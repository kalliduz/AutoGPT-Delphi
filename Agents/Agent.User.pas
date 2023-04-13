unit Agent.User;

interface
uses
  Agent, SysUtils;

type

  TUserCallback = function(const AMessage:string):string of object;
  TAgentUser = class(TAgent)
  private
    FUserCallback:TUserCallback;
  protected
    function CallAgentInternal(AParams:TAgentParams):string;override;
  public
    constructor Create(AUserCallback:TUserCallback);
  end;


implementation

{ TAgentUser }

function TAgentUser.CallAgentInternal(AParams: TAgentParams): string;
begin
  inherited;
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

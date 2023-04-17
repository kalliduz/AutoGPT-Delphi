unit Agent.ReadFile;

interface
uses
  Agent, SysUtils, IOUtils, Classes;

type
  TAgentReadFile = class(TAgent)
  protected
    function CallAgentInternal(AParams:TAgentParams):string;override;
  end;

implementation

{ TAgentReadFile }

function TAgentReadFile.CallAgentInternal(AParams: TAgentParams): string;
var
  LFullFileName:string;
  LStr:TStrings;
begin
  inherited;
  Result:='';
  LFullFileName:=TPath.Combine(IncludeTrailingPathDelimiter(FAgentEnvironment.WorkingDir),AParams[0]);
  if FileExists(LFullFileName) then
  begin
    LStr:= TStringList.Create;
    try
      LStr.LoadFromFile(LFullFileName);
      Result:= LStr.Text;
    finally
      LStr.Free;
    end;
  end;
end;


end.

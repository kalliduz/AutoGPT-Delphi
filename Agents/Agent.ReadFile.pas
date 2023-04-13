unit Agent.ReadFile;

interface
uses
  Agent, SysUtils, IOUtils, Classes;

type
  TAgentReadFile = class(TAgent)
  private
    FWorkingDir:string;
  protected
    function CallAgentInternal(AParams:TAgentParams):string;override;
  public
    constructor Create(const AWorkingDir:string);
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
  LFullFileName:=TPath.Combine(IncludeTrailingPathDelimiter(FWorkingDir),AParams[0]);
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

constructor TAgentReadFile.Create(const AWorkingDir: string);
begin
  inherited Create;
  FWorkingDir:= AWorkingDir;
end;

end.

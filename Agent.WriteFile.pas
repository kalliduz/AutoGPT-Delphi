unit Agent.WriteFile;

interface
uses
  Agent, SysUtils, IOUtils, Classes;

type
  TAgentWriteFile = class(TAgent)
  private
    FWorkingDir:string;
  protected
    function CallAgentInternal(AParams:TAgentParams):string;override;
  public
    constructor Create(const AWorkingDir:string);
  end;

implementation

{ TAgentReadFile }

function TAgentWriteFile.CallAgentInternal(AParams: TAgentParams): string;
var
  LFullFileName:string;
  LStr:TStrings;
begin
  inherited;
  Result:='1';
  LFullFileName:=TPath.Combine(IncludeTrailingPathDelimiter(FWorkingDir),AParams[0]);
  LStr:=TStringList.Create;
  try
    LStr.Text:=StringReplace(AParams[1],'\n',#13#10,[rfReplaceAll]);
    LStr.SaveToFile(LFullFileName);
    Result:='0';
  finally
    LStr.Free;
  end;
end;

constructor TAgentWriteFile.Create(const AWorkingDir: string);
begin
  inherited Create;
  FWorkingDir:= AWorkingDir;
end;

end.


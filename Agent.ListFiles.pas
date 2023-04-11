unit Agent.ListFiles;

interface
uses
  Agent, IOUtils;
type
  TAgentListFiles = class(TAgent)
  private
    FWorkingDir:string;
  public
    function CallAgent(AParams:TAgentParams):string;override;
    constructor Create(const AWorkingDir:string);
  end;

implementation

{ TAgentListFiles }

function TAgentListFiles.CallAgent(AParams: TAgentParams): string;
var
  LResults:TArray<string>;
  LFile:string;
begin
  Result:='';
  if TDirectory.Exists(FWorkingDir) then
  begin
    LResults:=TDirectory.GetFiles(FWorkingDir);
    for LFile in LResults do
      Result:= Result+ TPath.GetFileName(LFile)+sLineBreak;
  end
  else
    Result:= 'AutoGPT workspace is not existing!';
end;

constructor TAgentListFiles.Create(const AWorkingDir: string);
begin
  FWorkingDir:=AWorkingDir;
end;

end.

unit Agent.ListFiles;

interface
uses
  Agent, IOUtils;
type
  TAgentListFiles = class(TAgent)
  private
    FWorkingDir:string;
  protected
      function CallAgentInternal(AParams:TAgentParams):string;override;
  public
    constructor Create(const AWorkingDir:string);
  end;

implementation

{ TAgentListFiles }

function TAgentListFiles.CallAgentInternal(AParams: TAgentParams): string;
var
  LResults:TArray<string>;
  LFile:string;
begin
  inherited;
  Result:='';
  if TDirectory.Exists(FWorkingDir) then
  begin
    LResults:=TDirectory.GetFiles(FWorkingDir);
    for LFile in LResults do
      Result:= Result+ TPath.GetFileName(LFile)+sLineBreak;

    LogDebugMessage(Result);
  end
  else
  begin
    LogDebugMessage('Directory '+FWorkingDir+'doesn''t exist');
    Result:= 'AutoGPT workspace is not existing!';
  end;
end;

constructor TAgentListFiles.Create(const AWorkingDir: string);
begin
  FWorkingDir:=AWorkingDir;
end;

end.

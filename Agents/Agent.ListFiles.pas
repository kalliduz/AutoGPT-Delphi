unit Agent.ListFiles;

interface
uses
  Agent, IOUtils;
type
  TAgentListFiles = class(TAgent)
  private
  protected
      function CallAgentInternal(AParams:TAgentParams):string;override;
  public
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
  if TDirectory.Exists(FAgentEnvironment.WorkingDir) then
  begin
    LResults:=TDirectory.GetFiles(FAgentEnvironment.WorkingDir);
    for LFile in LResults do
      Result:= Result+ TPath.GetFileName(LFile)+sLineBreak;

    LogDebugMessage(Result);
  end
  else
  begin
    LogDebugMessage('Directory '+FAgentEnvironment.WorkingDir+'doesn''t exist');
    Result:= 'AutoGPT workspace is not existing!';
  end;
end;


end.

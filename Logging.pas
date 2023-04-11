unit Logging;

interface
uses
  IOUtils,SysUtils;

type
  TLogLevel = (llDebug,llInfo, llWarning, llError);
  TLogger = class
  private
  class var
    FLogFile:string;
  public
    class procedure LogMessage(const ALogLevel:TLoglevel; const AMessage:string);
    class property LogFile:string read FLogFile write FLogFile;
  end;
const
  LOGLEVEL_NAMES: array[TLogLevel] of string = ('DEBUG','INFO','WARNING','ERROR');

implementation

{ TLogger }

class procedure TLogger.LogMessage(const ALogLevel: TLoglevel;
  const AMessage: string);
const
  LOG_FORMAT = '%s: [%s] %s'+sLineBreak;
var
  LFullLogMessage:string;
begin
  if TDirectory.Exists(ExtractFilePath(FLogFile)) then
  begin
    LFullLogMessage:= Format(LOG_FORMAT,[DateToStr(Now),LOGLEVEL_NAMES[ALogLevel],AMessage]);
    TFile.AppendAllText(FLogFile,LFullLogMessage,TEncoding.UTF8);
  end;
end;

end.

unit AutoGPT.Options;

interface
uses
  IniFiles,SysUtils;

type
  TAutoGPTOptions = class
  private
    FOpenAIApiKey:string;
    FGoogleCustomSearchApiKey:string;
    FWorkingDir:string;
    FGPT3Only:Boolean;
    FGoogleSearchEngineID:string;
  public
    property OpenAIApiKey:string read FOpenAIApiKey write FOpenAIApiKey;
    property GoogleCustomSearchApiKey:string read FGoogleCustomSearchApiKey write FGoogleCustomSearchApiKey;
    property WorkingDir:string read FWorkingDir write FWorkingDir;
    property GoogleSearchEngineID:string read FGoogleSearchEngineID write FGoogleSearchEngineID;
    property GPT3Only:Boolean read FGPT3Only write FGPT3Only;
    constructor Create;
    procedure LoadFromIni(const AIniFileName:string);
    procedure SaveToIni(const AIniFileName:string);
  end;

implementation

{ TAutoGPTOptions }

constructor TAutoGPTOptions.Create;
begin
end;

procedure TAutoGPTOptions.LoadFromIni(const AIniFileName: string);
var
  LIni:TIniFile;
begin
  if FileExists(AIniFileName) then
  begin
    LIni:=TIniFile.Create(AIniFileName);
    try
      FWorkingDir:= LIni.ReadString('OPTIONS','WORKING_DIR','.\');
      FOpenAIApiKey:= LIni.ReadString('API_KEYS','OPEN_AI','');
      FGoogleCustomSearchApiKey:= LIni.ReadString('API_KEYS','GOOGLE_CUSTOM_SEARCH','');
      FGoogleSearchEngineID:= LIni.ReadString('API_KEYS','GOOGLE_SEARCH_ENGINE_ID','');
      FGPT3Only:=LIni.ReadBool('OPTIONS','GPT3ONLY',False);
    finally
      LIni.Free;
    end;
  end;
end;

procedure TAutoGPTOptions.SaveToIni(const AIniFileName: string);
var
  LIni:TIniFile;
begin
  LIni:=TIniFile.Create(AIniFileName);
  try
    LIni.WriteString('OPTIONS','WORKING_DIR',FWorkingDir);
    LIni.WriteString('API_KEYS','OPEN_AI',FOpenAIApiKey);
    LIni.WriteString('API_KEYS','GOOGLE_CUSTOM_SEARCH',FGoogleCustomSearchApiKey);
    LIni.WriteString('API_KEYS','GOOGLE_SEARCH_ENGINE_ID',FGoogleSearchEngineID);
    LIni.WriteBool('OPTIONS','GPT3ONLY',FGPT3Only);
  finally
    LIni.Free;
  end;
end;

end.

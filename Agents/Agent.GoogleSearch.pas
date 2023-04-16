unit Agent.GoogleSearch;

interface
uses
  Agent, Agent.GPT, System.Net.URLClient, System.Net.HttpClient,
  System.Net.HttpClientComponent, System.JSON,SysUtils, System.NetEncoding;

type
  TAgentGoogleSearch = class(TAgent)
  private
    FApiKeyOpenAI:string;
    FApiKeyGoogle:string;
    FSearchEngineID:string;
    function SummarizeEverything(const AText:string):string;
  protected
      function CallAgentInternal(AParams:TAgentParams):string; override;
  public
    constructor Create(const AOpenAIApiKey:string;const AGoogleAPIKey:string;const ASearchEngineID:string);
  end;

function GoogleSearch(const Query, APIKey: string;const ASearchEngineID:string): string;
implementation

{ TAgentGoogleSearch }
function GoogleSearch(const Query, APIKey: string; const ASearchEngineID:string): string;
const
  GoogleSearchURL = 'https://www.googleapis.com/customsearch/v1?key=%s&cx=%s&q=%s';
var
  URL: string;
  HTTPClient: TNetHTTPClient;
  HTTPRequest: TNetHTTPRequest;
  JSONValue: TJSONValue;
  JSONObj: TJSONObject;
  HTTPResponse: IHTTPResponse;
begin
  Result := '';
  URL := Format(GoogleSearchURL, [APIKey,ASearchEngineID, TNetEncoding.URL.Encode(Query)]);

  HTTPClient := TNetHTTPClient.Create(nil);
  try
    HTTPRequest := TNetHTTPRequest.Create(HTTPClient);
    try
      HTTPRequest.Client := HTTPClient;
      HTTPRequest.SetSubComponent(True);

      try
        HTTPResponse := HTTPRequest.Get(URL);
        JSONValue := TJSONObject.ParseJSONValue(HTTPResponse.ContentAsString(TEncoding.UTF8));
        try
          JSONObj := JSONValue as TJSONObject;
          if JSONObj.TryGetValue('items', JSONValue) then
          begin
            // Process search results here.
            // For example, you can extract the title and link of each search result.
            Result := JSONValue.ToString;
          end;
        finally
          JSONValue.Free;
        end;
      except
        on E: Exception do
          Writeln('Error: ' + E.Message);
      end;
    finally
      HTTPRequest.Free;
    end;
  finally
    HTTPClient.Free;
  end;
end;

function TAgentGoogleSearch.CallAgentInternal(AParams: TAgentParams): string;

begin
  inherited;
  Result:=GoogleSearch( AParams[0], FApiKeyGoogle,FSearchEngineID);
  LogDebugMessage('Raw response: '+Result);
  {
    we got our content, now we summarize it
  }
  Result:= SummarizeEverything(Result);
end;

constructor TAgentGoogleSearch.Create(const AOpenAIApiKey:string;const AGoogleAPIKey:string;const ASearchEngineID:string);
begin
  inherited Create;
  FApiKeyGoogle:=AGoogleAPIKey;
  FApiKeyOpenAI:=AOpenAIApiKey;
  FSearchEngineID:=ASearchEngineID;

end;

function TAgentGoogleSearch.SummarizeEverything(const AText: string): string;
var
  LSumAgent:TAgentGPT35;
  LStartIndex:Integer;
  LSumIdx:Integer;
begin
  Result:='';
  LSumIdx:=0;
  LStartIndex:=0;
  while LStartIndex < length(AText) do
  begin
    inc(LSumIdx);
    LSumAgent:=TAgentGPT35.Create(FApiKeyOpenAI);
    try
      Result:=Result+'SummaryPart'+inttostr(LSumIdx)+': '+sLineBreak + LSumAgent.CallAgent(['Summarize relevant info and list all links from the content:'#13#10,Copy(AText,LStartIndex,LStartIndex+8000)])+sLineBreak;
    finally
      LSumAgent.Free;
    end;
    LStartIndex:=LStartIndex+8000;
  end;
end;

end.

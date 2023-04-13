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
var
  LSumAgent:TAgentGPT35;
begin
  inherited;
  Result:=GoogleSearch( AParams[0], FApiKeyGoogle,FSearchEngineID);
  LogDebugMessage('Raw response: '+Result);
  {
    we got our content, now we execute the specified instruction with GPT-3
  }
  LSumAgent:=TAgentGPT35.Create(FApiKeyOpenAI);
  try
    Result:=  LSumAgent.CallAgent(['Summarize the relevant info and provide a linklist:'#13#10,Copy(Result,0,8000)]);
  finally
    LSumAgent.Free;
  end;
end;

constructor TAgentGoogleSearch.Create(const AOpenAIApiKey:string;const AGoogleAPIKey:string;const ASearchEngineID:string);
begin
  inherited Create;
  FApiKeyGoogle:=AGoogleAPIKey;
  FApiKeyOpenAI:=AOpenAIApiKey;
  FSearchEngineID:=ASearchEngineID;

end;

end.

unit Agent.Browse;

interface
uses
  IdHttp,IdSSLOpenSSL, SysUtils, Agent, XMLIntf, XMLDoc, Agent.GPT;

type
  TAgentBrowse = class(TAgent)
  protected
    function CallAgentInternal(AParams:TAgentParams):string;override;
  end;


implementation


function GetWebContent(const URL: string): string;
var
  IdHTTP: TIdHTTP;
  IdSSLIOHandler: TIdSSLIOHandlerSocketOpenSSL;
begin
  IdHTTP := TIdHTTP.Create(nil);
  try
    IdSSLIOHandler := TIdSSLIOHandlerSocketOpenSSL.Create(IdHTTP);
    IdHTTP.IOHandler := IdSSLIOHandler;
    IdHTTP.HandleRedirects := True;
    IdHTTP.Request.UserAgent := 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.63 Safari/537.36';
    IdSSLIOHandler.SSLOptions.SSLVersions := [sslvTLSv1, sslvTLSv1_1, sslvTLSv1_2];
    try
      Result := IdHTTP.Get(URL);
    except
      on E: Exception do
      begin
        Result := 'Error: ' + E.Message;
      end;
    end;
  finally
    IdHTTP.Free;
  end;
end;

function StripHtmlMarkup(const source:string):string;
var i, count: Integer;
    InTag: Boolean;
    P: PChar;
begin
  SetLength(Result, Length(source));
  P := PChar(Result);
  InTag := False;
  count := 0;
  for i:=1 to Length(source) do
    if InTag then
      begin
        if source[i] = '>' then InTag := False;
      end
    else
      if source[i] = '<' then InTag := True
      else
        begin
          P[count] := source[i];
          Inc(count);
        end;
  SetLength(Result, count);
end;

function StripHTMLTags(const HTML: string): string;
var
  XMLDocument: TXMLDocument;
  RootNode, CurrentNode: IXMLNode;
  TextContent: string;
  i: Integer;
begin
  Result := '';

  XMLDocument := TXMLDocument.Create(nil);
  try
    XMLDocument.LoadFromXML('<root>' + HTML + '</root>');
    RootNode := XMLDocument.DocumentElement;

    for i := 0 to RootNode.ChildNodes.Count - 1 do
    begin
      CurrentNode := RootNode.ChildNodes[i];
      TextContent := CurrentNode.Text;
      if i > 0 then
        Result := Result + ' ';
      Result := Result + TextContent;
    end;
  finally
    XMLDocument.Free;
  end;
end;

{ TAgentBrowse }

function TAgentBrowse.CallAgentInternal(AParams: TAgentParams): string;
var
  LContent:string;
  LSumAgent:TAgentGPT35;
begin
  inherited;
  LContent:= StripHtmlMarkup(GetWebContent(AParams[0]));

  {
    we got our content, now we execute the specified instruction with GPT-3
  }
  LSumAgent:=TAgentGPT35.Create(FAgentEnvironment);
  try
    Result:=  LSumAgent.CallAgent([AParams[1]+':'#13#10,Copy(LContent,0,8000)]);
  finally
    LSumAgent.Free;
  end;
end;


end.

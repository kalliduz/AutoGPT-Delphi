unit Agent.CMD;
interface
uses
  SysUtils, Classes, Windows, Agent;

type
  TAgentCMD = class(TAgent)
  protected
    function CallAgentInternal(AParams: TAgentParams): string; override;
  end;

implementation

function ReadOutput(hPipe: THandle): string;
const
  BUFSIZE = 2400;
var
  LBuffer: array[0..BUFSIZE] of AnsiChar;
  LBytesRead: DWORD;
  LSuccess: Boolean;
begin
  Result := '';
  repeat
    LSuccess := ReadFile(hPipe, LBuffer, BUFSIZE, LBytesRead, nil);
    if LSuccess then
    begin
      LBuffer[LBytesRead] := #0;
      Result := Result + string(LBuffer);
    end;
  until not LSuccess or (LBytesRead = 0);
end;

function TAgentCMD.CallAgentInternal(AParams: TAgentParams): string;
var
  LCommand: string;
  LStartupInfo: TStartupInfo;
  LProcessInfo: TProcessInformation;
  LReadPipe, LWritePipe: THandle;
  LWaitResult:DWORD;
  LSecurityAttributes: TSecurityAttributes;
begin
  if Length(AParams) <> 1 then
    raise Exception.Create('TAgentCMD.CallAgentInternal expects exactly 1 parameter.');

  LCommand := 'cmd.exe /c ' + AParams[0];

  FillChar(LStartupInfo, SizeOf(TStartupInfo), 0);
  FillChar(LProcessInfo, SizeOf(TProcessInformation), 0);

  LSecurityAttributes.nLength := SizeOf(TSecurityAttributes);
  LSecurityAttributes.bInheritHandle := True;
  LSecurityAttributes.lpSecurityDescriptor := nil;

  if not CreatePipe(LReadPipe, LWritePipe, @LSecurityAttributes, 0) then
    RaiseLastOSError;

  try
    LStartupInfo.cb := SizeOf(TStartupInfo);
    LStartupInfo.dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
    LStartupInfo.wShowWindow := SW_HIDE;
    LStartupInfo.hStdInput := GetStdHandle(STD_INPUT_HANDLE);
    LStartupInfo.hStdOutput := LWritePipe;
    LStartupInfo.hStdError := LWritePipe;

    if not CreateProcess(nil, PChar(LCommand), nil, nil, True,
      CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS, nil, nil, LStartupInfo, LProcessInfo) then
      RaiseLastOSError;

    try
      CloseHandle(LWritePipe);
      LWritePipe := INVALID_HANDLE_VALUE;

      LWaitResult:= WaitForSingleObject(LProcessInfo.hProcess, 30000);
      if LWaitResult = WAIT_TIMEOUT then
        TerminateProcess(LProcessInfo.hProcess, 1);

      Result := ReadOutput(LReadPipe);
    finally
      CloseHandle(LProcessInfo.hThread);
      CloseHandle(LProcessInfo.hProcess);
    end;
  finally
    if LReadPipe <> INVALID_HANDLE_VALUE then
      CloseHandle(LReadPipe);
    if LWritePipe <> INVALID_HANDLE_VALUE then
      CloseHandle(LWritePipe);
  end;
end;

end.

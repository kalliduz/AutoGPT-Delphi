program AutoGPT;

uses
  Vcl.Forms,
  Main in 'Main.pas' {frmAutoGPTGUI},
  AutoGPT.Manager in 'AutoGPT.Manager.pas',
  Logging in 'Logging.pas',
  Vcl.Themes,
  Vcl.Styles,
  AutoGPT.Options in 'AutoGPT.Options.pas',
  Agent.Browse in 'Agents\Agent.Browse.pas',
  Agent.CMD in 'Agents\Agent.CMD.pas',
  Agent.GoogleSearch in 'Agents\Agent.GoogleSearch.pas',
  Agent.GPT in 'Agents\Agent.GPT.pas',
  Agent.ListFiles in 'Agents\Agent.ListFiles.pas',
  Agent.Memory in 'Agents\Agent.Memory.pas',
  Agent in 'Agents\Agent.pas',
  Agent.ReadFile in 'Agents\Agent.ReadFile.pas',
  Agent.User in 'Agents\Agent.User.pas',
  Agent.WriteFile in 'Agents\Agent.WriteFile.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Tablet Dark');
  Application.CreateForm(TfrmAutoGPTGUI, frmAutoGPTGUI);
  Application.Run;
end.

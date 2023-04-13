program AutoGPT;

uses
  Vcl.Forms,
  Main in 'Main.pas' {Form1},
  Agent in 'Agent.pas',
  Agent.GPT in 'Agent.GPT.pas',
  AutoGPT.Manager in 'AutoGPT.Manager.pas',
  Agent.ReadFile in 'Agent.ReadFile.pas',
  Agent.WriteFile in 'Agent.WriteFile.pas',
  Agent.Browse in 'Agent.Browse.pas',
  Agent.GoogleSearch in 'Agent.GoogleSearch.pas',
  Agent.User in 'Agent.User.pas',
  Agent.Memory in 'Agent.Memory.pas',
  Agent.ListFiles in 'Agent.ListFiles.pas',
  Logging in 'Logging.pas',
  Agent.CMD in 'Agent.CMD.pas',
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Tablet Dark');
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

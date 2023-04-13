unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, AutoGPT.Manager, Vcl.StdCtrls, IOUtils,
  Vcl.ExtCtrls, Vcl.Samples.Spin, Vcl.WinXCtrls, Vcl.Imaging.pngimage, AutoGPT.Options;

type
  TfrmAutoGPTGUI = class(TForm)
    edtGoal: TEdit;
    mmoResults: TMemo;
    btnCreateTask: TButton;
    btnRun: TButton;
    pnlControls: TPanel;
    chkContinuous: TCheckBox;
    spinContinousRuns: TSpinEdit;
    actIndicatorRunning: TActivityIndicator;
    imgAutoGPT: TImage;
    procedure btnCreateTaskClick(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
    procedure chkContinuousClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FOptions:TAutoGPTOptions;
    FAutoGpt:TAutoGPTManager;
    { Private-Deklarationen }
    function UserCallback(const AMessage:string):string;
    procedure Run;
    procedure OnStepCompleted;
  public
    { Public-Deklarationen }
  end;

var
  frmAutoGPTGUI: TfrmAutoGPTGUI;
implementation

{$R *.dfm}

procedure TfrmAutoGPTGUI.btnCreateTaskClick(Sender: TObject);
var
  LWorkingDir:string;
begin
  if Assigned(FAutoGpt) then
    FAutoGpt.Free;
  ForceDirectories(LWorkingDir);
  FAutoGpt:= TAutoGPTManager.Create(edtGoal.Text,FOptions.OpenAIApiKey,FOptions.WorkingDir,FOptions.GoogleCustomSearchApiKey,FOptions.GoogleSearchEngineID,UserCallback,OnStepCompleted);
  mmoResults.Text:=FAutoGpt.Memory;
end;

procedure TfrmAutoGPTGUI.btnRunClick(Sender: TObject);
begin
  if not Assigned(FAutoGpt) then
    ShowMessage('Set a goal first!')
  else
    Run;
end;

procedure TfrmAutoGPTGUI.chkContinuousClick(Sender: TObject);
begin
  spinContinousRuns.Visible:= chkContinuous.Checked;
end;

procedure TfrmAutoGPTGUI.FormCreate(Sender: TObject);
var
  LIniFileName:string;
begin
  FOptions:=TAutoGPTOptions.Create;
  LIniFileName:=ChangeFileExt(ParamStr(0),'.ini');
  if not FileExists(LIniFileName) then
  begin
    FOptions.SaveToIni(LIniFileName);
    ShowMessage('Please provide your API keys in AutoGPT.ini');
    Halt;
  end else
  begin
    FOptions.LoadFromIni(LIniFileName);
  end;
end;

procedure TfrmAutoGPTGUI.OnStepCompleted;
begin
  mmoResults.Text:=FAutoGpt.Memory;
  spinContinousRuns.Value:=spinContinousRuns.Value-1;
  actIndicatorRunning.Animate:=False;
  btnCreateTask.Enabled:=True;
  btnRun.Enabled:=True;
  if chkContinuous.Checked AND (spinContinousRuns.Value>0) then
  begin
    Run;
  end;
end;

procedure TfrmAutoGPTGUI.Run;
begin
  if not FAutoGpt.IsRunning then
  begin
    FAutoGpt.RunOneStep;
    actIndicatorRunning.Animate:=True;
    btnCreateTask.Enabled:=False;
    btnRun.Enabled:=False;
  end;
end;

function TfrmAutoGPTGUI.UserCallback(const AMessage: string): string;
begin
  Result:= InputBox('AutoGPT needs your feedback',AMessage,'No user feedback provided');
end;

end.

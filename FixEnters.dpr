program FixEnters;

uses
  FastMM4,
  Vcl.Forms,
  MainForm in 'MainForm.pas' {frmMain},
  ccAppData in '..\..\Packages\CubicCommonControls\ccAppData.pas',
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  AppData:= TAppData.Create('Fix enters');
  TStyleManager.TrySetStyle('Sapphire Kamri');
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.

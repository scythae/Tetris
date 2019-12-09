program Tetris;

uses
  Vcl.Forms,
  uMain in 'uMain.pas' {frMain},
  UHelpers in 'UHelpers.pas',
  uModule in 'uModule.pas',
  uModuleTetris in 'uModuleTetris.pas',
  uModuleSnake in 'uModuleSnake.pas',
  uModuleRacer in 'uModuleRacer.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrMain, frMain);
  Application.Run;
end.


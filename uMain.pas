unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, System.Types, System.UITypes,
  Vcl.StdCtrls,

  uModule, Vcl.Buttons;

type
  TfrMain = class(TForm)
    tRecalc: TTimer;
    pScore: TPanel;
    pMenu: TPanel;
    btnResume: TButton;
    btnExit: TButton;
    btnMod2: TButton;
    btnMod1: TButton;
    btnAbout: TButton;
    pInfo: TPanel;
    labelInfo: TLabel;
    btnMod3: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure tRecalcTimer(Sender: TObject);
    procedure OnMenuButtonClick(Sender: TObject);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure FormDestroy(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure labelInfoMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  const
    FieldWidth = 10;
    FieldHeight = 20;
    DelayToRealiseFinish = 750;
  private
    CellSizeInPixels: Integer;
    FieldStartPoint: TPoint;
    Field: TField;
    Module: TModule;
    LastActiveButton: TButton;
    Keys: array [0..255] of Boolean;
    procedure PaintField();
    procedure PaintCell(X, Y: Integer);
    procedure ClearField();
    procedure Finish();
    procedure PaintShapes();
    procedure Run(ModuleClass: TModuleClass);
    function GetColorOfCell(CellType: Integer): TColor;
    procedure SwitchPause();
    procedure AdjustUI;
    procedure ShowText(const Text: string);
    function TryHideText: Boolean;
    procedure OnAppMessage(var Msg: TMsg; var Handled: Boolean);
    procedure RecalcSize();
    procedure Scale(Delta: Integer);
    function GetHeightOfMenuButton: Integer;
    function GetMenuButtonFontSize: Integer;
    procedure ResizeMenuButtons;
  end;

var
  frMain: TfrMain;

implementation

uses
  UHelpers, uModuleTetris, uModuleSnake, uModuleRacer;

{$R *.dfm}

procedure TfrMain.FormCreate(Sender: TObject);
begin
  CellSizeInPixels := 10;
  RecalcSize();

  Self.OverrideMouseEventsToMakeControlDraggable();

  FieldStartPoint.X := 0;
  FieldStartPoint.Y := CellSizeInPixels * FieldHeight;

  SetLength(Field, FieldWidth, FieldHeight);
  ClearField();

  FillChar(Keys, SizeOf(Keys), Ord(False));

  Application.OnMessage := OnAppMessage;
end;

procedure TfrMain.OnAppMessage(var Msg: TMsg; var Handled: Boolean);
const
  MaxAllowedDelayForInputInMillis = 150;
var
  Key: Cardinal;
  Pressed, Released: Boolean;
begin
  if (Msg.message <> WM_KEYDOWN) and (Msg.message <> WM_KEYUP) then
    Exit();

  if (GetTickCount - Msg.time) > MaxAllowedDelayForInputInMillis then
    Exit();

  Key := Msg.wParam;
  Pressed := Msg.message = WM_KEYDOWN;
  Released := Msg.message = WM_KEYUP;

  if Pressed and Keys[Key]
  or Released and not Keys[Key] then
  begin
    Handled := True;
    Exit();
  end;

  Keys[Key] := Pressed;

  if Pressed then
  begin
    if Key = vkEscape then
    begin
      SwitchPause();
      Handled := True;
      Exit();
    end;

    if Screen.ActiveControl is TButton then
      Exit();

    if TryHideText() then
    begin
      Handled := True;
      Exit();
    end;
  end;

  Handled := True;

  if Assigned(Module) and tRecalc.Enabled then
    Module.TakeInput(Key, Released);

  if Pressed then
    Repaint();
end;

procedure TfrMain.FormActivate(Sender: TObject);
begin
  AdjustUI();
end;

procedure TfrMain.FormDestroy(Sender: TObject);
begin
  FreeAndNil(Module);
end;

procedure TfrMain.Run(ModuleClass: TModuleClass);
begin
  ClearField();
  Module.Free();

  Module := ModuleClass.Create(Field);
  Module.OnChangeRecalcInterval :=
  procedure(NewIntervalInMillis: Integer)
  begin
    tRecalc.Enabled := NewIntervalInMillis > 0;
    tRecalc.Interval := NewIntervalInMillis;
  end;

  Module.Start();

  AdjustUI();
  Repaint();
end;

procedure TfrMain.OnMenuButtonClick(Sender: TObject);
begin
  LastActiveButton := Sender as TButton;

  if Sender = btnResume then
    SwitchPause()
  else if Sender = btnMod1 then
    Run(TModuleTetris)
  else if Sender = btnMod2 then
    Run(TModuleSnake)
  else if Sender = btnMod3 then
    Run(TModuleRacer)
  else if Sender = btnAbout then
    ShowText(
     ' Arrows and Spacebar to navigate, Esc to pause.'#13#10 +
     ' Mousewheel for an alpha adjustment, Shift + mousewheel for a size adjustment.'
    )
  else if Sender = btnExit then
    Close();
end;

procedure TfrMain.SwitchPause();
begin
  if not Assigned(Module) then
    Exit();

  tRecalc.Enabled := not tRecalc.Enabled;
  AdjustUI();
end;

procedure TfrMain.AdjustUI();
begin
  pMenu.Enabled := not pInfo.Visible;
  pMenu.Visible := not tRecalc.Enabled;
  btnResume.Visible := Assigned(Module);
  pScore.Visible := Assigned(Module);

  if pMenu.Enabled and pMenu.Visible then
    if Assigned(LastActiveButton) and LastActiveButton.Visible then
      LastActiveButton.SetFocus()
    else if btnResume.Visible then
      btnResume.SetFocus()
    else
      btnMod1.SetFocus();
end;

procedure TfrMain.ShowText(const Text: string);
begin
  labelInfo.Caption := Text;
  pInfo.Show();
  AdjustUI();
end;

function TfrMain.TryHideText(): Boolean;
begin
  Result := pInfo.Visible;
  if not Result then
    Exit();

  pInfo.Hide();
  AdjustUI();
end;

procedure TfrMain.ClearField();
var
  X, Y: Integer;
begin
  for Y := 0 to FieldHeight - 1 do
    for X := 0 to FieldWidth - 1 do
      Field[X, Y] := CellEmpty;
end;

procedure TfrMain.FormPaint(Sender: TObject);
begin
  PaintField();
  PaintShapes();
end;

procedure TfrMain.PaintField();
var
  X, Y: Integer;
begin
  for Y := 0 to FieldHeight - 1 do
    for X := 0 to FieldWidth - 1 do
    begin
      Canvas.Brush.Color := GetColorOfCell(Field[X, Y]);
      PaintCell(X, Y);
    end;
end;

function TfrMain.GetColorOfCell(CellType: Integer): TColor;
begin
  case CellType of
    CellEmpty: Result := Self.Color;
    CellShape: Result := clGray;
    CellSolid: Result := clBlack;
    else Result := clBlack;
  end;
end;

procedure TfrMain.labelInfoMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  TryHideText();
end;

procedure TfrMain.PaintCell(X, Y: Integer);
var
  CellRect: TRect;
begin
  CellRect.Left := X * CellSizeInPixels;
  CellRect.Right := CellRect.Left + CellSizeInPixels - 1;
  CellRect.Bottom := FieldStartPoint.Y - Y * CellSizeInPixels;
  CellRect.Top := CellRect.Bottom - CellSizeInPixels + 1;

  Canvas.Rectangle(CellRect);
end;

procedure TfrMain.PaintShapes();
var
  Shape: TShape;
  Cell: TCell;
begin
  if not Assigned(Module) then
    Exit();

  for Shape in Module.GetShapes() do
  begin
    Canvas.Brush.Color := GetColorOfCell(Shape.CellType);
    for Cell in Shape.Cells do
      PaintCell(Cell.X + Shape.Position.X, Cell.Y + Shape.Position.Y);
  end;
end;

procedure TfrMain.tRecalcTimer(Sender: TObject);
begin
  if not Assigned(Module) then
    Exit();

  tRecalc.Enabled := False;

  Module.Recalc();
  pScore.Caption := Module.Score.ToString;
  Repaint();

  if Module.Finished then
    Finish()
  else
    tRecalc.Enabled := True;
end;

procedure TfrMain.Finish();
var
  Score: Cardinal;
  Prefix: string;
  GotMaxScore: Boolean;
begin
  if not Assigned(Module) then
    Exit();

  Sleep(DelayToRealiseFinish);
  Score := Module.Score;
  GotMaxScore := Module.GotMaxScore();
  FreeAndNil(Module);
  ClearField();
  Repaint();

  if GotMaxScore then
    Prefix := 'MaxInt got taken. Count that as a victory. Congratulations! '
  else
    Prefix := 'Game over. ';

  ShowText(Prefix + #13#10'Score: ' + Score.ToString());
end;

procedure TfrMain.FormMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
var
  tmpABValue: Integer;
begin
  Handled := True;
  if GetKeyState(vkShift) < 0 then
  begin
    Scale(WheelDelta);
    Exit();
  end;

  if WheelDelta < 0 then
    tmpABValue := AlphaBlendValue - 20
  else
    tmpABValue := AlphaBlendValue + 20;

  if tmpABValue < 10 then
    AlphaBlendValue := 10
  else if tmpABValue > 255 then
    AlphaBlendValue := 255
  else
    AlphaBlendValue := tmpABValue;
end;

procedure TfrMain.Scale(Delta: Integer);
const
  Step = 1;
  CellSizeMin = 10;
  CellSizeMax = 40;
var
  tmpCellSize: Integer;
begin
  if Delta < 0 then
    tmpCellSize := CellSizeInPixels - Step
  else
    tmpCellSize := CellSizeInPixels + Step;

  if (tmpCellSize < CellSizeMin) or (tmpCellSize > CellSizeMax) then
    Exit();

  CellSizeInPixels := tmpCellSize;
  RecalcSize();
end;

procedure TfrMain.RecalcSize();
var
  W, H: Integer;
begin
  W := CellSizeInPixels * FieldWidth * 2;
  H := CellSizeInPixels * FieldHeight;
  FieldStartPoint.X := 0;
  FieldStartPoint.Y := H;

  SetBounds(Left, Top, W, H);

  pMenu.Width := W div 2 - 1;
  pMenu.Height := pMenu.ControlCount * GetHeightOfMenuButton();
  pMenu.Left := W - pMenu.Width;
  pMenu.Top := H - pMenu.Height;
  ResizeMenuButtons();

  pScore.Width := pMenu.Width;
  pScore.Height := GetHeightOfMenuButton();
  pScore.Left := pMenu.Left;
  pScore.Top := 0;
  pScore.Font.Size := GetMenuButtonFontSize();

  pInfo.Left := CellSizeInPixels * 2;
  pInfo.Top := CellSizeInPixels * 4 + 1;
  pInfo.Width := W - pInfo.Left * 2;
  pInfo.Height := H - pInfo.Top * 2 + 1;
  pInfo.Font.Size := GetMenuButtonFontSize();

  Repaint();
end;

function TfrMain.GetHeightOfMenuButton(): Integer;
begin
  Result := CellSizeInPixels * 5 div 2;
end;

function TfrMain.GetMenuButtonFontSize(): Integer;
begin
  Result := GetHeightOfMenuButton() div 3;
end;

procedure TfrMain.ResizeMenuButtons();
var
  I: Integer;
  Btn: TButton;
begin
  for I := 0 to pMenu.ControlCount - 1 do
  begin
    if not (pMenu.Controls[I] is TButton) then
      Continue;

    Btn := pMenu.Controls[I] as TButton;
    Btn.Height := GetHeightOfMenuButton();
    Btn.Font.Size := GetMenuButtonFontSize();
  end;
end;

end.


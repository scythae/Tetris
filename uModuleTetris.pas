unit uModuleTetris;

interface

uses
  System.Types, System.UITypes, uModule;

type
  TModuleTetris = class(TModule)
  private const
    ScorePerRemovedLine = 200;
  protected type
    TShapeType = (sI, sT, sL, sJ, sS, sZ, sSquare);
    TShapeRotation = (r0, r90, r180, r270);
  private
    ShapePosition: TPoint;
    Rotation: TShapeRotation;
    ShapeType: TShapeType;
    NextShapeType: TShapeType;
    NextShapeTypePosition: TPoint;
  protected
    Shapes: array [Low(TShapeType)..High(TShapeType), Low(TShapeRotation)..High(TShapeRotation)] of TCells;
    procedure LoadShapeCells(ShapeType: TShapeType; const S: string);
    procedure LoadShapes();
    procedure DefineNewShape();
    procedure DefineNextShapeType();
    procedure MergeShapeAndField();
    procedure RemoveSolidLines();
    function ShapeCanBePlacedAt(const Position: TPoint): Boolean;
    function ShapeCells(): TCells;
    function CellsFitToPosition(Cells: TCells; const Position: TPoint): Boolean;
    procedure MoveDown();
  protected
    procedure OnStart(); override;
    function GetRecalcInterval(): Integer; override;
  public
    procedure TakeInput(vkCode: Integer; IsReleased: Boolean = False); override;
    procedure Recalc(); override;
    function GetShapes(): TArray<TShape>; override;
  end;

implementation

procedure TModuleTetris.OnStart();
begin
  LoadShapes();

  NextShapeTypePosition := GetSpecialIndicatorPosition();

  DefineNextShapeType();
  DefineNewShape();
end;

procedure TModuleTetris.LoadShapes();
begin
  LoadShapeCells(sI,
    '#-' +
    '#-' +
    '#-' +
    '#-');
  LoadShapeCells(sT,
    '###-' +
    '.#.-');
  LoadShapeCells(sL,
    '#.-' +
    '#.-' +
    '##-');
  LoadShapeCells(sJ,
    '.#-' +
    '.#-' +
    '##-');
  LoadShapeCells(sS,
    '.##-' +
    '##.-');
  LoadShapeCells(sZ,
    '##.-' +
    '.##-');
  LoadShapeCells(sSquare,
    '##-' +
    '##-');
end;

procedure TModuleTetris.LoadShapeCells(ShapeType: TShapeType; const S: string);
var
  Rotation: TShapeRotation;
begin
  Shapes[ShapeType, r0] := GetCellsFromString(S);

  for Rotation := r90 to r270 do
    Shapes[ShapeType, Rotation] := RotateCells90(Shapes[ShapeType, Pred(Rotation)]);

  for Rotation := r0 to r270 do
    Shapes[ShapeType, Rotation] := ReflectedVerticallyCells(Shapes[ShapeType, Rotation]);
end;

procedure TModuleTetris.DefineNewShape();
begin
  Rotation := r0;
  ShapeType := NextShapeType;
  ShapePosition := Point(FieldBounds.Width div 2 - 1, FieldBounds.Height - 1);
  if not ShapeCanBePlacedAt(ShapePosition) then
    Finish();

  DefineNextShapeType();
end;

procedure TModuleTetris.DefineNextShapeType();
begin
  NextShapeType := TEnum<TShapeType>.Random();
end;

function TModuleTetris.CellsFitToPosition(Cells: TCells; const Position: TPoint): Boolean;
var
  Cell: TPoint;
begin
  for Cell in ShiftedCells(Cells, Position) do
    if not FieldBounds.Contains(Cell)
    or (Field[Cell.X, Cell.Y] <> CellEmpty) then
      Exit(False);

  Exit(True);
end;

function TModuleTetris.ShapeCanBePlacedAt(const Position: TPoint): Boolean;
begin
  Result := CellsFitToPosition(ShapeCells(), Position);
end;

function TModuleTetris.ShapeCells(): TCells;
begin
  Result := Shapes[ShapeType, Rotation];
end;

procedure TModuleTetris.MergeShapeAndField();
begin
  SolidifyCells(ShiftedCells(ShapeCells(), ShapePosition));
end;

procedure TModuleTetris.RemoveSolidLines();
  function LineIsSolid(Y: Integer): Boolean;
  var
    X: Integer;
  begin
    for X := 0 to FieldBounds.Width - 1 do
      if Field[X, Y] = CellEmpty then
        Exit(False);

    Result := True;
  end;

  procedure CopyLineFromTo(YFrom, YTo: Integer);
  var
    X: Integer;
  begin
    for X := 0 to FieldBounds.Width - 1 do
      Field[X, YTo] := Field[X, YFrom];
  end;
var
  Y: Integer;
  YShift: Integer;
begin
  YShift := 0;

  for Y := 0 to FieldBounds.Height - 1 do
    if LineIsSolid(Y) then
      Inc(YShift)
    else if YShift > 0 then
      CopyLineFromTo(Y, Y - YShift);

  Inc(FScore, YShift * YShift * ScorePerRemovedLine);
  if GotMaxScore() then
    Finish();
end;

function TModuleTetris.GetRecalcInterval(): Integer;
begin
  Result := 500;
end;

function TModuleTetris.GetShapes(): TArray<TShape>;
begin
  SetLength(Result, 2);

  Result[0].Cells := Shapes[ShapeType, Rotation];
  Result[0].Position := ShapePosition;
  Result[0].CellType := CellShape;

  Result[1].Cells := Shapes[NextShapeType, r0];
  Result[1].Position := NextShapeTypePosition;
  Result[1].CellType := CellSolid;
end;

procedure TModuleTetris.Recalc();
begin
  MoveDown();
end;

procedure TModuleTetris.MoveDown();
var
  tmpPosition: TPoint;
begin
  tmpPosition := ShapePosition;
  Dec(tmpPosition.Y);

  if not ShapeCanBePlacedAt(tmpPosition) then
  begin
    MergeShapeAndField();
    RemoveSolidLines();
    DefineNewShape();
    Exit();
  end;

  ShapePosition := tmpPosition;
end;

procedure TModuleTetris.TakeInput(vkCode: Integer; IsReleased: Boolean);
var
  tmpRotation: TShapeRotation;
  tmpPosition: TPoint;
begin
  if vkCode = vkDown then
  begin
    if IsReleased then
      SetRecalcIntervalInMillis(GetRecalcInterval())
    else
      SetRecalcIntervalInMillis(GetRecalcInterval() div 50);

    Exit();
  end;

  if IsReleased then
    Exit();

  case vkCode of
    vkSpace:
    begin
      tmpRotation := TEnum<TShapeRotation>.Succ(Rotation);
      if CellsFitToPosition(
        Shapes[ShapeType, tmpRotation],
        ShapePosition
      ) then
        Rotation := tmpRotation;
    end;
    vkLeft, vkRight:
    begin
      tmpPosition := ShapePosition;
      if vkCode = vkLeft then
        Dec(tmpPosition.X)
      else
        Inc(tmpPosition.X);

      if ShapeCanBePlacedAt(tmpPosition) then
        ShapePosition := tmpPosition;
    end;
  end;
end;

end.


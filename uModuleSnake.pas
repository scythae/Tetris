unit uModuleSnake;

interface

uses
  System.Types, System.UITypes, uModule;

type
  TModuleSnake = class(TModule)
  private type
    TDirection = (dNorth, dEast, dSouth, dWest);
    TKeyPoint = record
    private
      Position: TPoint;
      Direction: TDirection;
      procedure Move();
    end;
  private const
    CellSnake = CellSolid;
    CellFood = CellShape;
    ScorePerTakenObj = 200;
  private
    Food: TCell;
    KeyPoints: TArray<TKeyPoint>;
    FreeCellCount: Integer;
    SpeedMultiplier: Single;
    procedure CreateSnake();
    procedure CreateFood();
    function GetFreeCellCount: Integer;
    function TryGetRandomEmptyCell(var EmptyCell: TPoint): Boolean;
    function GetOppositeDirection(Dir: TDirection): TDirection;
  protected
    procedure OnStart(); override;
    function GetRecalcInterval(): Integer; override;
  public
    procedure TakeInput(vkCode: Integer; IsReleased: Boolean = False); override;
    procedure Recalc(); override;
  end;

implementation

procedure TModuleSnake.OnStart();
begin
  CreateSnake();
  CreateFood();
end;

procedure TModuleSnake.CreateSnake();
var
  Y: Integer;
  HeadPos, EndPos: TPoint;
begin
  HeadPos := Point(FieldBounds.Width div 2, FieldBounds.Height div 2);
  EndPos := Point(HeadPos.X, HeadPos.Y div 2);

  SetLength(KeyPoints, 2);
  KeyPoints[0].Position := HeadPos;
  KeyPoints[0].Direction := dNorth;
  KeyPoints[1].Position := EndPos;
  KeyPoints[1].Direction := dNorth;

  for Y := EndPos.Y to HeadPos.Y do
    Field[HeadPos.X, Y] := CellSnake;

  FreeCellCount := GetFreeCellCount();
end;

procedure TModuleSnake.CreateFood();
begin
  if TryGetRandomEmptyCell(Food) then
    Field[Food.X, Food.Y] := CellFood
  else
    Finish();
end;

function TModuleSnake.TryGetRandomEmptyCell(var EmptyCell: TPoint): Boolean;
var
  X, Y: Integer;
  ObjCellIndex, CurrentEmptyCellIndex: Integer;
begin
  ObjCellIndex := Random(FreeCellCount);

  CurrentEmptyCellIndex := -1;
  for X := 0 to FieldBounds.Width - 1 do
    for Y := 0 to FieldBounds.Height -1 do
    begin
      if Field[X, Y] = CellEmpty then
        Inc(CurrentEmptyCellIndex);

      if CurrentEmptyCellIndex = ObjCellIndex then
      begin
        EmptyCell.X := X;
        EmptyCell.Y := Y;
        Exit(True);
      end;
    end;

  Result := False;
end;

function TModuleSnake.GetFreeCellCount(): Integer;
var
  X, Y: Integer;
begin
  Result := 0;

  for X := 0 to FieldBounds.Width - 1 do
    for Y := 0 to FieldBounds.Height -1 do
      if Field[X, Y] = CellEmpty then
        Inc(Result);
end;

procedure TModuleSnake.Recalc();
var
  Last: Integer;
  HeadPos, EndPos: TPoint;
  FoodIsTaken: Boolean;
begin
  KeyPoints[0].Move();

  HeadPos := KeyPoints[0].Position;

  if not FieldBounds.Contains(HeadPos)
  or (Field[HeadPos.X, HeadPos.Y] = CellSnake) then
  begin
    Finish();
    Exit();
  end;

  FoodIsTaken := (Field[HeadPos.X, HeadPos.Y] = CellFood);

  Field[HeadPos.X, HeadPos.Y] := CellSnake;

  if FoodIsTaken then
  begin
    Inc(FScore, Round(ScorePerTakenObj * SpeedMultiplier));
    Dec(FreeCellCount);
    CreateFood();
    Exit();
  end;

  Last := High(KeyPoints);
  EndPos := KeyPoints[Last].Position;
  Field[EndPos.X, EndPos.Y] := CellEmpty;

  KeyPoints[Last].Move();

  if (Last > 0) and (KeyPoints[Last].Position = KeyPoints[Last-1].Position) then
    SetLength(KeyPoints, Last);
end;

procedure TModuleSnake.TakeInput(vkCode: Integer; IsReleased: Boolean);
var
  NewDirection: TDirection;
begin
  if vkCode = vkSpace then
  begin
    if IsReleased then
      SpeedMultiplier := 1
    else
      SpeedMultiplier := 3;

    SetRecalcIntervalInMillis(Round(GetRecalcInterval() / SpeedMultiplier));
    Exit();
  end;

  if IsReleased then
    Exit();

  case vkCode of
    vkUp: NewDirection := dNorth;
    vkRight: NewDirection := dEast;
    vkDown: NewDirection := dSouth;
    vkLeft: NewDirection := dWest;
    else Exit();
  end;

  if KeyPoints[0].Direction in [NewDirection, GetOppositeDirection(NewDirection)] then
    Exit();

  KeyPoints[0].Direction := NewDirection;
  KeyPoints := [KeyPoints[0]] + KeyPoints;
end;

function TModuleSnake.GetOppositeDirection(Dir: TDirection): TDirection;
begin
  case Dir of
    dNorth: Result := dSouth;
    dEast: Result := dWest;
    dSouth: Result := dNorth;
    else Result := dEast;
  end;
end;

function TModuleSnake.GetRecalcInterval(): Integer;
begin
  Result := 200;
end;

{ TMod2.TKeyPoint }

procedure TModuleSnake.TKeyPoint.Move();
begin
  case Direction of
    dNorth: Inc(Position.Y);
    dEast: Inc(Position.X);
    dSouth: Dec(Position.Y);
    dWest: Dec(Position.X);
  end;
end;

end.


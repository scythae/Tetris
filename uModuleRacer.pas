unit uModuleRacer;

interface

uses
  System.Types, System.UITypes, uModule, uModuleTetris;

type
  TModuleRacer = class(TModuleTetris)
  private type
    TObstacle = TShape;
    TInput = (inForward, inBackward, inLeft, inRight);
    TDurability = (dCrashed, d1, d2, d3);
  private const
    CellObstacle = CellShape;
    CellRacer = CellSolid;
    ScorePerPassedObstacle = 50;
    SpeedMultiplierIfForward = 4;
    SpeedMultiplierIfBackward = 0.5;
  private
    Obstacles: TArray<TObstacle>;
    Racer: TCells;
    Inputs: array [Low(TInput)..High(TInput)] of Boolean;
    IntervalBetweenObstaclesInCells: Integer;
    SpeedMultiplier: Single;
    RacerDurability: TDurability;
    DurabilityShapes: array [Low(TDurability)..High(TDurability)] of TCells;
    DurabilityIndicatorPosition: TPoint;
    procedure PutNewObstacle();
    function NewObstacleIsNeeded(): Boolean;
    function CollidedWithRacer(var Obstacle: TObstacle):Boolean;
    procedure MoveRacer(Input: TInput);
    function GetMaxObstacleBounds(): TRect;
    function CheckCrash(): Boolean;
    procedure MoveObstaclesDown;
    procedure RemovePassedObstacle;
    function LoadCells(const StringTemplate: string): TCells;
  protected
    procedure OnStart(); override;
    function GetRecalcInterval(): Integer; override;
  public
    procedure TakeInput(vkCode: Integer; IsReleased: Boolean = False); override;
    procedure Recalc(); override;
    function GetShapes(): TArray<TShape>; override;
  end;

implementation

function TModuleRacer.GetRecalcInterval(): Integer;
begin
  Result := 250;
end;

function TModuleRacer.GetShapes(): TArray<TShape>;
var
  DurabilityIndicator: TShape;
begin
  DurabilityIndicator.Cells := DurabilityShapes[RacerDurability];
  DurabilityIndicator.Position := DurabilityIndicatorPosition;
  DurabilityIndicator.CellType := CellSolid;
  Result := Obstacles + [DurabilityIndicator];
end;

procedure TModuleRacer.OnStart();
begin
  LoadShapes();
  DurabilityIndicatorPosition := GetSpecialIndicatorPosition();

  Racer := ShiftedCells(
    LoadCells(
      '.#.-' +
      '###-' +
      '.#.-' +
      '###-'),
    Point(FieldBounds.Width div 2 - 1, 5)
  );

  DurabilityShapes[dCrashed] := nil;
  DurabilityShapes[d1] := LoadCells(
    '.#.-' +
    '##.-' +
    '.#.-' +
    '.#.-' +
    '###-');
  DurabilityShapes[d2] := LoadCells(
    '###-' +
    '#.#-' +
    '..#-' +
    '.#.-' +
    '###-');
  DurabilityShapes[d3] := LoadCells(
    '###-' +
    '..#-' +
    '##.-' +
    '..#-' +
    '##.-');

  SetCellsOnField(Racer, CellRacer);

  IntervalBetweenObstaclesInCells := GetCellsBounds(Racer).Height + GetMaxObstacleBounds().Height + 1;
  RacerDurability := High(TDurability);
end;

function TModuleRacer.LoadCells(const StringTemplate: string): TCells;
begin
  Result := ReflectedVerticallyCells(GetCellsFromString(StringTemplate));
end;

function TModuleRacer.GetMaxObstacleBounds(): TRect;
var
  ST: TShapeType;
  SR: TShapeRotation;
  tmpBounds: TRect;
begin
  Result := TRect.Empty();

  for ST := Low(TShapeType) to High(TShapeType) do
    for SR := Low(TShapeRotation) to High(TShapeRotation) do
    begin
      tmpBounds := GetCellsBounds(Shapes[ST, SR]);
      if tmpBounds.Width > Result.Width then
        Result.Width := tmpBounds.Width;
      if tmpBounds.Height > Result.Height then
        Result.Height := tmpBounds.Height;
    end;
end;

procedure TModuleRacer.Recalc();
begin
  MoveObstaclesDown();

  if CheckCrash() then
    Exit();

  RemovePassedObstacle();

  if NewObstacleIsNeeded() then
    PutNewObstacle();
end;

procedure TModuleRacer.MoveObstaclesDown();
var
  I: Integer;
begin
  for I := 0 to High(Obstacles) do
    Dec(Obstacles[I].Position.Y);
end;

function TModuleRacer.CheckCrash(): Boolean;
var
  I: Integer;
begin
  for I := 0 to High(Obstacles) do
    if CollidedWithRacer(Obstacles[I]) then
    begin
      Obstacles[I].Cells := nil;
      Dec(RacerDurability);

      if RacerDurability > dCrashed then
        Continue;

      Finish();
      Exit(True);
    end;

  Result := False;
end;

procedure TModuleRacer.RemovePassedObstacle();
var
  LastIndex: Integer;
begin
  LastIndex := High(Obstacles);

  if (LastIndex >= 0) and (Obstacles[LastIndex].Position.Y < 0) then
  begin
    if Length(Obstacles[LastIndex].Cells) > 0 then
      Inc(FScore, Round(ScorePerPassedObstacle * SpeedMultiplier));

    SetLength(Obstacles, LastIndex);

    if GotMaxScore() then
      Finish();
  end;
end;

function TModuleRacer.CollidedWithRacer(var Obstacle: TObstacle): Boolean;
var
  Cell: TPoint;
begin
  for Cell in ShiftedCells(Obstacle.Cells, Obstacle.Position) do
    if FieldBounds.Contains(Cell) then
      if Field[Cell.X, Cell.Y] = CellRacer then
        Exit(True);

  Result := False;
end;

function TModuleRacer.NewObstacleIsNeeded(): Boolean;
begin
  if not Assigned(Obstacles) then
    Exit(True);

  Result := (FieldBounds.Height - Obstacles[0].Position.Y) > IntervalBetweenObstaclesInCells;
end;

procedure TModuleRacer.PutNewObstacle();
var
  Obstacle: TObstacle;
  ObstacleBounds: TRect;
  ST: TShapeType;
  SR: TShapeRotation;
begin
  ST := TEnum<TShapeType>.Random();
  SR := TEnum<TShapeRotation>.Random();

  Obstacle.Cells := Shapes[ST, SR];
  Obstacle.CellType := CellObstacle;

  ObstacleBounds := GetCellsBounds(Obstacle.Cells);
  Obstacle.Position := Point(
    Random(FieldBounds.Width - ObstacleBounds.Width + 1),
    FieldBounds.Height - 1
  );

  Obstacles := [Obstacle] + Obstacles;
end;

procedure TModuleRacer.TakeInput(vkCode: Integer; IsReleased: Boolean);
var
  tmpInput: TInput;
begin
  case vkCode of
    vkUp: tmpInput := inForward;
    vkRight: tmpInput := inRight;
    vkDown: tmpInput := inBackward;
    vkLeft: tmpInput := inLeft;
    else Exit();
  end;

  Inputs[tmpInput] := not IsReleased;

  if tmpInput in [inForward, inBackward] then
  begin
    if Inputs[inForward] then
      SpeedMultiplier := SpeedMultiplierIfForward
    else if Inputs[inBackward] then
      SpeedMultiplier := SpeedMultiplierIfBackward
    else
      SpeedMultiplier := 1;

    SetRecalcIntervalInMillis(Round(GetRecalcInterval() / SpeedMultiplier));
    Exit();
  end;

  if tmpInput in [inLeft, inRight] then
    if not IsReleased then
      MoveRacer(tmpInput)
    else if Inputs[inLeft] then
      MoveRacer(inLeft)
    else if Inputs[inRight] then
      MoveRacer(inRight);
end;

procedure TModuleRacer.MoveRacer(Input: TInput);
var
  Step: TPoint;
  Cell: TPoint;
  ShiftedRacer: TCells;
begin
  if Input = inLeft then
    Step := Point(-1, 0)
  else if Input = inRight then
    Step := Point(1, 0)
  else
    Exit();

  ShiftedRacer := ShiftedCells(Racer, Step);
  for Cell in ShiftedRacer do
    if not FieldBounds.Contains(Cell) then
      Exit();

  SetCellsOnField(Racer, CellEmpty);
  SetCellsOnField(ShiftedRacer, CellRacer);

  Racer := ShiftedRacer;

  CheckCrash();
end;

end.

unit uModule;

interface

uses
  System.Types, System.SysUtils, TypInfo;

const
  CellEmpty = 0;
  CellSolid = 1;
  CellShape = 2;

type
  TField = TArray<TArray<Integer>>;
  TCell = TPoint;
  TCells = TArray<TCell>;

  TShape = record
    Cells: TCells;
    Position: TCell;
    CellType: Integer;
  end;

  TModule = class
  public type
    TOnChangeRecalcInterval = reference to procedure(NewIntervalInMillis: Integer);
  private
    FFinished: Boolean;
    FField: TField;
    function GetField(X, Y: Integer): Integer; inline;
    procedure SetField(X, Y: Integer; const Value: Integer); inline;
    procedure AssertFieldCoords(X, Y: Integer); inline;
  protected
    FieldBounds: TRect;
    FScore: Cardinal;
    procedure SolidifyCells(Cells: TCells);
    procedure SetCellsOnField(Cells: TCells; CellType: Integer);
    procedure Finish();
    procedure SetRecalcIntervalInMillis(NewIntervalInMillis: Integer);
    procedure OnStart(); virtual;
    function GetRecalcInterval(): Integer; virtual;
    function GetSpecialIndicatorPosition(): TPoint;
    property Field[X: Integer; Y: Integer]: Integer read GetField write SetField;
  public
    OnChangeRecalcInterval: TOnChangeRecalcInterval;
    constructor Create(Field: TField); virtual; final;
    destructor Destroy(); override;
    procedure Start(); virtual; final;
    procedure Recalc(); virtual; abstract;
    procedure TakeInput(vkCode: Integer; IsReleased: Boolean = False); virtual; abstract;
    function GetShapes(): TArray<TShape>; virtual;
    property Score: Cardinal read FScore;
    property Finished: Boolean read FFinished;
    function GotMaxScore(): Boolean;
  end;

  TModuleClass = class of TModule;

  TEnum<T> = class
  strict private type
    PT = ^T;
  strict private class var
    MinVal: T;
    MaxVal: T;
    ByteMask: Cardinal;
  strict private
    class constructor Create();
    class function ToInt(Val: T): Integer;
    class function ToEnum(Val: Integer): T;
    class function Equal(Left, Right: T): Boolean;
  private
    class procedure Test();
  public
    class function Random(): T;
    class function Pred(Element: T): T;
    class function Succ(Element: T): T;
  end;

  function GetCellsBounds(Cells: TCells): TRect;
  function RotateCells90(Cells: TCells): TCells;

  function GetCellsFromString(const S: string): TCells;
  function ShiftedCells(Cells: TCells; Shift: TPoint): TCells;
  function ReflectedVerticallyCells(Cells: TCells): TCells;

implementation

{ TModule }

constructor TModule.Create(Field: TField);
begin
  Self.FField := Field;

  FieldBounds := Rect(0, 0, Length(Field), 0);

  if FieldBounds.Width = 0 then
    FieldBounds.Height := 0
  else
    FieldBounds.Height := Length(Field[0]);
end;

procedure TModule.Start();
begin
  SetRecalcIntervalInMillis(GetRecalcInterval());
  OnStart();
end;

procedure TModule.OnStart();
begin
end;

destructor TModule.Destroy();
begin
  SetRecalcIntervalInMillis(-1);
  inherited;
end;

procedure TModule.Finish();
begin
  FFinished := True;
end;

function TModule.GetSpecialIndicatorPosition(): TPoint;
begin
  Result := Point(FieldBounds.Width * 3 div 2 - 1, FieldBounds.Height * 2 div 3 - 1);
end;

function TModule.GotMaxScore(): Boolean;
begin
  Result := FScore > Cardinal(High(Integer));
end;

function TModule.GetRecalcInterval: Integer;
begin
  Result := 500;
end;

function TModule.GetShapes(): TArray<TShape>;
begin
  Result := nil;
end;

procedure TModule.SetCellsOnField(Cells: TCells; CellType: Integer);
var
  Cell: TCell;
begin
  for Cell in Cells do
    Field[Cell.X, Cell.Y] := CellType;
end;

procedure TModule.SetField(X, Y: Integer; const Value: Integer);
begin
  AssertFieldCoords(X, Y);
  FField[X, Y] := Value;
end;

function TModule.GetField(X, Y: Integer): Integer;
begin
  AssertFieldCoords(X, Y);
  Result := FField[X, Y];
end;

procedure TModule.AssertFieldCoords(X, Y: Integer);
begin
  Assert(
    FieldBounds.Contains(Point(X, Y)),
    'Got out of field''s bounds.'
  );
end;

procedure TModule.SetRecalcIntervalInMillis(NewIntervalInMillis: Integer);
begin
  if Assigned(OnChangeRecalcInterval) then
    OnChangeRecalcInterval(NewIntervalInMillis);
end;

procedure TModule.SolidifyCells(Cells: TCells);
begin
  SetCellsOnField(Cells, CellSolid);
end;

function RotateCells90(Cells: TCells): TCells;
var
  Ymin, Ymax: Integer;
  I: Integer;
  CellsBounds: TRect;
begin
  if not Assigned(Cells) then
    Exit(nil);

  CellsBounds := GetCellsBounds(Cells);
  Ymin := CellsBounds.Top;
  Ymax := CellsBounds.Bottom - 1;

  SetLength(Result, Length(Cells));
  for I := 0 to High(Cells) do
  begin
    Result[I].X := Ymax + Ymin - Cells[I].Y;
    Result[I].Y := Cells[I].X;
  end;
end;

function GetCellsBounds(Cells: TCells): TRect;
var
  Cell: TCell;
begin
  if not Assigned(Cells) then
    Exit(TRect.Empty());

  Result := TRect.Create(Cells[0]);

  for Cell in Cells do
  begin
    if Cell.Y < Result.Top then
      Result.Top := Cell.Y
    else
    if Cell.Y > Result.Bottom then
      Result.Bottom := Cell.Y;

    if Cell.X < Result.Left then
      Result.Left := Cell.X
    else
    if Cell.X > Result.Right then
      Result.Right := Cell.X;
  end;

  Inc(Result.Right);
  Inc(Result.Bottom);
end;

function GetCellsFromString(const S: string): TCells;
const
  RowDelimiter = '-';
  Solid = '#';
  Empty = '.';
var
  X, Y: Integer;
  Rows: TArray<string>;
begin
  Result := nil;

  Rows := S.Split([RowDelimiter]);

  for Y := 0 to Length(Rows) - 1 do
    for X := 0 to Length(Rows[Y]) - 1 do
      if Rows[Y].Chars[X] = Solid then
        Result := Result + [Point(X, Y)];
end;

function ShiftedCells(Cells: TCells; Shift: TPoint): TCells;
var
  I: Integer;
begin
  SetLength(Result, Length(Cells));
  for I := 0 to High(Result) do
    Result[I] := Cells[I].Add(Shift);
end;

function CopyCells(Cells: TCells; ModifyCell: TFunc<TCell, TCell> = nil): TCells;
var
  I: Integer;
begin
  SetLength(Result, Length(Cells));

  if Assigned(ModifyCell) then
    for I := 0 to High(Result) do
      Result[I] := ModifyCell(Cells[I])
  else
    for I := 0 to High(Result) do
      Result[I] := Cells[I];
end;

function ReflectedVerticallyCells(Cells: TCells): TCells;
var
  I: Integer;
begin
  SetLength(Result, Length(Cells));
  for I := 0 to High(Result) do
  begin
    Result[I].X := Cells[I].X;
    Result[I].Y := -Cells[I].Y;
  end;
end;

{ TEnum<T> }

class constructor TEnum<T>.Create();
var
  PI: PTypeInfo;
begin
  PI := PTypeInfo(TypeInfo(T));

  Assert(
    PI.Kind = tkEnumeration,
    'This class should be used for enumeration types only.'
  );

  case PI.TypeData.OrdType of
    otSByte, otUByte: ByteMask := $FF;
    otSWord, otUWord: ByteMask := $FFFF;
    otSLong, otULong: ByteMask := $FFFFFFFF;
  end;

  MinVal := ToEnum(PI.TypeData.MinValue);
  MaxVal := ToEnum(PI.TypeData.MaxValue);

  Test();
end;

class function TEnum<T>.Equal(Left, Right: T): Boolean;
begin
  Result := ToInt(Left) = ToInt(Right);
end;

class function TEnum<T>.Random(): T;
begin
  Result := ToEnum(System.Random(
    ToInt(MaxVal) + 1
  ));
end;

class function TEnum<T>.Pred(Element: T): T;
begin
  if Equal(Element, MinVal) then
    Result := MaxVal
  else
    Result := ToEnum(ToInt(Element) - 1);
end;

class function TEnum<T>.Succ(Element: T): T;
begin
  if Equal(Element, MaxVal) then
    Result := MinVal
  else
    Result := ToEnum(ToInt(Element) + 1);
end;

class procedure TEnum<T>.Test;
var
  RandomVal: T;
begin
  try
    Assert(Equal(MinVal, MinVal));
    Assert(Equal(MaxVal, MaxVal));
    Assert(Equal(MaxVal, Pred(MinVal)));
    Assert(Equal(MinVal, Succ(MaxVal)));

    RandomVal := Self.Random();
    Assert(Equal(RandomVal, RandomVal));
    Assert(Equal(RandomVal, Succ(Pred(RandomVal))));
  except
    raise Exception.Create('TEnum<T> error.');
  end;
end;

class function TEnum<T>.ToEnum(Val: Integer): T;
begin
  Result := PT(@Val)^;
end;

class function TEnum<T>.ToInt(Val: T): Integer;
begin
  Result := PInteger(@Val)^ and ByteMask;
end;

end.


unit UHelpers;

interface

uses
  Winapi.Windows, System.Classes, System.Math, System.SysUtils, System.Types,
  Vcl.Controls, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.CheckLst, Vcl.Menus,
  Vcl.ActnList;

type
  TComponentHelper = class helper for TComponent
  public
    function FindFirstComponent<T: TComponent>(CheckComponentFunc: TFunc<T, Boolean> = nil): T;
    function GetSingleton<T: TComponent>(): T;
    function GetComponentsRecursively(): TArray<TComponent>;
  end;

  TControlHelper = class helper for TControl
  public
    function GetControls(): TArray<TControl>;
    function GetControlsRecursive(): TArray<TControl>;
    procedure OverrideMouseEventsToMakeControlDraggable();
  end;

implementation

{ TComponentHelper }

function TComponentHelper.FindFirstComponent<T>(CheckComponentFunc: TFunc<T, Boolean>): T;
var
  I: Integer;
begin
  for I := 0 to ComponentCount - 1 do
    if Components[I] is T then
      if not Assigned(CheckComponentFunc) or CheckComponentFunc(Components[I]) then
        Exit(Components[I] as T);

  Result := nil;
end;

function TComponentHelper.GetComponentsRecursively(): TArray<TComponent>;
var
  Child: TComponent;
begin
  Result := nil;
  for Child in Self do
    Result := Result + [Child] + Child.GetComponentsRecursively();
end;

function TComponentHelper.GetSingleton<T>(): T;
begin
  Result := FindFirstComponent<T>();
  if not Assigned(Result) then
    Result := T.Create(Self);
end;

{ TControlDragMouseEvents }

type
  TControlDragMouseEvents = class(TComponent)
  private
    Dragged: Boolean;
    MouseDownPoint: TPoint;
    Control: TControl;
    procedure DoMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure DoMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure DoMouseMove(Sender: TObject; Shift: TShiftState;
    X, Y: Integer);
  private type
    TControlAccessor = class(Tcontrol);
  private
    inheritedMouseDown, inheritedMouseUp: TMouseEvent;
    inheritedMouseMove: TMouseMoveEvent;
    procedure Initialize(Control: TControl);
  end;

procedure TControlDragMouseEvents.DoMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Assigned(inheritedMouseDown) then
    inheritedMouseDown(Sender, Button, Shift, X, Y);

  Dragged := True;
  MouseDownPoint.X := X;
  MouseDownPoint.Y := Y;
end;

procedure TControlDragMouseEvents.DoMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  if Assigned(inheritedMouseMove) then
    inheritedMouseMove(Sender, Shift, X, Y);

  if not Dragged then
    Exit();

  Control.Left := Control.Left - MouseDownPoint.X + X;
  Control.Top := Control.Top - MouseDownPoint.Y + Y;
end;

procedure TControlDragMouseEvents.DoMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Assigned(inheritedMouseUp) then
    inheritedMouseUp(Sender, Button, Shift, X, Y);

  Dragged := False;
end;

procedure TControlDragMouseEvents.Initialize(Control: TControl);
begin
  Assert(Assigned(Control));
  Self.Control := Control;
  inheritedMouseDown := TControlAccessor(Control).OnMouseDown;
  inheritedMouseUp := TControlAccessor(Control).OnMouseUp;
  inheritedMouseMove := TControlAccessor(Control).OnMouseMove;
  TControlAccessor(Control).OnMouseDown := DoMouseDown;
  TControlAccessor(Control).OnMouseUp := DoMouseUp;
  TControlAccessor(Control).OnMouseMove := DoMouseMove;
  Control.Cursor := crHandPoint;
end;

{ TControlHelper }

function TControlHelper.GetControls(): TArray<TControl>;
var
  I: Integer;
  SelfAsWinControl: TWinControl absolute Self;
begin
  if not (Self is TWinControl) then
    Exit(nil);

  SetLength(Result, SelfAsWinControl.ControlCount);
  for I := 0 to High(Result) do
    Result[I] := SelfAsWinControl.Controls[I];
end;

function TControlHelper.GetControlsRecursive(): TArray<TControl>;
var
  Child: TControl;
begin
  Result := nil;
  for Child in GetControls() do
    Result := Result + [Child] + Child.GetControlsRecursive();
end;

procedure TControlHelper.OverrideMouseEventsToMakeControlDraggable;
begin
  if Assigned(Self.FindFirstComponent<TControlDragMouseEvents>()) then
    Exit();

  Self.GetSingleton<TControlDragMouseEvents>().Initialize(Self);
end;

end.

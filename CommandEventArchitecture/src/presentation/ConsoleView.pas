unit ConsoleView;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, TodoModel, AppEvents;

type
  TConsoleView = class
  private
    FModel: TTodoModel;
    FSelectedId: Integer;
  public
    constructor Create(AModel: TTodoModel);
    procedure HandleEvent(const AEvent: TAppEvent);
    procedure Render;
  end;

implementation

constructor TConsoleView.Create(AModel: TTodoModel);
begin
  inherited Create;
  FModel := AModel;
  FSelectedId := 0;
end;

procedure TConsoleView.HandleEvent(const AEvent: TAppEvent);
begin
  if AEvent is TSelectionChangedEvent then
    FSelectedId := TSelectionChangedEvent(AEvent).TodoId;

  if AEvent is TTodoChangedEvent then
  begin
    case TTodoChangedEvent(AEvent).Kind of
      tckAdded:   Writeln('[Event] TodoAdded id=', TTodoChangedEvent(AEvent).TodoId);
      tckDeleted: Writeln('[Event] TodoDeleted id=', TTodoChangedEvent(AEvent).TodoId);
      tckToggled: Writeln('[Event] TodoToggled id=', TTodoChangedEvent(AEvent).TodoId);
    end;
    Render;
  end;
end;

procedure TConsoleView.Render;
var
  I: Integer;
  Item: TTodoItem;
  Mark, Selected: string;
begin
  Writeln;
  Writeln('--- TODO LIJST ---');
  if FModel.Count = 0 then
    Writeln('(leeg)');
  for I := 0 to FModel.Count - 1 do
  begin
    Item := FModel.ItemAt(I);
    if Item.Completed then Mark := 'x' else Mark := ' ';
    if Item.Id = FSelectedId then Selected := ' < selected' else Selected := '';
    Writeln(Format('%d. [%s] %s%s', [Item.Id, Mark, Item.Title, Selected]));
  end;
end;

end.

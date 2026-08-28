unit TodoCommands;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, TodoModel, AppEvents, EventBus, CommandManager;

type
  TTodoCommand = class(TCommand)
  protected
    FModel: TTodoModel;
    FBus: TEventBus;
  public
    constructor Create(AModel: TTodoModel; ABus: TEventBus);
  end;

  TAddTodoCommand = class(TTodoCommand)
  private
    FTitle: string;
    FItem: TTodoItem;
    FInModel: Boolean;
  public
    constructor Create(AModel: TTodoModel; ABus: TEventBus; const ATitle: string);
    destructor Destroy; override;
    procedure Execute; override;
    procedure Undo; override;
    function Description: string; override;
  end;

  TDeleteTodoCommand = class(TTodoCommand)
  private
    FId: Integer;
    FItem: TTodoItem;
    FInModel: Boolean;
  public
    constructor Create(AModel: TTodoModel; ABus: TEventBus; AId: Integer);
    destructor Destroy; override;
    procedure Execute; override;
    procedure Undo; override;
    function Description: string; override;
  end;

  TToggleTodoCommand = class(TTodoCommand)
  private
    FId: Integer;
  public
    constructor Create(AModel: TTodoModel; ABus: TEventBus; AId: Integer);
    procedure Execute; override;
    procedure Undo; override;
    function Description: string; override;
  end;

implementation

constructor TTodoCommand.Create(AModel: TTodoModel; ABus: TEventBus);
begin
  inherited Create;
  FModel := AModel;
  FBus := ABus;
end;

constructor TAddTodoCommand.Create(AModel: TTodoModel; ABus: TEventBus; const ATitle: string);
begin
  inherited Create(AModel, ABus);
  FTitle := ATitle;
  FItem := nil;
  FInModel := False;
end;

destructor TAddTodoCommand.Destroy;
begin
  if not FInModel then
    FItem.Free;
  inherited Destroy;
end;

procedure TAddTodoCommand.Execute;
begin
  if FItem = nil then
    FItem := TTodoItem.Create(FModel.NewId, FTitle);
  FModel.AddItem(FItem);
  FInModel := True;
  FBus.Publish(TTodoChangedEvent.Create(FItem.Id, tckAdded));
  FBus.Publish(TSelectionChangedEvent.Create(FItem.Id));
end;

procedure TAddTodoCommand.Undo;
begin
  FItem := FModel.ExtractItem(FItem.Id);
  FInModel := False;
  FBus.Publish(TTodoChangedEvent.Create(FItem.Id, tckDeleted));
end;

function TAddTodoCommand.Description: string;
begin
  Result := 'Todo toevoegen: ' + FTitle;
end;

constructor TDeleteTodoCommand.Create(AModel: TTodoModel; ABus: TEventBus; AId: Integer);
begin
  inherited Create(AModel, ABus);
  FId := AId;
  FItem := nil;
  FInModel := True;
end;

destructor TDeleteTodoCommand.Destroy;
begin
  if not FInModel then
    FItem.Free;
  inherited Destroy;
end;

procedure TDeleteTodoCommand.Execute;
begin
  FItem := FModel.ExtractItem(FId);
  if FItem = nil then
    raise Exception.CreateFmt('Todo %d bestaat niet', [FId]);
  FInModel := False;
  FBus.Publish(TTodoChangedEvent.Create(FId, tckDeleted));
end;

procedure TDeleteTodoCommand.Undo;
begin
  FModel.AddItem(FItem);
  FInModel := True;
  FBus.Publish(TTodoChangedEvent.Create(FId, tckAdded));
  FBus.Publish(TSelectionChangedEvent.Create(FId));
end;

function TDeleteTodoCommand.Description: string;
begin
  Result := Format('Todo %d verwijderen', [FId]);
end;

constructor TToggleTodoCommand.Create(AModel: TTodoModel; ABus: TEventBus; AId: Integer);
begin
  inherited Create(AModel, ABus);
  FId := AId;
end;

procedure TToggleTodoCommand.Execute;
var
  Item: TTodoItem;
begin
  Item := FModel.FindItem(FId);
  if Item = nil then
    raise Exception.CreateFmt('Todo %d bestaat niet', [FId]);
  Item.Completed := not Item.Completed;
  FBus.Publish(TTodoChangedEvent.Create(FId, tckToggled));
  FBus.Publish(TSelectionChangedEvent.Create(FId));
end;

procedure TToggleTodoCommand.Undo;
begin
  Execute;
end;

function TToggleTodoCommand.Description: string;
begin
  Result := Format('Todo %d omschakelen', [FId]);
end;

end.

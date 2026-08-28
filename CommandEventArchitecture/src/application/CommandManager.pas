unit CommandManager;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Contnrs;

type
  TCommand = class
  public
    procedure Execute; virtual; abstract;
    procedure Undo; virtual; abstract;
    function Description: string; virtual; abstract;
  end;

  TCommandManager = class
  private
    FUndoStack: TObjectList;
    FRedoStack: TObjectList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure ExecuteCommand(ACommand: TCommand);
    procedure Undo;
    procedure Redo;
  end;

implementation

constructor TCommandManager.Create;
begin
  inherited Create;
  FUndoStack := TObjectList.Create(True);
  FRedoStack := TObjectList.Create(True);
end;

destructor TCommandManager.Destroy;
begin
  FRedoStack.Free;
  FUndoStack.Free;
  inherited Destroy;
end;

procedure TCommandManager.ExecuteCommand(ACommand: TCommand);
begin
  if ACommand = nil then
    Exit;
  try
    ACommand.Execute;
    FUndoStack.Add(ACommand);
    FRedoStack.Clear;
    Writeln('[Command] ', ACommand.Description);
  except
    ACommand.Free;
    raise;
  end;
end;

procedure TCommandManager.Undo;
var
  Command: TCommand;
begin
  if FUndoStack.Count = 0 then
  begin
    Writeln('[Undo] niets om ongedaan te maken');
    Exit;
  end;
  Command := TCommand(FUndoStack.Extract(FUndoStack.Last));
  Command.Undo;
  FRedoStack.Add(Command);
  Writeln('[Undo] ', Command.Description);
end;

procedure TCommandManager.Redo;
var
  Command: TCommand;
begin
  if FRedoStack.Count = 0 then
  begin
    Writeln('[Redo] niets om opnieuw uit te voeren');
    Exit;
  end;
  Command := TCommand(FRedoStack.Extract(FRedoStack.Last));
  Command.Execute;
  FUndoStack.Add(Command);
  Writeln('[Redo] ', Command.Description);
end;

end.

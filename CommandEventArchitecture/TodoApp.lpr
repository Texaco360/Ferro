program TodoApp;

{$mode objfpc}{$H+}

uses
  SysUtils,
  TodoModel,
  AppEvents,
  EventBus,
  CommandManager,
  TodoCommands,
  ConsoleView;

var
  Model: TTodoModel;
  Bus: TEventBus;
  Commands: TCommandManager;
  View: TConsoleView;
  Choice, TitleText, IdText: string;
  Id: Integer;
begin
  Model := TTodoModel.Create;
  Bus := TEventBus.Create;
  Commands := TCommandManager.Create;
  View := TConsoleView.Create(Model);
  try
    Bus.Subscribe(TTodoChangedEvent, @View.HandleEvent);
    Bus.Subscribe(TSelectionChangedEvent, @View.HandleEvent);

    Writeln('Event-driven Free Pascal Todo');
    View.Render;

    repeat
      WriteLn;
      Write('[a]dd [t]oggle [d]elete [l]ist [u]ndo [r]edo [q]uit: ');
      ReadLn(Choice);
      Choice := LowerCase(Trim(Choice));

      if Choice = 'a' then
      begin
        Write('Titel: ');
        ReadLn(TitleText);
        if Trim(TitleText) <> '' then
          Commands.ExecuteCommand(
            TAddTodoCommand.Create(Model, Bus, TitleText)
          );
      end
      else if Choice = 't' then
      begin
        Write('Todo-id: ');
        ReadLn(IdText);
        if TryStrToInt(IdText, Id) then
          Commands.ExecuteCommand(
            TToggleTodoCommand.Create(Model, Bus, Id)
          );
      end
      else if Choice = 'd' then
      begin
        Write('Todo-id: ');
        ReadLn(IdText);
        if TryStrToInt(IdText, Id) then
          Commands.ExecuteCommand(
            TDeleteTodoCommand.Create(Model, Bus, Id)
          );
      end
      else if Choice = 'l' then
        View.Render
      else if Choice = 'u' then
        Commands.Undo
      else if Choice = 'r' then
        Commands.Redo;
    until Choice = 'q';
  finally
    { Subscribers moeten verdwijnen voordat de bus verdwijnt. }
    View.Free;
    Commands.Free;
    Bus.Free;
    Model.Free;
  end;
end.

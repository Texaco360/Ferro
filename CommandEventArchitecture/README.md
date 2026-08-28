# Free Pascal Todo, CommandManager + EventBus

Een kleine consoleapplicatie die dezelfde flow toont als een CAD-app:

```
UI -> CommandManager -> Command -> Domain Model -> EventBus -> View
```

## Bouwen

```bash
fpc -Mobjfpc -Fu./src/domain -Fu./src/application -Fu./src/presentation -FE./build -FU./build TodoApp.lpr
./Build/TodoApp
```

Of:

```bash
make
```

## Commando's in de applicatie

- `a` add todo
- `t` toggle completed
- `d` delete todo
- `l` list
- `u` undo
- `r` redo
- `q` quit

## Architectuur

- `todo_model.pas`: domeinmodel, kent geen UI, CommandManager of EventBus.
- `app_events.pas`: event-contracten.
- `event_bus.pas`: synchronous in-process publish/subscribe.
- `todo_commands.pas`: wijzigingen en bijhorende events.
- `command_manager.pas`: Execute, Undo en Redo.
- `console_view.pas`: View die events ontvangt en zichzelf opnieuw toont.

De EventBus is bewust synchroon. Een queue/background worker is een apart concept en hoort niet in deze eerste demo.

unit AppEvents;

{$mode objfpc}{$H+}

interface

type
  TTodoChangeKind = (tckAdded, tckDeleted, tckToggled);

  TAppEvent = class
  end;

  TTodoChangedEvent = class(TAppEvent)
  public
    TodoId: Integer;
    Kind: TTodoChangeKind;
    constructor Create(ATodoId: Integer; AKind: TTodoChangeKind);
  end;

  TSelectionChangedEvent = class(TAppEvent)
  public
    TodoId: Integer;
    constructor Create(ATodoId: Integer);
  end;

implementation

constructor TTodoChangedEvent.Create(ATodoId: Integer; AKind: TTodoChangeKind);
begin
  inherited Create;
  TodoId := ATodoId;
  Kind := AKind;
end;

constructor TSelectionChangedEvent.Create(ATodoId: Integer);
begin
  inherited Create;
  TodoId := ATodoId;
end;

end.

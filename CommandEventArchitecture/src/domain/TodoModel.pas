unit TodoModel;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Contnrs;

type
  TTodoItem = class
  private
    FId: Integer;
    FTitle: string;
    FCompleted: Boolean;
  public
    constructor Create(AId: Integer; const ATitle: string);
    property Id: Integer read FId;
    property Title: string read FTitle write FTitle;
    property Completed: Boolean read FCompleted write FCompleted;
  end;

  TTodoModel = class
  private
    FItems: TObjectList;
    FNextId: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    function NewId: Integer;
    procedure AddItem(AItem: TTodoItem);
    function ExtractItem(AId: Integer): TTodoItem;
    function FindItem(AId: Integer): TTodoItem;
    function Count: Integer;
    function ItemAt(AIndex: Integer): TTodoItem;
  end;

implementation

constructor TTodoItem.Create(AId: Integer; const ATitle: string);
begin
  inherited Create;
  FId := AId;
  FTitle := ATitle;
  FCompleted := False;
end;

constructor TTodoModel.Create;
begin
  inherited Create;
  FItems := TObjectList.Create(True);
  FNextId := 1;
end;

destructor TTodoModel.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

function TTodoModel.NewId: Integer;
begin
  Result := FNextId;
  Inc(FNextId);
end;

procedure TTodoModel.AddItem(AItem: TTodoItem);
begin
  if AItem = nil then
    raise Exception.Create('Todo mag niet nil zijn');
  FItems.Add(AItem);
end;

function TTodoModel.ExtractItem(AId: Integer): TTodoItem;
begin
  Result := FindItem(AId);
  if Result <> nil then
    FItems.Extract(Result);
end;

function TTodoModel.FindItem(AId: Integer): TTodoItem;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to FItems.Count - 1 do
    if TTodoItem(FItems[I]).Id = AId then
      Exit(TTodoItem(FItems[I]));
end;

function TTodoModel.Count: Integer;
begin
  Result := FItems.Count;
end;

function TTodoModel.ItemAt(AIndex: Integer): TTodoItem;
begin
  Result := TTodoItem(FItems[AIndex]);
end;

end.

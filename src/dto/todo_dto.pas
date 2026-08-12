unit todo_dto;

{$mode objfpc}{$H+}

interface

uses
  Contnrs,
  fpjson,
  base_dto;

type
  TTodoDTO = class(TBaseDTO)
  public
    Id : Integer;
    Title : String;
    Completed : Boolean;

    constructor Create; overload;
    constructor Create(
      const AId: Integer;
      const ATitle: String;
      const ACompleted: Boolean
    ); overload;

    class function FromCreateJSON(const ABody: String): TTodoDTO; static;
    class function FromUpdateJSON(const ABody: String): TTodoDTO; static;
  end;

  TTodoDTOList = class(TObjectList)
  public
    function ItemAt(const AIndex: Integer): TTodoDTO;
  end;

implementation

constructor TTodoDTO.Create;
begin
  inherited Create;
  Id := 0;
  Title := '';
  Completed := False;
end;

constructor TTodoDTO.Create(
  const AId: Integer;
  const ATitle: String;
  const ACompleted: Boolean
);
begin
  inherited Create;
  Id := AId;
  Title := ATitle;
  Completed := ACompleted;
end;

function TTodoDTOList.ItemAt(const AIndex: Integer): TTodoDTO;
begin
  Result := TTodoDTO(Items[AIndex]);
end;

class function TTodoDTO.FromCreateJSON(const ABody: String): TTodoDTO;
var
  Data: TJSONObject;
begin
  Data := ParseRequestBody(ABody);
  try
    Result := TTodoDTO.Create;
    Result.Title := RequireStringField(Data, 'title');
  finally
    Data.Free;
  end;
end;

class function TTodoDTO.FromUpdateJSON(
  const ABody: String
): TTodoDTO;
var
  Data: TJSONObject;
begin
  Data := ParseRequestBody(ABody);
  try
    Result := TTodoDTO.Create;
    Result.Title := RequireStringField(Data, 'title');
    Result.Completed := RequireBooleanField(Data, 'completed');
  finally
    Data.Free;
  end;
end;

end.
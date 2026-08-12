unit project_dto;

{$mode objfpc}{$H+}

interface

uses
  Contnrs,
  fpjson,
  base_dto;

type
  TProjectDTO = class(TBaseDTO)
  public
    Id: Integer;
    Name: String;
    CreatedAt: String;

    constructor Create; overload;
    constructor Create(
      const AId: Integer;
      const AName: String;
      const ACreatedAt: String
    ); overload;

    class function FromCreateJSON(const ABody: String): TProjectDTO; static;
    class function FromUpdateJSON(const ABody: String): TProjectDTO; static;
  end;

  TProjectDTOList = class(TObjectList)
  public
    function ItemAt(const AIndex: Integer): TProjectDTO;
  end;

implementation

constructor TProjectDTO.Create;
begin
  inherited Create;
  Id := 0;
  Name := '';
  CreatedAt := '';
end;

constructor TProjectDTO.Create(
  const AId: Integer;
  const AName: String;
  const ACreatedAt: String
);
begin
  inherited Create;
  Id := AId;
  Name := AName;
  CreatedAt := ACreatedAt;
end;

function TProjectDTOList.ItemAt(const AIndex: Integer): TProjectDTO;
begin
  Result := TProjectDTO(Items[AIndex]);
end;

class function TProjectDTO.FromCreateJSON(const ABody: String): TProjectDTO;
var
  Data: TJSONObject;
begin
  Data := ParseRequestBody(ABody);
  try
    Result := TProjectDTO.Create;
    Result.Name := RequireStringField(Data, 'name');
  finally
    Data.Free;
  end;
end;

class function TProjectDTO.FromUpdateJSON(const ABody: String): TProjectDTO;
var
  Data: TJSONObject;
begin
  Data := ParseRequestBody(ABody);
  try
    Result := TProjectDTO.Create;
    Result.Name := RequireStringField(Data, 'name');
  finally
    Data.Free;
  end;
end;

end.

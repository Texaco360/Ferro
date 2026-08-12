unit todo_resource;

{$mode objfpc}{$H+}

interface

uses
  fpjson,
  todo_dto;

type
  TTodoResource = class
  public
    class function One(const AItem: TTodoDTO): TJSONObject; static;
    class function Many(const AItems: TTodoDTOList): TJSONArray; static;
  end;

implementation

class function TTodoResource.One(const AItem: TTodoDTO): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('id', AItem.Id);
  Result.Add('title', AItem.Title);
  Result.Add('completed', AItem.Completed);
end;

class function TTodoResource.Many(const AItems: TTodoDTOList): TJSONArray;
var
  I: Integer;
begin
  Result := TJSONArray.Create;

  for I := 0 to AItems.Count - 1 do
    Result.Add(One(AItems.ItemAt(I)));
end;

end.

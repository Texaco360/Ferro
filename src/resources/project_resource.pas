unit project_resource;

{$mode objfpc}{$H+}

interface

uses
  fpjson,
  project_dto;

type
  TProjectResource = class
  public
    class function One(const AItem: TProjectDTO): TJSONObject; static;
    class function Many(const AItems: TProjectDTOList): TJSONArray; static;
  end;

implementation

class function TProjectResource.One(const AItem: TProjectDTO): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('id', AItem.Id);
  Result.Add('name', AItem.Name);
  Result.Add('created_at', AItem.CreatedAt);
end;

class function TProjectResource.Many(const AItems: TProjectDTOList): TJSONArray;
var
  I: Integer;
begin
  Result := TJSONArray.Create;

  for I := 0 to AItems.Count - 1 do
    Result.Add(One(AItems.ItemAt(I)));
end;

end.

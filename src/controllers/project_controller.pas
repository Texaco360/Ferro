unit project_controller;

{$mode objfpc}{$H+}

interface

uses
  Horse,
  SysUtils,
  fpjson,
  controller,
  project_repository;

type
  TProjectController = class(TBaseController)
  private
    class var FRepository: TProjectRepository;
    class function Repository: TProjectRepository; static;

  public
    class destructor Destroy;

    class procedure GetAll(
      Req : THorseRequest;
      Res : THorseResponse); static;

    class procedure GetById(
      Req : THorseRequest;
      Res : THorseResponse); static;

    class procedure Create(
      Req : THorseRequest;
      Res : THorseResponse); static;

    class procedure Update(
      Req : THorseRequest;
      Res : THorseResponse); static;

    class procedure Delete(
      Req : THorseRequest;
      Res : THorseResponse); static;
  end;

implementation

class function TProjectController.Repository: TProjectRepository;
begin
  if FRepository = nil then
    FRepository := TProjectRepository.Create;

  Result := FRepository;
end;

class destructor TProjectController.Destroy;
begin
  FreeAndNil(FRepository);
end;

class procedure TProjectController.GetAll(
  Req : THorseRequest;
  Res : THorseResponse);
var
  Items: TJSONArray;
begin
  Items := nil;
  try
    Items := Repository.GetAll;
    SendJSON(Res, Items);
  finally
    Items.Free;
  end;
end;

class procedure TProjectController.GetById(
  Req : THorseRequest;
  Res : THorseResponse);
var
  ItemId: Integer;
  Item: TJSONObject;
begin
  Item := nil;
  ItemId := ParamAsInt(Req, 'id');
  try
    Item := Repository.GetById(ItemId);
    SendJSON(Res, Item);
  finally
    Item.Free;
  end;
end;

class procedure TProjectController.Create(
  Req : THorseRequest;
  Res : THorseResponse);
var
  Item: TJSONObject;
  ItemId: Integer;
begin
  Item := TJSONObject(GetJSON(Req.Body));
  try
    ItemId := Repository.CreateProject(Item.Strings['name']);
    Item.Add('id', ItemId);
    SendJSON(Res, Item, 201);
  finally
    Item.Free;
  end;
end;

class procedure TProjectController.Update(
  Req : THorseRequest;
  Res : THorseResponse);
var
  ItemId: Integer;
  Item: TJSONObject;
begin
  Item := TJSONObject(GetJSON(Req.Body));
  ItemId := ParamAsInt(Req, 'id');
  try
    Repository.Update(ItemId, Item.Strings['name']);
    SendJSON(Res, Item);
  finally
    Item.Free;
  end;
end;

class procedure TProjectController.Delete(
  Req : THorseRequest;
  Res : THorseResponse);
var
  ItemId: Integer;
begin
  ItemId := ParamAsInt(Req, 'id');
  Repository.Delete(ItemId);
  SendNoContent(Res);
end;

end.

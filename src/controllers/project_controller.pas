unit project_controller;

{$mode objfpc}{$H+}

interface

uses
  Horse,
  SysUtils,
  fpjson,
  controller,
  project_repository,
  project_service;

type
  TProjectController = class(TBaseController)
  private
    class var FRepository: TProjectRepository;
    class var FService: TProjectService;
    class function Repository: TProjectRepository; static;
    class function Service: TProjectService; static;

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

class function TProjectController.Service: TProjectService;
begin
  if FService = nil then
    FService := TProjectService.Create(Repository);

  Result := FService;
end;

class destructor TProjectController.Destroy;
begin
  FreeAndNil(FService);
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
    Items := Service.GetAll;
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
    Item := Service.GetById(ItemId);
    SendJSON(Res, Item);
  finally
    Item.Free;
  end;
end;

class procedure TProjectController.Create(
  Req : THorseRequest;
  Res : THorseResponse);
var
  ReqItem: TJSONObject;
  ResItem: TJSONObject;
  ItemName: String;
begin
  ReqItem := TJSONObject(GetJSON(Req.Body));
  ResItem := nil;
  try
    ItemName := ReqItem.Strings['name'];
    ResItem := Service.CreateProject(ItemName);
    SendJSON(Res, ResItem, 201);
  finally
    ReqItem.Free;
    ResItem.Free;
  end;
end;

class procedure TProjectController.Update(
  Req : THorseRequest;
  Res : THorseResponse);
var
  ItemId: Integer;
  ReqItem: TJSONObject;
  ResItem: TJSONObject;
  ItemName: String;
begin
  ReqItem := TJSONObject(GetJSON(Req.Body));
  ResItem := nil;
  ItemId := ParamAsInt(Req, 'id');
  try
    ItemName := ReqItem.Strings['name'];
    ResItem := Service.UpdateProject(ItemId, ItemName);
    SendJSON(Res, ResItem);
  finally
    ReqItem.Free;
    ResItem.Free;
  end;
end;

class procedure TProjectController.Delete(
  Req : THorseRequest;
  Res : THorseResponse);
var
  ItemId: Integer;
begin
  ItemId := ParamAsInt(Req, 'id');
  Service.DeleteProject(ItemId);
  SendNoContent(Res);
end;

end.

unit project_controller;

{$mode objfpc}{$H+}

interface

uses
  Horse,
  SysUtils,
  fpjson,
  project_dto,
  project_resource,
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
  Items: TProjectDTOList;
  Payload: TJSONArray;
begin
  Items := nil;
  Payload := nil;
  try
    Items := Service.GetAll;
    Payload := TProjectResource.Many(Items);
    SendJSON(Res, Payload);
  finally
    Items.Free;
    Payload.Free;
  end;
end;

class procedure TProjectController.GetById(
  Req : THorseRequest;
  Res : THorseResponse);
var
  ItemId: Integer;
  Item: TProjectDTO;
  Payload: TJSONObject;
begin
  Item := nil;
  Payload := nil;
  ItemId := ParamAsInt(Req, 'id');
  try
    Item := Service.GetById(ItemId);
    if Item = nil then
    begin
      SendNoContent(Res);
      Exit;
    end;

    Payload := TProjectResource.One(Item);
    SendJSON(Res, Payload);
  finally
    Item.Free;
    Payload.Free;
  end;
end;

class procedure TProjectController.Create(
  Req : THorseRequest;
  Res : THorseResponse);
var
  ReqItem: TProjectDTO;
  ResItem: TProjectDTO;
  Payload: TJSONObject;
begin
  ReqItem := nil;
  ResItem := nil;
  Payload := nil;
  try
    ReqItem := TProjectDTO.FromCreateJSON(Req.Body);
    ResItem := Service.CreateProject(ReqItem);
    Payload := TProjectResource.One(ResItem);
    SendJSON(Res, Payload, 201);
  finally
    ReqItem.Free;
    ResItem.Free;
    Payload.Free;
  end;
end;

class procedure TProjectController.Update(
  Req : THorseRequest;
  Res : THorseResponse);
var
  ItemId: Integer;
  ReqItem: TProjectDTO;
  ResItem: TProjectDTO;
  Payload: TJSONObject;
begin
  ReqItem := nil;
  ResItem := nil;
  Payload := nil;
  ItemId := ParamAsInt(Req, 'id');
  try
    ReqItem := TProjectDTO.FromUpdateJSON(Req.Body);
    ResItem := Service.UpdateProject(ItemId, ReqItem);
    if ResItem = nil then
    begin
      SendNoContent(Res);
      Exit;
    end;

    Payload := TProjectResource.One(ResItem);
    SendJSON(Res, Payload);
  finally
    ReqItem.Free;
    ResItem.Free;
    Payload.Free;
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

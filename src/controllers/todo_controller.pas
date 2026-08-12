unit todo_controller;

{$mode objfpc}{$H+}

interface

uses
  Horse,
  SysUtils,
  fpjson,
  todo_dto,
  todo_resource,
  controller,
  todo_repository,
  todo_service;

type
  TTodoController = class(TBaseController)
  private
    class var FRepository: TTodoRepository;
    class var FService: TTodoService;
    class function Repository: TTodoRepository; static;
    class function Service: TTodoService; static;

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

class function TTodoController.Repository: TTodoRepository;
begin
  if FRepository = nil then
    FRepository := TTodoRepository.Create;

  Result := FRepository;
end;

class function TTodoController.Service: TTodoService;
begin
  if FService = nil then
    FService := TTodoService.Create(Repository);

  Result := FService;
end;

class destructor TTodoController.Destroy;
begin
  FreeAndNil(FService);
  FreeAndNil(FRepository);
end;

class procedure TTodoController.GetAll(
  Req : THorseRequest;
  Res : THorseResponse);
var
  Todos: TTodoDTOList;
  Payload: TJSONArray;
begin
  Todos := nil;
  Payload := nil;

  try
    Todos := Service.GetAll;
    Payload := TTodoResource.Many(Todos);
    SendJSON(Res, Payload);
  finally
    Todos.Free;
    Payload.Free;
  end;
end;

class procedure TTodoController.GetById(
  Req : THorseRequest;
  Res : THorseResponse);
var
  TodoId: Integer;
  Todo: TTodoDTO;
  Payload: TJSONObject;
begin
  Todo := nil;
  Payload := nil;
  TodoId := ParamAsInt(Req, 'id');
  try
    Todo := Service.GetById(TodoId);
    if Todo = nil then
    begin
      SendNoContent(Res);
      Exit;
    end;

    Payload := TTodoResource.One(Todo);
    SendJSON(Res, Payload);
  finally
    Todo.Free;
    Payload.Free;
  end;
end;

class procedure TTodoController.Create(
  Req : THorseRequest;
  Res : THorseResponse);
var
  ReqTodo: TTodoDTO;
  ResTodo: TTodoDTO;
  Payload: TJSONObject;
begin
  ReqTodo := nil;
  ResTodo := nil;
  Payload := nil;
  try
    ReqTodo := TTodoDTO.FromCreateJSON(Req.Body);
    ResTodo := Service.CreateTodo(ReqTodo);
    Payload := TTodoResource.One(ResTodo);
    SendJSON(Res, Payload, 201);
  finally
    ReqTodo.Free;
    ResTodo.Free;
    Payload.Free;
  end;
end;

class procedure TTodoController.Update(
  Req : THorseRequest;
  Res : THorseResponse);
var
  TodoId: Integer;
  ReqTodo: TTodoDTO;
  ResTodo: TTodoDTO;
  Payload: TJSONObject;
begin
  ReqTodo := nil;
  ResTodo := nil;
  Payload := nil;
  TodoId := ParamAsInt(Req, 'id');
  try
    ReqTodo := TTodoDTO.FromUpdateJSON(Req.Body);
    ResTodo := Service.UpdateTodo(TodoId, ReqTodo);

    if ResTodo = nil then
    begin
      SendNoContent(Res);
      Exit;
    end;

    Payload := TTodoResource.One(ResTodo);
    SendJSON(Res, Payload);
  finally
    ReqTodo.Free;
    ResTodo.Free;
    Payload.Free;
  end;
end;

class procedure TTodoController.Delete(
  Req : THorseRequest;
  Res : THorseResponse);
var
  TodoId: Integer;
begin
  TodoId := ParamAsInt(Req, 'id');
  Service.DeleteTodo(TodoId);
  SendNoContent(Res);
end;

end.

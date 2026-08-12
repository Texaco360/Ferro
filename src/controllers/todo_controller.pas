unit todo_controller;

{$mode objfpc}{$H+}

interface

uses
  Horse,
  SysUtils,
  fpjson,
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
  Todos: TJSONArray;
begin
  Todos := nil;

  try
    Todos := Service.GetAll;
    SendJSON(Res, Todos);
  finally
    Todos.Free;
  end;
end;

class procedure TTodoController.GetById(
  Req : THorseRequest;
  Res : THorseResponse);
var
  TodoId: Integer;
  Todo: TJSONObject;
begin
  Todo := nil;
  TodoId := ParamAsInt(Req, 'id');
  try
    Todo := Service.GetById(TodoId);
    SendJSON(Res, Todo);
  finally
    Todo.Free;
  end;
end;

class procedure TTodoController.Create(
  Req : THorseRequest;
  Res : THorseResponse);
var
  ReqTodo: TJSONObject;
  ResTodo: TJSONObject;
  Title: String;
begin
  ReqTodo := TJSONObject(GetJSON(Req.Body));
  ResTodo := nil;
  try
    Title := ReqTodo.Strings['title'];
    ResTodo := Service.CreateTodo(Title);
    SendJSON(Res, ResTodo, 201);
  finally
    ReqTodo.Free;
    ResTodo.Free;
  end;
end;

class procedure TTodoController.Update(
  Req : THorseRequest;
  Res : THorseResponse);
var
  TodoId: Integer;
  ReqTodo: TJSONObject;
  ResTodo: TJSONObject;
  Title: String;
  Completed: Boolean;
begin
  ReqTodo := TJSONObject(GetJSON(Req.Body));
  ResTodo := nil;
  TodoId := ParamAsInt(Req, 'id');
  try
    Title := ReqTodo.Strings['title'];
    Completed := ReqTodo.Booleans['completed'];
    ResTodo := Service.UpdateTodo(TodoId, Title, Completed);
    SendJSON(Res, ResTodo);
  finally
    ReqTodo.Free;
    ResTodo.Free;
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

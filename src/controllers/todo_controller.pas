unit todo_controller;

{$mode objfpc}{$H+}

interface

uses
  Horse,
  SysUtils,
  fpjson,
  controller,
  todo_repository;

type
  TTodoController = class(TBaseController)
  private
    class var FRepository: TTodoRepository;
    class function Repository: TTodoRepository; static;

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

class destructor TTodoController.Destroy;
begin
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
    Todos := Repository.GetAll;
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
    Todo := Repository.GetById(TodoId);
    SendJSON(Res, Todo);
  finally
    Todo.Free;
  end;
end;

class procedure TTodoController.Create(
  Req : THorseRequest;
  Res : THorseResponse);
var
  Todo: TJSONObject;
  TodoId: Integer;
begin
  Todo := TJSONObject(GetJSON(Req.Body));
  try
    TodoId := Repository.CreateTodo(Todo.Strings['title']);
    Todo.Add('id', TodoId);
    SendJSON(Res, Todo, 201);
  finally
    Todo.Free;
  end;
end;

class procedure TTodoController.Update(
  Req : THorseRequest;
  Res : THorseResponse);
var
  TodoId: Integer;
  Todo: TJSONObject;
begin
  Todo := TJSONObject(GetJSON(Req.Body));
  TodoId := ParamAsInt(Req, 'id');
  try
    Repository.Update(TodoId, Todo.Strings['title'], Todo.Booleans['completed']);
    SendJSON(Res, Todo);
  finally
    Todo.Free;
  end;
end;

class procedure TTodoController.Delete(
  Req : THorseRequest;
  Res : THorseResponse);
var
  TodoId: Integer;
begin
  TodoId := ParamAsInt(Req, 'id');
  Repository.Delete(TodoId);
  SendNoContent(Res);
end;

end.

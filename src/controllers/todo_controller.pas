unit todo_controller;

{$mode objfpc}{$H+}

interface

uses
  Horse,
  SysUtils,
  fpjson;

procedure GetTodos(
  Req : THorseRequest;
  Res : THorseResponse);

procedure GetTodoById(
  Req : THorseRequest;
  Res : THorseResponse);

procedure CreateTodo(
  Req : THorseRequest;
  Res : THorseResponse);

procedure UpdateTodo(
  Req : THorseRequest;
  Res : THorseResponse);

procedure DeleteTodo(
  Req : THorseRequest;
  Res : THorseResponse);

implementation

uses
 
  todo_repository;

procedure GetTodos(
  Req : THorseRequest;
  Res : THorseResponse);
var
  Repo: TTodoRepository;
  Todos: TJSONArray;
begin
  Repo := TTodoRepository.Create;
  Todos := nil;

  try
    Todos := Repo.GetAll;

    Res
      .ContentType('application/json')
      .Send(Todos.AsJSON);
  finally
    Todos.Free;
    Repo.Free;
  end;
end;

procedure GetTodoById(
  Req : THorseRequest;
  Res : THorseResponse);
var
  Repo: TTodoRepository;
  TodoId: Integer;
  Todo: TJSONObject;
begin
  Repo := TTodoRepository.Create;
  Todo := nil;
  TodoId := StrToIntDef(Req.Params['id'], 0);
  try
    Todo := Repo.GetById(TodoId);

    Res
      .ContentType('application/json')
      .Send(Todo.AsJSON);
  finally
    Todo.Free;
    Repo.Free;
  end;
end;

procedure CreateTodo(
  Req : THorseRequest;
  Res : THorseResponse);
var
  Repo: TTodoRepository;
  Todo: TJSONObject;
  TodoId: Integer;
begin
  Repo := TTodoRepository.Create;
  Todo := TJSONObject(GetJSON(Req.Body));
  try
    TodoId := Repo.CreateTodo(Todo.Strings['title']);
    Todo.Add('id', TodoId);
    Res
      .Status(201)
      .ContentType('application/json')
      .Send(Todo.AsJSON);
  finally
    Todo.Free;
    Repo.Free;
  end;
end;

procedure UpdateTodo(
  Req : THorseRequest;
  Res : THorseResponse);
var
  Repo: TTodoRepository;
  TodoId: Integer;
  Todo: TJSONObject;
begin
  Repo := TTodoRepository.Create;
  Todo := TJSONObject(GetJSON(Req.Body));
  TodoId := StrToIntDef(Req.Params['id'], 0);
  try
    Repo.Update(TodoId, Todo.Strings['title'], Todo.Booleans['completed']);
    Res
      .ContentType('application/json')
      .Send(Todo.AsJSON);
  finally
    Todo.Free;
    Repo.Free;
  end;
end;

procedure DeleteTodo(
  Req : THorseRequest;
  Res : THorseResponse);
var
  Repo: TTodoRepository;
  TodoId: Integer;
begin
  Repo := TTodoRepository.Create;
  TodoId := StrToIntDef(Req.Params['id'], 0);
  try
    Repo.Delete(TodoId);
    Res.Status(204).Send('');
  finally
    Repo.Free;
  end;
end;

end.

unit project_controller;

{$mode objfpc}{$H+}

interface

uses
  Horse,
  SysUtils,
  fpjson;

procedure GetProjects(
  Req : THorseRequest;
  Res : THorseResponse);

procedure GetProjectById(
  Req : THorseRequest;
  Res : THorseResponse);

procedure CreateProject(
  Req : THorseRequest;
  Res : THorseResponse);

procedure UpdateProject(
  Req : THorseRequest;
  Res : THorseResponse);

procedure DeleteProject(
  Req : THorseRequest;
  Res : THorseResponse);

implementation

uses
  project_repository;

procedure GetProjects(
  Req : THorseRequest;
  Res : THorseResponse);
var
  Repo: TProjectRepository;
  Items: TJSONArray;
begin
  Repo := TProjectRepository.Create;
  Items := nil;
  try
    Items := Repo.GetAll;
    Res
      .ContentType('application/json')
      .Send(Items.AsJSON);
  finally
    Items.Free;
    Repo.Free;
  end;
end;

procedure GetProjectById(
  Req : THorseRequest;
  Res : THorseResponse);
var
  Repo: TProjectRepository;
  ItemId: Integer;
  Item: TJSONObject;
begin
  Repo := TProjectRepository.Create;
  Item := nil;
  ItemId := StrToIntDef(Req.Params['id'], 0);
  try
    Item := Repo.GetById(ItemId);
    Res
      .ContentType('application/json')
      .Send(Item.AsJSON);
  finally
    Item.Free;
    Repo.Free;
  end;
end;

procedure CreateProject(
  Req : THorseRequest;
  Res : THorseResponse);
var
  Repo: TProjectRepository;
  Item: TJSONObject;
  ItemId: Integer;
begin
  Repo := TProjectRepository.Create;
  Item := TJSONObject(GetJSON(Req.Body));
  try
    ItemId := Repo.CreateProject(Item.Strings['name']);
    Item.Add('id', ItemId);
    Res
      .Status(201)
      .ContentType('application/json')
      .Send(Item.AsJSON);
  finally
    Item.Free;
    Repo.Free;
  end;
end;

procedure UpdateProject(
  Req : THorseRequest;
  Res : THorseResponse);
var
  Repo: TProjectRepository;
  ItemId: Integer;
  Item: TJSONObject;
begin
  Repo := TProjectRepository.Create;
  Item := TJSONObject(GetJSON(Req.Body));
  ItemId := StrToIntDef(Req.Params['id'], 0);
  try
    Repo.Update(ItemId, Item.Strings['name']);
    Res
      .ContentType('application/json')
      .Send(Item.AsJSON);
  finally
    Item.Free;
    Repo.Free;
  end;
end;

procedure DeleteProject(
  Req : THorseRequest;
  Res : THorseResponse);
var
  Repo: TProjectRepository;
  ItemId: Integer;
begin
  Repo := TProjectRepository.Create;
  ItemId := StrToIntDef(Req.Params['id'], 0);
  try
    Repo.Delete(ItemId);
    Res.Status(204).Send('');
  finally
    Repo.Free;
  end;
end;

end.

unit project_repository;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  SQLDB,
  project_dto,
  repository;

type
  TProjectRepository = class(TRepositoryBase)
  private
    function MapProject(const Query: TSQLQuery): TProjectDTO;

  public

    function GetAll: TProjectDTOList;

    function GetById(
      const AId: Integer
    ): TProjectDTO;

    function CreateProject(
      const AName: String
    ): TProjectDTO;

    function Update(
      const AId: Integer;
      const AName: String
    ): TProjectDTO;

    procedure Delete(
      const AId: Integer
    );

  end;

implementation

uses
  SQLite3Conn;

function TProjectRepository.MapProject(const Query: TSQLQuery): TProjectDTO;
begin
  Result := TProjectDTO.Create(
    Query.FieldByName('id').AsInteger,
    Query.FieldByName('name').AsString,
    Query.FieldByName('created_at').AsString
  );
end;

function TProjectRepository.GetAll: TProjectDTOList;
var
  Conn: TSQLite3Connection;
  Query: TSQLQuery;
  Item: TProjectDTO;
begin
  Result := TProjectDTOList.Create(True);

  Query := CreateQuery(Conn);

  try
    Query.SQL.Text :=
      'select id,name,created_at ' +
      'from projects ' +
      'order by id';

    Query.Open;

    while not Query.EOF do
    begin
      Item := MapProject(Query);
      Result.Add(Item);
      Query.Next;
    end;

  finally
    Query.Free;
    Conn.Free;
  end;
end;

function TProjectRepository.GetById(
  const AId: Integer
): TProjectDTO;
var
  Conn: TSQLite3Connection;
  Query: TSQLQuery;
begin
  Result := nil;

  Query := CreateQuery(Conn);

  try
    Query.SQL.Text :=
      'select id,name,created_at ' +
      'from projects ' +
      'where id = :id';

    SetParamInt(Query, 'id', AId);

    Query.Open;

    if not Query.EOF then
      Result := MapProject(Query);

  finally
    Query.Free;
    Conn.Free;
  end;
end;

function TProjectRepository.CreateProject(
  const AName: String
): TProjectDTO;
var
  Conn: TSQLite3Connection;
  Query: TSQLQuery;
  CreatedId: Integer;
begin
  Result := nil;
  CreatedId := 0;

  Query := CreateQuery(Conn);

  try
    BeginTransaction(Conn);

    Query.SQL.Text :=
      'insert into projects (name) values (:name)';

    SetParamString(Query, 'name', AName);

    Query.ExecSQL;
    CommitTransaction(Conn);

    Query.SQL.Text :=
      'select last_insert_rowid() as id';
    Query.Open;
    CreatedId := Query.FieldByName('id').AsInteger;

    Result := GetById(CreatedId);

  finally
    if Conn.Transaction.Active then
      RollbackTransaction(Conn);

    Query.Free;
    Conn.Free;
  end;
end;

function TProjectRepository.Update(
  const AId: Integer;
  const AName: String
): TProjectDTO;
var
  Conn: TSQLite3Connection;
  Query: TSQLQuery;
begin
  Result := nil;
  Query := CreateQuery(Conn);

  try
    BeginTransaction(Conn);

    Query.SQL.Text :=
      'update projects set name = :name where id = :id';

    SetParamString(Query, 'name', AName);
    SetParamInt(Query, 'id', AId);

    Query.ExecSQL;
    CommitTransaction(Conn);

    Result := GetById(AId);

  finally
    if Conn.Transaction.Active then
      RollbackTransaction(Conn);

    Query.Free;
    Conn.Free;
  end;
end;

procedure TProjectRepository.Delete(
  const AId: Integer
);
var
  Conn: TSQLite3Connection;
  Query: TSQLQuery;
begin
  Query := CreateQuery(Conn);

  try
    BeginTransaction(Conn);
    Query.SQL.Text := 'delete from projects where id = :id';
    SetParamInt(Query, 'id', AId);
    Query.ExecSQL;
    CommitTransaction(Conn);

  finally
    if Conn.Transaction.Active then
      RollbackTransaction(Conn);

    Query.Free;
    Conn.Free;
  end;
end;

end.

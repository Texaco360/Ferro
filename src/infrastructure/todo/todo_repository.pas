unit todo_repository;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  SQLDB,
  todo_dto,
  repository;

type
  TTodoRepository = class(TRepositoryBase)
  private
    function MapTodo(const Query: TSQLQuery): TTodoDTO;

  public

    function GetAll: TTodoDTOList;

    function GetById(
      const AId: Integer
    ): TTodoDTO;

    function CreateTodo(
      const ATitle: String
    ): TTodoDTO;

    function Update(
      const AId: Integer;
      const ATitle: String;
      const ACompleted: Boolean
    ): TTodoDTO;

    procedure Delete(
      const AId: Integer
    );

  end;

implementation

uses
  SQLite3Conn;

function TTodoRepository.MapTodo(const Query: TSQLQuery): TTodoDTO;
begin
  Result := TTodoDTO.Create(
    Query.FieldByName('id').AsInteger,
    Query.FieldByName('title').AsString,
    Query.FieldByName('completed').AsInteger = 1
  );
end;

function TTodoRepository.GetAll: TTodoDTOList;
var
  Conn: TSQLite3Connection;
  Query: TSQLQuery;
  Item: TTodoDTO;
begin
  Result := TTodoDTOList.Create(True);

  Query := CreateQuery(Conn);

  try
    Query.SQL.Text :=
      'select id,title,completed ' +
      'from todos ' +
      'order by id';

    Query.Open;

    while not Query.EOF do
    begin
      Item := MapTodo(Query);
      Result.Add(Item);

      Query.Next;
    end;

  finally
    Query.Free;
    Conn.Free;
  end;
end;

function TTodoRepository.GetById(
  const AId: Integer
): TTodoDTO;
var
  Conn: TSQLite3Connection;
  Query: TSQLQuery;
begin
  Result := nil;

  Query := CreateQuery(Conn);

  try
    Query.SQL.Text :=
      'select id,title,completed ' +
      'from todos ' +
      'where id = :id';

    SetParamInt(Query, 'id', AId);

    Query.Open;

    if not Query.EOF then
      Result := MapTodo(Query);

  finally
    Query.Free;
    Conn.Free;
  end;
end;

function TTodoRepository.CreateTodo(
  const ATitle: String
): TTodoDTO;
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
      'insert into todos ' +
      '(title,completed) ' +
      'values (:title,0)';

    SetParamString(Query, 'title', ATitle);

    Query.ExecSQL;
    CommitTransaction(Conn);

    Query.SQL.Text :=
      'select last_insert_rowid() as id';

    Query.Open;

    CreatedId :=
      Query.FieldByName('id').AsInteger;

    Result := GetById(CreatedId);

  finally
    if Conn.Transaction.Active then
      RollbackTransaction(Conn);

    Query.Free;
    Conn.Free;
  end;
end;

function TTodoRepository.Update(
  const AId: Integer;
  const ATitle: String;
  const ACompleted: Boolean
): TTodoDTO;
var
  Conn: TSQLite3Connection;
  Query: TSQLQuery;
begin
  Result := nil;

  Query := CreateQuery(Conn);

  try
    BeginTransaction(Conn);

    Query.SQL.Text :=
      'update todos ' +
      'set title=:title,' +
      '    completed=:completed ' +
      'where id=:id';

    SetParamString(Query, 'title', ATitle);
    SetParamInt(Query, 'completed', Ord(ACompleted));
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

procedure TTodoRepository.Delete(
  const AId: Integer
);
var
  Conn: TSQLite3Connection;
  Query: TSQLQuery;
begin

  Query := CreateQuery(Conn);

  try
    BeginTransaction(Conn);

    Query.SQL.Text :=
      'delete from todos ' +
      'where id=:id';

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

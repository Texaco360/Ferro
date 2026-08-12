unit todo_repository;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  SQLDB,
  fpjson,
  repository;

type
  TTodoRepository = class(TRepositoryBase)
  private
    function MapTodo(const Query: TSQLQuery): TJSONObject;

  public

    function GetAll: TJSONArray;

    function GetById(
      const AId: Integer
    ): TJSONObject;

    function CreateTodo(
      const ATitle: String
    ): Integer;

    procedure Update(
      const AId: Integer;
      const ATitle: String;
      const ACompleted: Boolean
    );

    procedure Delete(
      const AId: Integer
    );

  end;

implementation

uses
  SQLite3Conn;

function TTodoRepository.MapTodo(const Query: TSQLQuery): TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.Add(
    'id',
    Query.FieldByName('id').AsInteger
  );

  Result.Add(
    'title',
    Query.FieldByName('title').AsString
  );

  Result.Add(
    'completed',
    Query.FieldByName('completed').AsInteger = 1
  );
end;

function TTodoRepository.GetAll: TJSONArray;
var
  Conn: TSQLite3Connection;
  Query: TSQLQuery;
  Item: TJSONObject;
begin
  Result := TJSONArray.Create;

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
): TJSONObject;
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
): Integer;
var
  Conn: TSQLite3Connection;
  Query: TSQLQuery;
begin
  Result := 0;

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

    Result :=
      Query.FieldByName('id').AsInteger;

  finally
    if Conn.Transaction.Active then
      RollbackTransaction(Conn);

    Query.Free;
    Conn.Free;
  end;
end;

procedure TTodoRepository.Update(
  const AId: Integer;
  const ATitle: String;
  const ACompleted: Boolean
);
var
  Conn: TSQLite3Connection;
  Query: TSQLQuery;
begin

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
unit todo_repository;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  fpjson;

type
  TTodoRepository = class
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
  SQLite3Conn,
  SQLDB,
  db_connection;

function TTodoRepository.GetAll: TJSONArray;
var
  Conn: TSQLite3Connection;
  Query: TSQLQuery;
  Item: TJSONObject;
begin
  Result := TJSONArray.Create;

  Conn := CreateConnection;
  Query := TSQLQuery.Create(nil);

  try

    Query.DataBase := Conn;
    Query.Transaction := Conn.Transaction;

    Query.SQL.Text :=
      'select id,title,completed ' +
      'from todos ' +
      'order by id';

    Query.Open;

    while not Query.EOF do
    begin

      Item := TJSONObject.Create;

      Item.Add(
        'id',
        Query.FieldByName('id').AsInteger
      );

      Item.Add(
        'title',
        Query.FieldByName('title').AsString
      );

      Item.Add(
        'completed',
        Query.FieldByName('completed').AsInteger = 1
      );

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

  Conn := CreateConnection;
  Query := TSQLQuery.Create(nil);

  try

    Query.DataBase := Conn;
    Query.Transaction := Conn.Transaction;

    Query.SQL.Text :=
      'select id,title,completed ' +
      'from todos ' +
      'where id = :id';

    Query.ParamByName('id').AsInteger :=
      AId;

    Query.Open;

    if not Query.EOF then
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

  Conn := CreateConnection;
  Query := TSQLQuery.Create(nil);

  try

    Query.DataBase := Conn;
    Query.Transaction := Conn.Transaction;

    Conn.Transaction.StartTransaction;

    Query.SQL.Text :=
      'insert into todos ' +
      '(title,completed) ' +
      'values (:title,0)';

    Query.ParamByName(
      'title'
    ).AsString := ATitle;

    Query.ExecSQL;

    Conn.Transaction.Commit;

    Query.SQL.Text :=
      'select last_insert_rowid() as id';

    Query.Open;

    Result :=
      Query.FieldByName('id').AsInteger;

  finally
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

  Conn := CreateConnection;
  Query := TSQLQuery.Create(nil);

  try

    Query.DataBase := Conn;
    Query.Transaction := Conn.Transaction;

    Conn.Transaction.StartTransaction;

    Query.SQL.Text :=
      'update todos ' +
      'set title=:title,' +
      '    completed=:completed ' +
      'where id=:id';

    Query.ParamByName('title').AsString :=
      ATitle;

    Query.ParamByName('completed').AsInteger :=
      Ord(ACompleted);

    Query.ParamByName('id').AsInteger :=
      AId;

    Query.ExecSQL;

    Conn.Transaction.Commit;

  finally
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

  Conn := CreateConnection;
  Query := TSQLQuery.Create(nil);

  try

    Query.DataBase := Conn;
    Query.Transaction := Conn.Transaction;

    Conn.Transaction.StartTransaction;

    Query.SQL.Text :=
      'delete from todos ' +
      'where id=:id';

    Query.ParamByName('id').AsInteger :=
      AId;

    Query.ExecSQL;

    Conn.Transaction.Commit;

  finally
    Query.Free;
    Conn.Free;
  end;
end;

end.
unit project_repository;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  fpjson;

type
  TProjectRepository = class
  public

    function GetAll: TJSONArray;

    function GetById(
      const AId: Integer
    ): TJSONObject;

    function CreateProject(
      const AName: String
    ): Integer;

    procedure Update(
      const AId: Integer;
      const AName: String
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

function TProjectRepository.GetAll: TJSONArray;
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
      'select id,name,created_at ' +
      'from projects ' +
      'order by id';

    Query.Open;

    while not Query.EOF do
    begin
      Item := TJSONObject.Create;
      Item.Add('id', Query.FieldByName('id').AsInteger);
      Item.Add('name', Query.FieldByName('name').AsString);
      Item.Add('created_at', Query.FieldByName('created_at').AsString);
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
      'select id,name,created_at ' +
      'from projects ' +
      'where id = :id';

    Query.ParamByName('id').AsInteger := AId;

    Query.Open;

    if not Query.EOF then
    begin
      Result := TJSONObject.Create;
      Result.Add('id', Query.FieldByName('id').AsInteger);
      Result.Add('name', Query.FieldByName('name').AsString);
      Result.Add('created_at', Query.FieldByName('created_at').AsString);
    end;

  finally
    Query.Free;
    Conn.Free;
  end;
end;

function TProjectRepository.CreateProject(
  const AName: String
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
      'insert into projects (name) values (:name)';

    Query.ParamByName('name').AsString := AName;

    Query.ExecSQL;
    Conn.Transaction.Commit;

    Query.SQL.Text :=
      'select last_insert_rowid() as id';
    Query.Open;
    Result := Query.FieldByName('id').AsInteger;

  finally
    Query.Free;
    Conn.Free;
  end;
end;

procedure TProjectRepository.Update(
  const AId: Integer;
  const AName: String
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
      'update projects set name = :name where id = :id';

    Query.ParamByName('name').AsString := AName;
    Query.ParamByName('id').AsInteger := AId;

    Query.ExecSQL;
    Conn.Transaction.Commit;

  finally
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
  Conn := CreateConnection;
  Query := TSQLQuery.Create(nil);

  try
    Query.DataBase := Conn;
    Query.Transaction := Conn.Transaction;

    Conn.Transaction.StartTransaction;
    Query.SQL.Text := 'delete from projects where id = :id';
    Query.ParamByName('id').AsInteger := AId;
    Query.ExecSQL;
    Conn.Transaction.Commit;

  finally
    Query.Free;
    Conn.Free;
  end;
end;

end.

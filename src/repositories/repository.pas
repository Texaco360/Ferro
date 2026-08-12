unit repository;

{$mode objfpc}{$H+}

interface

uses
  SQLite3Conn,
  SQLDB;

type
  TRepositoryBase = class
  protected
    function CreateQuery(out Conn: TSQLite3Connection): TSQLQuery;
    procedure BeginTransaction(const Conn: TSQLite3Connection);
    procedure CommitTransaction(const Conn: TSQLite3Connection);
    procedure RollbackTransaction(const Conn: TSQLite3Connection);
    procedure SetParamInt(
      const Query: TSQLQuery;
      const AName: String;
      const AValue: Integer
    );
    procedure SetParamString(
      const Query: TSQLQuery;
      const AName: String;
      const AValue: String
    );
  end;

implementation

uses
  db_connection;

function TRepositoryBase.CreateQuery(out Conn: TSQLite3Connection): TSQLQuery;
begin
  Conn := CreateConnection;

  Result := TSQLQuery.Create(nil);
  Result.DataBase := Conn;
  Result.Transaction := Conn.Transaction;
end;

procedure TRepositoryBase.BeginTransaction(const Conn: TSQLite3Connection);
begin
  if not Conn.Transaction.Active then
    Conn.Transaction.StartTransaction;
end;

procedure TRepositoryBase.CommitTransaction(const Conn: TSQLite3Connection);
begin
  if Conn.Transaction.Active then
    Conn.Transaction.Commit;
end;

procedure TRepositoryBase.RollbackTransaction(const Conn: TSQLite3Connection);
begin
  if Conn.Transaction.Active then
    Conn.Transaction.Rollback;
end;

procedure TRepositoryBase.SetParamInt(
  const Query: TSQLQuery;
  const AName: String;
  const AValue: Integer
);
begin
  Query.ParamByName(AName).AsInteger := AValue;
end;

procedure TRepositoryBase.SetParamString(
  const Query: TSQLQuery;
  const AName: String;
  const AValue: String
);
begin
  Query.ParamByName(AName).AsString := AValue;
end;

end.

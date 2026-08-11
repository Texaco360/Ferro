unit migrations;

{$mode objfpc}{$H+}

interface

procedure RunMigrations;
procedure MigrationStatus;
procedure FreshMigrations;

implementation

uses
  SysUtils,
  Classes,
  SQLite3Conn,
  SQLDB,
  db_connection;

type
  TMigration = record
    Version: String;
    SQL: String;
  end;

var
  FMigrations: array of TMigration;
  FMigrationCount: Integer;
  FRegistered: Boolean;

procedure AddMigration(const AVersion: String; const ASQL: String);
begin
  SetLength(FMigrations, FMigrationCount + 1);
  FMigrations[FMigrationCount].Version := AVersion;
  FMigrations[FMigrationCount].SQL := ASQL;
  Inc(FMigrationCount);
end;

procedure RegisterMigrations;
begin
  if FRegistered then
    Exit;

  FRegistered := True;

  AddMigration(
    '20260811_001_create_todos',
    'CREATE TABLE IF NOT EXISTS todos (' +
    'id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    'title TEXT NOT NULL,' +
    'completed INTEGER NOT NULL DEFAULT 0,' +
    'created_at DATETIME DEFAULT CURRENT_TIMESTAMP' +
    ')'
  );
  AddMigration(
    '20260811_create_projects',
    'CREATE TABLE IF NOT EXISTS projects (' +
    'id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    'name TEXT NOT NULL,' +
    'created_at DATETIME DEFAULT CURRENT_TIMESTAMP' +
    ')'
  );
  // $MIGRATIONS_END
end;

procedure EnsureMigrationsTable(Conn: TSQLite3Connection);
var
  Query: TSQLQuery;
begin
  Query := TSQLQuery.Create(nil);
  try
    Query.DataBase := Conn;
    Query.Transaction := Conn.Transaction;
    Conn.Transaction.StartTransaction;
    Query.SQL.Text :=
      'CREATE TABLE IF NOT EXISTS schema_migrations (' +
      'version TEXT PRIMARY KEY,' +
      'applied_at DATETIME DEFAULT CURRENT_TIMESTAMP' +
      ')';
    Query.ExecSQL;
    Conn.Transaction.Commit;
  finally
    Query.Free;
  end;
end;

function IsMigrationApplied(Conn: TSQLite3Connection; const AVersion: String): Boolean;
var
  Query: TSQLQuery;
begin
  Query := TSQLQuery.Create(nil);
  try
    Query.DataBase := Conn;
    Query.Transaction := Conn.Transaction;
    Conn.Transaction.StartTransaction;
    Query.SQL.Text :=
      'SELECT COUNT(*) AS cnt FROM schema_migrations WHERE version = :version';
    Query.ParamByName('version').AsString := AVersion;
    Query.Open;
    Result := Query.FieldByName('cnt').AsInteger > 0;
    Query.Close;
    Conn.Transaction.Commit;
  finally
    Query.Free;
  end;
end;

procedure ApplyMigration(Conn: TSQLite3Connection; const AMigration: TMigration);
var
  Query: TSQLQuery;
begin
  Query := TSQLQuery.Create(nil);
  try
    Query.DataBase := Conn;
    Query.Transaction := Conn.Transaction;
    Conn.Transaction.StartTransaction;

    Query.SQL.Text := AMigration.SQL;
    Query.ExecSQL;

    Query.SQL.Text :=
      'INSERT INTO schema_migrations (version) VALUES (:version)';
    Query.ParamByName('version').AsString := AMigration.Version;
    Query.ExecSQL;

    Conn.Transaction.Commit;
    Writeln('  Applied: ' + AMigration.Version);
  finally
    Query.Free;
  end;
end;

procedure RunMigrations;
var
  Conn: TSQLite3Connection;
  I: Integer;
  Applied: Integer;
begin
  RegisterMigrations;

  Conn := CreateConnection;
  try
    EnsureMigrationsTable(Conn);

    Applied := 0;
    for I := 0 to FMigrationCount - 1 do
    begin
      if not IsMigrationApplied(Conn, FMigrations[I].Version) then
      begin
        ApplyMigration(Conn, FMigrations[I]);
        Inc(Applied);
      end;
    end;

    if Applied = 0 then
      Writeln('Nothing to migrate.')
    else
      Writeln(Format('%d migration(s) applied.', [Applied]));
  finally
    Conn.Free;
  end;
end;

procedure MigrationStatus;
var
  Conn: TSQLite3Connection;
  I: Integer;
  StatusStr: String;
begin
  RegisterMigrations;

  Conn := CreateConnection;
  try
    EnsureMigrationsTable(Conn);

    Writeln(Format('%-45s  %s', ['Version', 'Status']));
    Writeln(StringOfChar('-', 55));

    for I := 0 to FMigrationCount - 1 do
    begin
      if IsMigrationApplied(Conn, FMigrations[I].Version) then
        StatusStr := 'applied'
      else
        StatusStr := 'pending';

      Writeln(Format('%-45s  %s', [FMigrations[I].Version, StatusStr]));
    end;
  finally
    Conn.Free;
  end;
end;

procedure FreshMigrations;
var
  Conn: TSQLite3Connection;
  Query: TSQLQuery;
  TableNames: TStringList;
  I: Integer;
begin
  RegisterMigrations;

  Conn := CreateConnection;
  TableNames := TStringList.Create;
  try
    Query := TSQLQuery.Create(nil);
    try
      Query.DataBase := Conn;
      Query.Transaction := Conn.Transaction;
      Conn.Transaction.StartTransaction;
      Query.SQL.Text :=
        'SELECT name FROM sqlite_master WHERE type=''table'' ' +
        'AND name NOT IN (''sqlite_sequence'')';
      Query.Open;
      while not Query.EOF do
      begin
        TableNames.Add(Query.FieldByName('name').AsString);
        Query.Next;
      end;
      Query.Close;
      Conn.Transaction.Commit;
    finally
      Query.Free;
    end;

    for I := 0 to TableNames.Count - 1 do
    begin
      Query := TSQLQuery.Create(nil);
      try
        Query.DataBase := Conn;
        Query.Transaction := Conn.Transaction;
        Conn.Transaction.StartTransaction;
        Query.SQL.Text := 'DROP TABLE IF EXISTS "' + TableNames[I] + '"';
        Query.ExecSQL;
        Conn.Transaction.Commit;
        Writeln('  Dropped: ' + TableNames[I]);
      finally
        Query.Free;
      end;
    end;
  finally
    TableNames.Free;
    Conn.Free;
  end;

  FRegistered := False;
  FMigrationCount := 0;
  SetLength(FMigrations, 0);

  Writeln('Running all migrations fresh...');
  RunMigrations;
end;

initialization
  FRegistered := False;
  FMigrationCount := 0;
  SetLength(FMigrations, 0);

end.

unit db_connection;

{$mode objfpc}
{$H+}

interface

uses
  SysUtils,
  SQLite3Conn,
  SQLDB;

function CreateConnection: TSQLite3Connection;

implementation

function ResolveDatabasePath: String;
var
  EnvDbPath: String;
  ExeDir: String;
  Candidates: array[0..3] of String;
  I: Integer;
begin
  EnvDbPath := Trim(GetEnvironmentVariable('DB_PATH'));
  if EnvDbPath <> '' then
  begin
    Result := ExpandFileName(EnvDbPath);
    Exit;
  end;

  ExeDir := ExtractFilePath(ParamStr(0));

  Candidates[0] := ExpandFileName('src/database/todo.db');
  Candidates[1] := ExpandFileName('database/todo.db');
  Candidates[2] := ExpandFileName(IncludeTrailingPathDelimiter(ExeDir) + '../../src/database/todo.db');
  Candidates[3] := ExpandFileName(IncludeTrailingPathDelimiter(ExeDir) + '../src/database/todo.db');

  for I := Low(Candidates) to High(Candidates) do
  begin
    if FileExists(Candidates[I]) then
    begin
      Result := Candidates[I];
      Exit;
    end;
  end;

  Result := Candidates[0];
end;

function CreateConnection: TSQLite3Connection;
var
  Tran : TSQLTransaction;
begin
  Result := TSQLite3Connection.Create(nil);

  Tran := TSQLTransaction.Create(Result);

  Result.Transaction := Tran;

  Result.DatabaseName :=
    ResolveDatabasePath;

  Result.Open;
end;

end.
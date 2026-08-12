program generate;

{$MODE DELPHI}
{$H+}

uses
  SysUtils,
  Classes;

var
  ModelPascal: String;
  ModelLower: String;
  ModelPlural: String;
  RootDir: String;

function SrcFile(const ARelPath: String): String;
begin
  Result := RootDir + PathDelim +
    StringReplace(ARelPath, '/', PathDelim, [rfReplaceAll]);
end;

procedure WriteFileContent(const APath, AContent: String);
var
  F: TextFile;
begin
  AssignFile(F, APath);
  Rewrite(F);
  try
    Write(F, AContent);
  finally
    CloseFile(F);
  end;
end;

function ReadFileContent(const APath: String): String;
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.LoadFromFile(APath);
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

procedure ValidateAndInit;
begin
  ModelPascal := ParamStr(1);
  ModelLower := LowerCase(ModelPascal);
  ModelPlural := ModelLower + 's';

  if Length(ModelPascal) = 0 then
  begin
    Writeln('ERROR: Model name cannot be empty.');
    Halt(1);
  end;

  if not (ModelPascal[1] in ['A'..'Z']) then
  begin
    Writeln('ERROR: Model name must start with an uppercase letter (PascalCase).');
    Writeln('  Example: ' + UpperCase(Copy(ModelPascal, 1, 1)) + Copy(ModelPascal, 2, MaxInt));
    Halt(1);
  end;

  RootDir := ExcludeTrailingPathDelimiter(
    ExpandFileName(ExtractFilePath(ParamStr(0)) + '../..')
  );
end;

procedure CheckGuard;
var
  DtoPath, RepoPath, CtrlPath: String;
  AnyExists: Boolean;
begin
  DtoPath  := SrcFile('src/dto/'          + ModelLower + '_dto.pas');
  RepoPath := SrcFile('src/repositories/' + ModelLower + '_repository.pas');
  CtrlPath := SrcFile('src/controllers/'  + ModelLower + '_controller.pas');

  AnyExists := FileExists(DtoPath) or FileExists(RepoPath) or FileExists(CtrlPath);

  if AnyExists then
  begin
    Writeln('ERROR: Model "' + ModelPascal + '" already exists. Aborting.');
    if FileExists(DtoPath)  then Writeln('  Exists: src/dto/'          + ModelLower + '_dto.pas');
    if FileExists(RepoPath) then Writeln('  Exists: src/repositories/' + ModelLower + '_repository.pas');
    if FileExists(CtrlPath) then Writeln('  Exists: src/controllers/'  + ModelLower + '_controller.pas');
    Halt(1);
  end;
end;

function BuildDtoContent: String;
var
  L: TStringList;
begin
  L := TStringList.Create;
  try
    L.Add('unit ' + ModelLower + '_dto;');
    L.Add('');
    L.Add('interface');
    L.Add('');
    L.Add('type');
    L.Add('  T' + ModelPascal + 'DTO = record');
    L.Add('    Id: Integer;');
    L.Add('    Name: String;');
    L.Add('    CreatedAt: String;');
    L.Add('  end;');
    L.Add('');
    L.Add('implementation');
    L.Add('');
    L.Add('end.');
    Result := L.Text;
  finally
    L.Free;
  end;
end;

function BuildRepositoryContent: String;
var
  L: TStringList;
  MP, ML, MPl: String;
begin
  MP  := ModelPascal;
  ML  := ModelLower;
  MPl := ModelPlural;

  L := TStringList.Create;
  try
    L.Add('unit ' + ML + '_repository;');
    L.Add('');
    L.Add('{$mode objfpc}{$H+}');
    L.Add('');
    L.Add('interface');
    L.Add('');
    L.Add('uses');
    L.Add('  Classes,');
    L.Add('  SysUtils,');
    L.Add('  fpjson;');
    L.Add('');
    L.Add('type');
    L.Add('  T' + MP + 'Repository = class');
    L.Add('  public');
    L.Add('');
    L.Add('    function GetAll: TJSONArray;');
    L.Add('');
    L.Add('    function GetById(');
    L.Add('      const AId: Integer');
    L.Add('    ): TJSONObject;');
    L.Add('');
    L.Add('    function Create' + MP + '(');
    L.Add('      const AName: String');
    L.Add('    ): Integer;');
    L.Add('');
    L.Add('    procedure Update(');
    L.Add('      const AId: Integer;');
    L.Add('      const AName: String');
    L.Add('    );');
    L.Add('');
    L.Add('    procedure Delete(');
    L.Add('      const AId: Integer');
    L.Add('    );');
    L.Add('');
    L.Add('  end;');
    L.Add('');
    L.Add('implementation');
    L.Add('');
    L.Add('uses');
    L.Add('  SQLite3Conn,');
    L.Add('  SQLDB,');
    L.Add('  db_connection;');
    L.Add('');
    L.Add('function T' + MP + 'Repository.GetAll: TJSONArray;');
    L.Add('var');
    L.Add('  Conn: TSQLite3Connection;');
    L.Add('  Query: TSQLQuery;');
    L.Add('  Item: TJSONObject;');
    L.Add('begin');
    L.Add('  Result := TJSONArray.Create;');
    L.Add('');
    L.Add('  Conn := CreateConnection;');
    L.Add('  Query := TSQLQuery.Create(nil);');
    L.Add('');
    L.Add('  try');
    L.Add('    Query.DataBase := Conn;');
    L.Add('    Query.Transaction := Conn.Transaction;');
    L.Add('');
    L.Add('    Query.SQL.Text :=');
    L.Add('      ''select id,name,created_at '' +');
    L.Add('      ''from ' + MPl + ' '' +');
    L.Add('      ''order by id'';');
    L.Add('');
    L.Add('    Query.Open;');
    L.Add('');
    L.Add('    while not Query.EOF do');
    L.Add('    begin');
    L.Add('      Item := TJSONObject.Create;');
    L.Add('      Item.Add(''id'', Query.FieldByName(''id'').AsInteger);');
    L.Add('      Item.Add(''name'', Query.FieldByName(''name'').AsString);');
    L.Add('      Item.Add(''created_at'', Query.FieldByName(''created_at'').AsString);');
    L.Add('      Result.Add(Item);');
    L.Add('      Query.Next;');
    L.Add('    end;');
    L.Add('');
    L.Add('  finally');
    L.Add('    Query.Free;');
    L.Add('    Conn.Free;');
    L.Add('  end;');
    L.Add('end;');
    L.Add('');
    L.Add('function T' + MP + 'Repository.GetById(');
    L.Add('  const AId: Integer');
    L.Add('): TJSONObject;');
    L.Add('var');
    L.Add('  Conn: TSQLite3Connection;');
    L.Add('  Query: TSQLQuery;');
    L.Add('begin');
    L.Add('  Result := nil;');
    L.Add('');
    L.Add('  Conn := CreateConnection;');
    L.Add('  Query := TSQLQuery.Create(nil);');
    L.Add('');
    L.Add('  try');
    L.Add('    Query.DataBase := Conn;');
    L.Add('    Query.Transaction := Conn.Transaction;');
    L.Add('');
    L.Add('    Query.SQL.Text :=');
    L.Add('      ''select id,name,created_at '' +');
    L.Add('      ''from ' + MPl + ' '' +');
    L.Add('      ''where id = :id'';');
    L.Add('');
    L.Add('    Query.ParamByName(''id'').AsInteger := AId;');
    L.Add('');
    L.Add('    Query.Open;');
    L.Add('');
    L.Add('    if not Query.EOF then');
    L.Add('    begin');
    L.Add('      Result := TJSONObject.Create;');
    L.Add('      Result.Add(''id'', Query.FieldByName(''id'').AsInteger);');
    L.Add('      Result.Add(''name'', Query.FieldByName(''name'').AsString);');
    L.Add('      Result.Add(''created_at'', Query.FieldByName(''created_at'').AsString);');
    L.Add('    end;');
    L.Add('');
    L.Add('  finally');
    L.Add('    Query.Free;');
    L.Add('    Conn.Free;');
    L.Add('  end;');
    L.Add('end;');
    L.Add('');
    L.Add('function T' + MP + 'Repository.Create' + MP + '(');
    L.Add('  const AName: String');
    L.Add('): Integer;');
    L.Add('var');
    L.Add('  Conn: TSQLite3Connection;');
    L.Add('  Query: TSQLQuery;');
    L.Add('begin');
    L.Add('  Result := 0;');
    L.Add('');
    L.Add('  Conn := CreateConnection;');
    L.Add('  Query := TSQLQuery.Create(nil);');
    L.Add('');
    L.Add('  try');
    L.Add('    Query.DataBase := Conn;');
    L.Add('    Query.Transaction := Conn.Transaction;');
    L.Add('');
    L.Add('    Conn.Transaction.StartTransaction;');
    L.Add('');
    L.Add('    Query.SQL.Text :=');
    L.Add('      ''insert into ' + MPl + ' (name) values (:name)'';');
    L.Add('');
    L.Add('    Query.ParamByName(''name'').AsString := AName;');
    L.Add('');
    L.Add('    Query.ExecSQL;');
    L.Add('    Conn.Transaction.Commit;');
    L.Add('');
    L.Add('    Query.SQL.Text :=');
    L.Add('      ''select last_insert_rowid() as id'';');
    L.Add('    Query.Open;');
    L.Add('    Result := Query.FieldByName(''id'').AsInteger;');
    L.Add('');
    L.Add('  finally');
    L.Add('    Query.Free;');
    L.Add('    Conn.Free;');
    L.Add('  end;');
    L.Add('end;');
    L.Add('');
    L.Add('procedure T' + MP + 'Repository.Update(');
    L.Add('  const AId: Integer;');
    L.Add('  const AName: String');
    L.Add(');');
    L.Add('var');
    L.Add('  Conn: TSQLite3Connection;');
    L.Add('  Query: TSQLQuery;');
    L.Add('begin');
    L.Add('  Conn := CreateConnection;');
    L.Add('  Query := TSQLQuery.Create(nil);');
    L.Add('');
    L.Add('  try');
    L.Add('    Query.DataBase := Conn;');
    L.Add('    Query.Transaction := Conn.Transaction;');
    L.Add('');
    L.Add('    Conn.Transaction.StartTransaction;');
    L.Add('');
    L.Add('    Query.SQL.Text :=');
    L.Add('      ''update ' + MPl + ' set name = :name where id = :id'';');
    L.Add('');
    L.Add('    Query.ParamByName(''name'').AsString := AName;');
    L.Add('    Query.ParamByName(''id'').AsInteger := AId;');
    L.Add('');
    L.Add('    Query.ExecSQL;');
    L.Add('    Conn.Transaction.Commit;');
    L.Add('');
    L.Add('  finally');
    L.Add('    Query.Free;');
    L.Add('    Conn.Free;');
    L.Add('  end;');
    L.Add('end;');
    L.Add('');
    L.Add('procedure T' + MP + 'Repository.Delete(');
    L.Add('  const AId: Integer');
    L.Add(');');
    L.Add('var');
    L.Add('  Conn: TSQLite3Connection;');
    L.Add('  Query: TSQLQuery;');
    L.Add('begin');
    L.Add('  Conn := CreateConnection;');
    L.Add('  Query := TSQLQuery.Create(nil);');
    L.Add('');
    L.Add('  try');
    L.Add('    Query.DataBase := Conn;');
    L.Add('    Query.Transaction := Conn.Transaction;');
    L.Add('');
    L.Add('    Conn.Transaction.StartTransaction;');
    L.Add('    Query.SQL.Text := ''delete from ' + MPl + ' where id = :id'';');
    L.Add('    Query.ParamByName(''id'').AsInteger := AId;');
    L.Add('    Query.ExecSQL;');
    L.Add('    Conn.Transaction.Commit;');
    L.Add('');
    L.Add('  finally');
    L.Add('    Query.Free;');
    L.Add('    Conn.Free;');
    L.Add('  end;');
    L.Add('end;');
    L.Add('');
    L.Add('end.');
    Result := L.Text;
  finally
    L.Free;
  end;
end;

function BuildControllerContent: String;
var
  L: TStringList;
  MP, ML: String;
begin
  MP  := ModelPascal;
  ML  := ModelLower;

  L := TStringList.Create;
  try
    L.Add('unit ' + ML + '_controller;');
    L.Add('');
    L.Add('{$mode objfpc}{$H+}');
    L.Add('');
    L.Add('interface');
    L.Add('');
    L.Add('uses');
    L.Add('  Horse,');
    L.Add('  SysUtils,');
    L.Add('  fpjson,');
    L.Add('  controller,');
    L.Add('  ' + ML + '_repository;');
    L.Add('');
    L.Add('type');
    L.Add('  T' + MP + 'Controller = class(TBaseController)');
    L.Add('  private');
    L.Add('    class var FRepository: T' + MP + 'Repository;');
    L.Add('    class function Repository: T' + MP + 'Repository; static;');
    L.Add('');
    L.Add('  public');
    L.Add('    class destructor Destroy;');
    L.Add('');
    L.Add('    class procedure GetAll(');
    L.Add('      Req : THorseRequest;');
    L.Add('      Res : THorseResponse); static;');
    L.Add('');
    L.Add('    class procedure GetById(');
    L.Add('      Req : THorseRequest;');
    L.Add('      Res : THorseResponse); static;');
    L.Add('');
    L.Add('    class procedure Create(');
    L.Add('      Req : THorseRequest;');
    L.Add('      Res : THorseResponse); static;');
    L.Add('');
    L.Add('    class procedure Update(');
    L.Add('      Req : THorseRequest;');
    L.Add('      Res : THorseResponse); static;');
    L.Add('');
    L.Add('    class procedure Delete(');
    L.Add('      Req : THorseRequest;');
    L.Add('      Res : THorseResponse); static;');
    L.Add('  end;');
    L.Add('');
    L.Add('implementation');
    L.Add('');
    L.Add('class function T' + MP + 'Controller.Repository: T' + MP + 'Repository;');
    L.Add('begin');
    L.Add('  if FRepository = nil then');
    L.Add('    FRepository := T' + MP + 'Repository.Create;');
    L.Add('');
    L.Add('  Result := FRepository;');
    L.Add('end;');
    L.Add('');
    L.Add('class destructor T' + MP + 'Controller.Destroy;');
    L.Add('begin');
    L.Add('  FreeAndNil(FRepository);');
    L.Add('end;');
    L.Add('');
    L.Add('class procedure T' + MP + 'Controller.GetAll(');
    L.Add('  Req : THorseRequest;');
    L.Add('  Res : THorseResponse);');
    L.Add('var');
    L.Add('  Items: TJSONArray;');
    L.Add('begin');
    L.Add('  Items := nil;');
    L.Add('  try');
    L.Add('    Items := Repository.GetAll;');
    L.Add('    SendJSON(Res, Items);');
    L.Add('  finally');
    L.Add('    Items.Free;');
    L.Add('  end;');
    L.Add('end;');
    L.Add('');
    L.Add('class procedure T' + MP + 'Controller.GetById(');
    L.Add('  Req : THorseRequest;');
    L.Add('  Res : THorseResponse);');
    L.Add('var');
    L.Add('  ItemId: Integer;');
    L.Add('  Item: TJSONObject;');
    L.Add('begin');
    L.Add('  Item := nil;');
    L.Add('  ItemId := ParamAsInt(Req, ''id'');');
    L.Add('  try');
    L.Add('    Item := Repository.GetById(ItemId);');
    L.Add('    SendJSON(Res, Item);');
    L.Add('  finally');
    L.Add('    Item.Free;');
    L.Add('  end;');
    L.Add('end;');
    L.Add('');
    L.Add('class procedure T' + MP + 'Controller.Create(');
    L.Add('  Req : THorseRequest;');
    L.Add('  Res : THorseResponse);');
    L.Add('var');
    L.Add('  Item: TJSONObject;');
    L.Add('  ItemId: Integer;');
    L.Add('begin');
    L.Add('  Item := TJSONObject(GetJSON(Req.Body));');
    L.Add('  try');
    L.Add('    ItemId := Repository.Create' + MP + '(Item.Strings[''name'']);');
    L.Add('    Item.Add(''id'', ItemId);');
    L.Add('    SendJSON(Res, Item, 201);');
    L.Add('  finally');
    L.Add('    Item.Free;');
    L.Add('  end;');
    L.Add('end;');
    L.Add('');
    L.Add('class procedure T' + MP + 'Controller.Update(');
    L.Add('  Req : THorseRequest;');
    L.Add('  Res : THorseResponse);');
    L.Add('var');
    L.Add('  ItemId: Integer;');
    L.Add('  Item: TJSONObject;');
    L.Add('begin');
    L.Add('  Item := TJSONObject(GetJSON(Req.Body));');
    L.Add('  ItemId := ParamAsInt(Req, ''id'');');
    L.Add('  try');
    L.Add('    Repository.Update(ItemId, Item.Strings[''name'']);');
    L.Add('    SendJSON(Res, Item);');
    L.Add('  finally');
    L.Add('    Item.Free;');
    L.Add('  end;');
    L.Add('end;');
    L.Add('');
    L.Add('class procedure T' + MP + 'Controller.Delete(');
    L.Add('  Req : THorseRequest;');
    L.Add('  Res : THorseResponse);');
    L.Add('var');
    L.Add('  ItemId: Integer;');
    L.Add('begin');
    L.Add('  ItemId := ParamAsInt(Req, ''id'');');
    L.Add('  Repository.Delete(ItemId);');
    L.Add('  SendNoContent(Res);');
    L.Add('end;');
    L.Add('');
    L.Add('end.');
    Result := L.Text;
  finally
    L.Free;
  end;
end;

procedure PatchMigrations;
var
  MigrationsPath: String;
  Content: String;
  Date: String;
  NewEntry: String;
  Sentinel: String;
  SentinelPos: Integer;
  F: TextFile;
begin
  MigrationsPath := SrcFile('src/database/migrations.pas');
  Sentinel := '  // $MIGRATIONS_END';
  Date := FormatDateTime('YYYYMMDD', Now);

  Content := ReadFileContent(MigrationsPath);

  SentinelPos := Pos(Sentinel, Content);
  if SentinelPos = 0 then
  begin
    Writeln('ERROR: sentinel not found in migrations.pas. Expected: ' + Sentinel);
    Halt(1);
  end;

  NewEntry :=
    '  AddMigration(' + LineEnding +
    '    ''' + Date + '_create_' + ModelPlural + ''',' + LineEnding +
    '    ''CREATE TABLE IF NOT EXISTS ' + ModelPlural + ' ('' +' + LineEnding +
    '    ''id INTEGER PRIMARY KEY AUTOINCREMENT,'' +' + LineEnding +
    '    ''name TEXT NOT NULL,'' +' + LineEnding +
    '    ''created_at DATETIME DEFAULT CURRENT_TIMESTAMP'' +' + LineEnding +
    '    '')''' + LineEnding +
    '  );' + LineEnding;

  Content :=
    Copy(Content, 1, SentinelPos - 1) +
    NewEntry +
    Copy(Content, SentinelPos, Length(Content));

  AssignFile(F, MigrationsPath);
  Rewrite(F);
  try
    Write(F, Content);
  finally
    CloseFile(F);
  end;

  Writeln('  Patched: src/database/migrations.pas');
end;

procedure PatchBootstrap;
var
  BootstrapPath: String;
  Content: String;
  NewRoutes: String;
  LB: String;
  F: TextFile;
begin
  LB := LineEnding;
  BootstrapPath := SrcFile('src/bootstrap/server_bootstrap.pas');

  Content := ReadFileContent(BootstrapPath);

  if Pos('; // $USES_END', Content) = 0 then
  begin
    Writeln('ERROR: uses sentinel not found in server_bootstrap.pas. Expected: ; // $USES_END');
    Halt(1);
  end;

  Content := StringReplace(
    Content,
    '; // $USES_END',
    ',' + LB + '  ' + ModelLower + '_controller; // $USES_END',
    []
  );

  if Pos('  // $ROUTES_END', Content) = 0 then
  begin
    Writeln('ERROR: routes sentinel not found in server_bootstrap.pas. Expected:   // $ROUTES_END');
    Halt(1);
  end;

  NewRoutes :=
    '  THorse.Get(''/api/' + ModelPlural + ''', T' + ModelPascal + 'Controller.GetAll);' + LB +
    '  THorse.Get(''/api/' + ModelPlural + '/:id'', T' + ModelPascal + 'Controller.GetById);' + LB +
    '  THorse.Post(''/api/' + ModelPlural + ''', T' + ModelPascal + 'Controller.Create);' + LB +
    '  THorse.Put(''/api/' + ModelPlural + '/:id'', T' + ModelPascal + 'Controller.Update);' + LB +
    '  THorse.Delete(''/api/' + ModelPlural + '/:id'', T' + ModelPascal + 'Controller.Delete);' + LB +
    '  // $ROUTES_END';

  Content := StringReplace(
    Content,
    '  // $ROUTES_END',
    NewRoutes,
    []
  );

  AssignFile(F, BootstrapPath);
  Rewrite(F);
  try
    Write(F, Content);
  finally
    CloseFile(F);
  end;

  Writeln('  Patched: src/bootstrap/server_bootstrap.pas');
end;

begin
  if ParamCount < 1 then
  begin
    Writeln('Usage: generate <ModelName>');
    Writeln('');
    Writeln('  ModelName must be PascalCase, e.g.: generate Project');
    Halt(1);
  end;

  ValidateAndInit;
  CheckGuard;

  WriteFileContent(
    SrcFile('src/dto/' + ModelLower + '_dto.pas'),
    BuildDtoContent
  );
  Writeln('  Created: src/dto/' + ModelLower + '_dto.pas');

  WriteFileContent(
    SrcFile('src/repositories/' + ModelLower + '_repository.pas'),
    BuildRepositoryContent
  );
  Writeln('  Created: src/repositories/' + ModelLower + '_repository.pas');

  WriteFileContent(
    SrcFile('src/controllers/' + ModelLower + '_controller.pas'),
    BuildControllerContent
  );
  Writeln('  Created: src/controllers/' + ModelLower + '_controller.pas');

  PatchMigrations;
  PatchBootstrap;

  Writeln('');
  Writeln('Generated model "' + ModelPascal + '" successfully.');
  Writeln('Run ./scripts/build.sh to compile.');
end.

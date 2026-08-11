unit todo_controller_tests;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  fpcunit,
  testregistry,
  process,
  fphttpclient,
  fpjson,
  jsonparser,
  SQLite3Conn,
  SQLDB,
  todo_repository;

type
  TTestHTTPClient = class(TFPHTTPClient)
  public
    procedure SetRequestBodyStream(AStream: TStream);
  end;

  TTestTodoController = class(TTestCase)
  private
    FDatabasePath: string;
    FPort: Word;
    FServerProcess: TProcess;
    function ResolveDatabasePath: string;
    procedure EnsureFreshDatabase;
    procedure ExecuteSchema;
    function IsPortAvailable(const APort: Word): Boolean;
    function FindAvailablePort(const AStartPort, AMaxAttempts: Integer): Word;
    function BaseUrl: string;
    procedure StartServer;
    procedure StopServer;
    procedure WaitForServerReady;
    function GetJsonObject(const AContent: string): TJSONObject;
    function GetJsonArray(const AContent: string): TJSONArray;
    function HttpGet(const APath: string): string;
    function HttpPostJson(const APath, AJson: string): string;
    function HttpPutJson(const APath, AJson: string): string;
    function HttpDelete(const APath: string): string;
    function CreateTodoJson(const ATitle: string; const ACompleted: Boolean = False): string;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure GetTodosReturnsAnEmptyArray;
    procedure CreateTodoReturnsCreatedTodoWithId;
    procedure GetTodoByIdReturnsTheStoredTodo;
    procedure UpdateTodoReturnsTheUpdatedTodo;
    procedure DeleteTodoReturnsNoContent;
  end;

implementation

uses
  BaseUnix,
  Sockets;

function setenv(name: PAnsiChar; value: PAnsiChar; overwrite: LongInt): LongInt; cdecl; external 'c' name 'setenv';

procedure TTestHTTPClient.SetRequestBodyStream(AStream: TStream);
begin
  RequestBody := AStream;
end;

function TTestTodoController.ResolveDatabasePath: string;
begin
  Result := Trim(GetEnvironmentVariable('DB_PATH'));
  if Result <> '' then
    Exit;

  Result := ExpandFileName(
    IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
    '../ferroserver-tests.sqlite'
  );
end;

procedure TTestTodoController.EnsureFreshDatabase;
begin
  if FDatabasePath = '' then
    FDatabasePath := ResolveDatabasePath;

  setenv(
    PAnsiChar(AnsiString('DB_PATH')),
    PAnsiChar(AnsiString(FDatabasePath)),
    1
  );

  if FileExists(FDatabasePath) then
    DeleteFile(FDatabasePath);

  ExecuteSchema;
end;

procedure TTestTodoController.ExecuteSchema;
var
  Connection: TSQLite3Connection;
  Query: TSQLQuery;
  SchemaFile: TStringList;
  Transaction: TSQLTransaction;
  SchemaPath: string;
begin
  Connection := TSQLite3Connection.Create(nil);
  Transaction := TSQLTransaction.Create(Connection);
  Query := TSQLQuery.Create(nil);
  SchemaFile := TStringList.Create;
  try
    Connection.Transaction := Transaction;
    Connection.DatabaseName := FDatabasePath;
    Connection.Open;

    SchemaPath := ExpandFileName(
      IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
      '../../../src/database/schema.sql'
    );
    SchemaFile.LoadFromFile(SchemaPath);

    Query.DataBase := Connection;
    Query.Transaction := Transaction;
    Query.SQL.Text := SchemaFile.Text;

    Transaction.StartTransaction;
    Query.ExecSQL;
    Transaction.Commit;
  finally
    SchemaFile.Free;
    Query.Free;
    Connection.Free;
  end;
end;

function TTestTodoController.IsPortAvailable(const APort: Word): Boolean;
var
  Sock: LongInt;
  Addr: TInetSockAddr;
  Opt: LongInt;
begin
  Result := False;

  Sock := fpSocket(AF_INET, SOCK_STREAM, 0);
  if Sock < 0 then
    Exit;

  try
    Opt := 1;
    fpSetSockOpt(Sock, SOL_SOCKET, SO_REUSEADDR, @Opt, SizeOf(Opt));

    FillByte(Addr, SizeOf(Addr), 0);
    Addr.sin_family := AF_INET;
    Addr.sin_port := htons(APort);
    Addr.sin_addr.s_addr := htonl(INADDR_ANY);

    Result := fpBind(Sock, @Addr, SizeOf(Addr)) = 0;
  finally
    fpClose(Sock);
  end;
end;

function TTestTodoController.FindAvailablePort(const AStartPort, AMaxAttempts: Integer): Word;
var
  Sock: LongInt;
  Addr: TInetSockAddr;
  AddrLen: TSockLen;
  Opt: LongInt;
begin
  Sock := fpSocket(AF_INET, SOCK_STREAM, 0);
  if Sock < 0 then
    raise Exception.Create('Unable to create a TCP socket for test port reservation.');

  try
    Opt := 1;
    fpSetSockOpt(Sock, SOL_SOCKET, SO_REUSEADDR, @Opt, SizeOf(Opt));

    FillByte(Addr, SizeOf(Addr), 0);
    Addr.sin_family := AF_INET;
    Addr.sin_port := 0;
    Addr.sin_addr.s_addr := htonl(INADDR_ANY);

    if fpBind(Sock, @Addr, SizeOf(Addr)) <> 0 then
      raise Exception.Create('Unable to reserve an ephemeral TCP port for controller tests.');

    AddrLen := SizeOf(Addr);
    FillByte(Addr, SizeOf(Addr), 0);

    if fpGetSockName(Sock, @Addr, @AddrLen) <> 0 then
      raise Exception.Create('Unable to read back the reserved controller test port.');

    Result := ntohs(Addr.sin_port);
  finally
    fpClose(Sock);
  end;
end;

function TTestTodoController.BaseUrl: string;
begin
  Result := Format('http://127.0.0.1:%d', [FPort]);
end;

procedure TTestTodoController.StartServer;
var
  ServerBinary: string;
begin
  FPort := 54321;

  ServerBinary := ExpandFileName(
    IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
    '../../bin/ferroserver'
  );

  FServerProcess := TProcess.Create(nil);
  FServerProcess.Executable := '/usr/bin/env';
  FServerProcess.Parameters.Add('PORT=' + IntToStr(FPort));
  FServerProcess.Parameters.Add('DB_PATH=' + FDatabasePath);
  FServerProcess.Parameters.Add(ServerBinary);
  FServerProcess.Options := [poNewProcessGroup];
  FServerProcess.Execute;

  WaitForServerReady;
end;

procedure TTestTodoController.StopServer;
begin
  if not Assigned(FServerProcess) then
    Exit;

  if FServerProcess.Running then
  begin
    FServerProcess.Terminate(0);
    FServerProcess.WaitOnExit;
  end;

  FreeAndNil(FServerProcess);
end;

procedure TTestTodoController.WaitForServerReady;
var
  Client: TFPHTTPClient;
  Attempt: Integer;
  Content: string;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Client.IOTimeout := 1000;
    Client.ConnectTimeout := 1000;

    for Attempt := 1 to 50 do
    begin
      try
        Content := string(Client.Get(BaseUrl + '/api/todos'));
        if Content = '[]' then
          Exit;
      except
        on E: Exception do
        begin
          if Attempt = 50 then
            raise Exception.CreateFmt('Server did not become ready: %s', [E.Message]);
        end;
      end;

      Sleep(100);
    end;

    raise Exception.Create('Server did not become ready in time.');
  finally
    Client.Free;
  end;
end;

function TTestTodoController.GetJsonObject(const AContent: string): TJSONObject;
begin
  Result := GetJSON(AContent) as TJSONObject;
end;

function TTestTodoController.GetJsonArray(const AContent: string): TJSONArray;
begin
  Result := GetJSON(AContent) as TJSONArray;
end;

function TTestTodoController.HttpGet(const APath: string): string;
var
  Client: TFPHTTPClient;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Client.IOTimeout := 1000;
    Client.ConnectTimeout := 1000;
    Result := string(Client.Get(BaseUrl + APath));
  finally
    Client.Free;
  end;
end;

function TTestTodoController.HttpPostJson(const APath, AJson: string): string;
var
  Client: TTestHTTPClient;
  BodyStream: TStringStream;
begin
  Client := TTestHTTPClient.Create(nil);
  BodyStream := TStringStream.Create(AJson);
  try
    Client.IOTimeout := 1000;
    Client.ConnectTimeout := 1000;
    Client.AddHeader('Content-Type', 'application/json');
    Client.SetRequestBodyStream(BodyStream);
    Result := string(Client.Post(BaseUrl + APath));
  finally
    BodyStream.Free;
    Client.Free;
  end;
end;

function TTestTodoController.HttpPutJson(const APath, AJson: string): string;
var
  Client: TTestHTTPClient;
  BodyStream: TStringStream;
begin
  Client := TTestHTTPClient.Create(nil);
  BodyStream := TStringStream.Create(AJson);
  try
    Client.IOTimeout := 1000;
    Client.ConnectTimeout := 1000;
    Client.AddHeader('Content-Type', 'application/json');
    Client.SetRequestBodyStream(BodyStream);
    Result := string(Client.Put(BaseUrl + APath));
  finally
    BodyStream.Free;
    Client.Free;
  end;
end;

function TTestTodoController.HttpDelete(const APath: string): string;
var
  Client: TFPHTTPClient;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Client.IOTimeout := 1000;
    Client.ConnectTimeout := 1000;
    Result := string(Client.Delete(BaseUrl + APath));
  finally
    Client.Free;
  end;
end;

function TTestTodoController.CreateTodoJson(const ATitle: string; const ACompleted: Boolean): string;
var
  Payload: TJSONObject;
begin
  Payload := TJSONObject.Create;
  try
    Payload.Add('title', ATitle);
    Payload.Add('completed', ACompleted);
    Result := Payload.AsJSON;
  finally
    Payload.Free;
  end;
end;

procedure TTestTodoController.SetUp;
begin
  EnsureFreshDatabase;
  StartServer;
end;

procedure TTestTodoController.TearDown;
begin
  StopServer;
end;

procedure TTestTodoController.GetTodosReturnsAnEmptyArray;
var
  Todos: TJSONArray;
begin
  Todos := GetJsonArray(HttpGet('/api/todos'));
  try
    AssertEquals(0, Todos.Count);
  finally
    Todos.Free;
  end;
end;

procedure TTestTodoController.CreateTodoReturnsCreatedTodoWithId;
var
  CreatedJson: TJSONObject;
begin
  CreatedJson := GetJsonObject(HttpPostJson('/api/todos', CreateTodoJson('Write controller tests')));
  try
    AssertEquals('Write controller tests', CreatedJson.Strings['title']);
    AssertFalse(CreatedJson.Booleans['completed']);
    AssertTrue(CreatedJson.Integers['id'] > 0);
  finally
    CreatedJson.Free;
  end;
end;

procedure TTestTodoController.GetTodoByIdReturnsTheStoredTodo;
var
  Repository: TTodoRepository;
  CreatedId: Integer;
  TodoJson: TJSONObject;
begin
  Repository := TTodoRepository.Create;
  try
    CreatedId := Repository.CreateTodo('Fetch me');
  finally
    Repository.Free;
  end;

  TodoJson := GetJsonObject(HttpGet('/api/todos/' + IntToStr(CreatedId)));
  try
    AssertEquals(CreatedId, TodoJson.Integers['id']);
    AssertEquals('Fetch me', TodoJson.Strings['title']);
    AssertFalse(TodoJson.Booleans['completed']);
  finally
    TodoJson.Free;
  end;
end;

procedure TTestTodoController.UpdateTodoReturnsTheUpdatedTodo;
var
  Repository: TTodoRepository;
  CreatedId: Integer;
  TodoJson: TJSONObject;
begin
  Repository := TTodoRepository.Create;
  try
    CreatedId := Repository.CreateTodo('Original title');
  finally
    Repository.Free;
  end;

  TodoJson := GetJsonObject(HttpPutJson(
    '/api/todos/' + IntToStr(CreatedId),
    CreateTodoJson('Updated title', True)
  ));
  try
    AssertEquals('Updated title', TodoJson.Strings['title']);
    AssertTrue(TodoJson.Booleans['completed']);
  finally
    TodoJson.Free;
  end;

  Repository := TTodoRepository.Create;
  try
    TodoJson := Repository.GetById(CreatedId);
    try
      AssertNotNull(TodoJson);
      AssertEquals('Updated title', TodoJson.Strings['title']);
      AssertTrue(TodoJson.Booleans['completed']);
    finally
      TodoJson.Free;
    end;
  finally
    Repository.Free;
  end;
end;

procedure TTestTodoController.DeleteTodoReturnsNoContent;
var
  Repository: TTodoRepository;
  CreatedId: Integer;
begin
  Repository := TTodoRepository.Create;
  try
    CreatedId := Repository.CreateTodo('Remove me');
  finally
    Repository.Free;
  end;

  AssertEquals('', HttpDelete('/api/todos/' + IntToStr(CreatedId)));

  Repository := TTodoRepository.Create;
  try
    AssertNull(Repository.GetById(CreatedId));
  finally
    Repository.Free;
  end;
end;

initialization
  RegisterTest(TTestTodoController);

end.

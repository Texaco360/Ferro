unit server_bootstrap;

{$mode delphi}
{$H+}

interface

procedure StartServer;

implementation

uses
  BaseUnix,
  Sockets,
  SysUtils,
  Horse,
  todo_controller;

function IsPortAvailable(const APort: Word): Boolean;
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

function FindAvailablePort(const AStartPort: Integer; const AMaxAttempts: Integer): Integer;
var
  Candidate: Integer;
  Attempt: Integer;
begin
  Candidate := AStartPort;
  if Candidate < 1 then
    Candidate := 9000;

  for Attempt := 0 to AMaxAttempts - 1 do
  begin
    if Candidate > 65535 then
      Candidate := 1024;

    if IsPortAvailable(Candidate) then
      Exit(Candidate);

    Inc(Candidate);
  end;

  raise Exception.CreateFmt(
    'No free TCP port found after %d attempts starting at %d.',
    [AMaxAttempts, AStartPort]
  );
end;

procedure RegisterRoutes;
begin
  THorse.Get('/api/todos', GetTodos);
  THorse.Get('/api/todos/:id', GetTodoById);
    THorse.Post('/api/todos', CreateTodo);
    THorse.Put('/api/todos/:id', UpdateTodo);
    THorse.Delete('/api/todos/:id', DeleteTodo);
end;

procedure StartServer;
var
  RequestedPort: Integer;
  Port: Integer;
begin
  RequestedPort := StrToIntDef(GetEnvironmentVariable('PORT'), 9000);
  Port := FindAvailablePort(RequestedPort, 500);

  if Port <> RequestedPort then
    Writeln(Format('Port %d is busy, using %d.', [RequestedPort, Port]));

  RegisterRoutes;
  THorse.Listen(Port);
end;

end.

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
  migrations,
  todo_controller,
  project_controller; // $USES_END

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
  THorse.Get('/api/todos', TTodoController.GetAll);
  THorse.Get('/api/todos/:id', TTodoController.GetById);
  THorse.Post('/api/todos', TTodoController.Create);
  THorse.Put('/api/todos/:id', TTodoController.Update);
  THorse.Delete('/api/todos/:id', TTodoController.Delete);
  THorse.Get('/api/projects', TProjectController.GetAll);
  THorse.Get('/api/projects/:id', TProjectController.GetById);
  THorse.Post('/api/projects', TProjectController.Create);
  THorse.Put('/api/projects/:id', TProjectController.Update);
  THorse.Delete('/api/projects/:id', TProjectController.Delete);
  // $ROUTES_END
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

  RunMigrations;
  RegisterRoutes;
  THorse.Listen(Port);
end;

end.

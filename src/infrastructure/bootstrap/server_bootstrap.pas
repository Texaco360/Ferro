unit server_bootstrap;

{$mode delphi}
{$H+}

interface

procedure StartServer;

implementation

uses
  {$IFDEF UNIX}
  BaseUnix,
  {$ENDIF}
  Sockets,
  SysUtils,
  Horse,
  migrations,
  app_routes,
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
    {$IFDEF UNIX}
    fpClose(Sock);
    {$ELSE}
    CloseSocket(Sock);
    {$ENDIF}
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

procedure StartServer;
var
  RequestedPort: Integer;
  Port: Integer;
  Host: string;
begin
  RequestedPort := StrToIntDef(GetEnvironmentVariable('PORT'), 9000);
  Port := RequestedPort;
  if Port < 1 then
    Port := 9000;
  Host := Trim(GetEnvironmentVariable('HOST'));
  if Host = '' then
    Host := '0.0.0.0';

  RunMigrations;
  app_routes.RegisterRoutes;
  THorse.Listen(Port, Host);
end;

end.

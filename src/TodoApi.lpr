program TodoApi;

{$MODE DELPHI}
{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  server_bootstrap;

begin
  StartServer;

end.
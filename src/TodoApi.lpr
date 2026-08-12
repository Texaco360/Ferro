program TodoApi;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  server_bootstrap;

begin
  StartServer;

end.
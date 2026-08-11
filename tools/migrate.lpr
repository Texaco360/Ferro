program migrate;

{$MODE DELPHI}
{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  migrations;

procedure PrintUsage;
begin
  Writeln('Usage: migrate [--status|--fresh]');
  Writeln('');
  Writeln('  (no args)   Apply pending migrations');
  Writeln('  --status    Show applied and pending migrations');
  Writeln('  --fresh     Drop all tables and re-run all migrations');
end;

begin
  if ParamCount = 0 then
    RunMigrations
  else if ParamStr(1) = '--status' then
    MigrationStatus
  else if ParamStr(1) = '--fresh' then
    FreshMigrations
  else
  begin
    Writeln('Unknown option: ' + ParamStr(1));
    Writeln('');
    PrintUsage;
    Halt(1);
  end;
end.

program FerroServerTests;

{$mode objfpc}{$H+}

uses
  consoletestrunner,
  todo_controller_tests,
  todo_repository_tests;

begin
  with TTestRunner.Create(nil) do
  try
    Title := 'FerroServer tests';
    Run;
  finally
    Free;
  end;
end.
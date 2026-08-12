unit todo_repository_tests;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  fpcunit,
  testregistry,
  migrations,
  todo_dto,
  todo_repository;

type
  TTestTodoRepository = class(TTestCase)
  private
    FDatabasePath: string;
    function ResolveDatabasePath: string;
    procedure EnsureFreshDatabase;
    function CreateRepository: TTodoRepository;
  protected
    procedure SetUp; override;
  published
    procedure GetAllReturnsAnEmptyArray;
    procedure CreateTodoPersistsATodo;
    procedure GetByIdReturnsTheInsertedTodo;
    procedure UpdateChangesTheStoredRow;
    procedure DeleteRemovesTheStoredRow;
  end;

implementation

uses
  {$IFDEF WINDOWS}
  Windows;
  {$ELSE}
  Unix;
  {$ENDIF}

{$IFDEF UNIX}
function setenv(name: PAnsiChar; value: PAnsiChar; overwrite: LongInt): LongInt; cdecl; external 'c' name 'setenv';
{$ENDIF}

procedure SetDbPathEnv(const APath: string);
begin
  {$IFDEF WINDOWS}
  if not Windows.SetEnvironmentVariable(PChar('DB_PATH'), PChar(APath)) then
    raise Exception.Create('Unable to set DB_PATH environment variable.');
  {$ELSE}
  if setenv(PAnsiChar(AnsiString('DB_PATH')), PAnsiChar(AnsiString(APath)), 1) <> 0 then
    raise Exception.Create('Unable to set DB_PATH environment variable.');
  {$ENDIF}
end;

function TTestTodoRepository.ResolveDatabasePath: string;
begin
  Result := Trim(SysUtils.GetEnvironmentVariable('DB_PATH'));
  if Result <> '' then
    Exit;

  Result := ExpandFileName(
    IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
    '../ferroserver-tests.sqlite'
  );
end;

procedure TTestTodoRepository.EnsureFreshDatabase;
begin
  if FDatabasePath = '' then
    FDatabasePath := ResolveDatabasePath;

  SetDbPathEnv(FDatabasePath);

  if FileExists(FDatabasePath) then
    SysUtils.DeleteFile(FDatabasePath);

  RunMigrations;
end;

function TTestTodoRepository.CreateRepository: TTodoRepository;
begin
  Result := TTodoRepository.Create;
end;

procedure TTestTodoRepository.SetUp;
begin
  EnsureFreshDatabase;
end;

procedure TTestTodoRepository.GetAllReturnsAnEmptyArray;
var
  Repository: TTodoRepository;
  Todos: TTodoDTOList;
begin
  Repository := CreateRepository;
  Todos := nil;
  try
    Todos := Repository.GetAll;
    AssertEquals(0, Todos.Count);
  finally
    Todos.Free;
    Repository.Free;
  end;
end;

procedure TTestTodoRepository.CreateTodoPersistsATodo;
var
  Repository: TTodoRepository;
  Todo: TTodoDTO;
begin
  Repository := CreateRepository;
  Todo := nil;
  try
    Todo := Repository.CreateTodo('Write tests');
    AssertNotNull(Todo);
    AssertTrue(Todo.Id > 0);
    AssertEquals('Write tests', Todo.Title);
    AssertFalse(Todo.Completed);
  finally
    Todo.Free;
    Repository.Free;
  end;
end;

procedure TTestTodoRepository.GetByIdReturnsTheInsertedTodo;
var
  Repository: TTodoRepository;
  CreatedTodo: TTodoDTO;
  Todo: TTodoDTO;
begin
  Repository := CreateRepository;
  CreatedTodo := nil;
  Todo := nil;
  try
    CreatedTodo := Repository.CreateTodo('Write tests');

    Todo := Repository.GetById(CreatedTodo.Id);
    AssertNotNull(Todo);
    AssertEquals(CreatedTodo.Id, Todo.Id);
    AssertEquals('Write tests', Todo.Title);
    AssertFalse(Todo.Completed);
  finally
    CreatedTodo.Free;
    Todo.Free;
    Repository.Free;
  end;
end;

procedure TTestTodoRepository.UpdateChangesTheStoredRow;
var
  Repository: TTodoRepository;
  CreatedTodo: TTodoDTO;
  Todo: TTodoDTO;
  UpdatedTodo: TTodoDTO;
begin
  Repository := CreateRepository;
  CreatedTodo := nil;
  Todo := nil;
  UpdatedTodo := nil;
  try
    CreatedTodo := Repository.CreateTodo('Write tests');
    UpdatedTodo := Repository.Update(CreatedTodo.Id, 'Write more tests', True);
    UpdatedTodo.Free;
    UpdatedTodo := nil;

    Todo := Repository.GetById(CreatedTodo.Id);
    AssertNotNull(Todo);
    AssertEquals('Write more tests', Todo.Title);
    AssertTrue(Todo.Completed);
  finally
    UpdatedTodo.Free;
    CreatedTodo.Free;
    Todo.Free;
    Repository.Free;
  end;
end;

procedure TTestTodoRepository.DeleteRemovesTheStoredRow;
var
  Repository: TTodoRepository;
  CreatedTodo: TTodoDTO;
  Todo: TTodoDTO;
begin
  Repository := CreateRepository;
  CreatedTodo := nil;
  Todo := nil;
  try
    CreatedTodo := Repository.CreateTodo('Write tests');
    Repository.Delete(CreatedTodo.Id);

    Todo := Repository.GetById(CreatedTodo.Id);
    AssertNull(Todo);
  finally
    CreatedTodo.Free;
    Todo.Free;
    Repository.Free;
  end;
end;

initialization
  RegisterTest(TTestTodoRepository);

end.
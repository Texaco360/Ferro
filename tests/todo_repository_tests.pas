unit todo_repository_tests;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  fpcunit,
  testregistry,
  migrations,
  fpjson,
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

function setenv(name: PAnsiChar; value: PAnsiChar; overwrite: LongInt): LongInt; cdecl; external 'c' name 'setenv';

function TTestTodoRepository.ResolveDatabasePath: string;
begin
  Result := Trim(GetEnvironmentVariable('DB_PATH'));
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

  setenv(
    PAnsiChar(AnsiString('DB_PATH')),
    PAnsiChar(AnsiString(FDatabasePath)),
    1
  );

  if FileExists(FDatabasePath) then
    DeleteFile(FDatabasePath);

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
  Todos: TJSONArray;
begin
  Repository := CreateRepository;
  try
    Todos := Repository.GetAll;
    try
      AssertEquals(0, Todos.Count);
    finally
      Todos.Free;
    end;
  finally
    Repository.Free;
  end;
end;

procedure TTestTodoRepository.CreateTodoPersistsATodo;
var
  Repository: TTodoRepository;
  CreatedId: Integer;
begin
  Repository := CreateRepository;
  try
    CreatedId := Repository.CreateTodo('Write tests');

    AssertTrue(CreatedId > 0);
  finally
    Repository.Free;
  end;
end;

procedure TTestTodoRepository.GetByIdReturnsTheInsertedTodo;
var
  Repository: TTodoRepository;
  CreatedId: Integer;
  Todo: TJSONObject;
begin
  Repository := CreateRepository;
  try
    CreatedId := Repository.CreateTodo('Write tests');

    Todo := Repository.GetById(CreatedId);
    try
      AssertNotNull(Todo);
      AssertEquals(CreatedId, Todo.Integers['id']);
      AssertEquals('Write tests', Todo.Strings['title']);
      AssertFalse(Todo.Booleans['completed']);
    finally
      Todo.Free;
    end;
  finally
    Repository.Free;
  end;
end;

procedure TTestTodoRepository.UpdateChangesTheStoredRow;
var
  Repository: TTodoRepository;
  CreatedId: Integer;
  Todo: TJSONObject;
begin
  Repository := CreateRepository;
  try
    CreatedId := Repository.CreateTodo('Write tests');
    Repository.Update(CreatedId, 'Write more tests', True);

    Todo := Repository.GetById(CreatedId);
    try
      AssertNotNull(Todo);
      AssertEquals('Write more tests', Todo.Strings['title']);
      AssertTrue(Todo.Booleans['completed']);
    finally
      Todo.Free;
    end;
  finally
    Repository.Free;
  end;
end;

procedure TTestTodoRepository.DeleteRemovesTheStoredRow;
var
  Repository: TTodoRepository;
  CreatedId: Integer;
begin
  Repository := CreateRepository;
  try
    CreatedId := Repository.CreateTodo('Write tests');
    Repository.Delete(CreatedId);

    AssertNull(Repository.GetById(CreatedId));
  finally
    Repository.Free;
  end;
end;

initialization
  RegisterTest(TTestTodoRepository);

end.
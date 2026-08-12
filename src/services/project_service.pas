unit project_service;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  fpjson,
  project_repository;

type
  EProjectValidationError = class(Exception);

  TProjectService = class
  private
    FRepository: TProjectRepository;
    procedure ValidateName(const AName: String);

  public
    constructor Create(ARepository: TProjectRepository);

    function GetAll: TJSONArray;

    function GetById(
      const AId: Integer
    ): TJSONObject;

    function CreateProject(
      const AName: String
    ): TJSONObject;

    function UpdateProject(
      const AId: Integer;
      const AName: String
    ): TJSONObject;

    procedure DeleteProject(
      const AId: Integer
    );
  end;

implementation

constructor TProjectService.Create(ARepository: TProjectRepository);
begin
  inherited Create;
  FRepository := ARepository;
end;

procedure TProjectService.ValidateName(const AName: String);
var
  TrimmedName: String;
begin
  TrimmedName := Trim(AName);

  if TrimmedName = '' then
    raise EProjectValidationError.Create('Name is required');

  if Length(TrimmedName) > 200 then
    raise EProjectValidationError.Create('Name must be <= 200 chars');
end;

function TProjectService.GetAll: TJSONArray;
begin
  Result := FRepository.GetAll;
end;

function TProjectService.GetById(
  const AId: Integer
): TJSONObject;
begin
  if AId <= 0 then
    raise EProjectValidationError.Create('Invalid project id');

  Result := FRepository.GetById(AId);
end;

function TProjectService.CreateProject(
  const AName: String
): TJSONObject;
var
  ItemId: Integer;
begin
  ValidateName(AName);

  ItemId := FRepository.CreateProject(Trim(AName));
  Result := FRepository.GetById(ItemId);
end;

function TProjectService.UpdateProject(
  const AId: Integer;
  const AName: String
): TJSONObject;
begin
  if AId <= 0 then
    raise EProjectValidationError.Create('Invalid project id');

  ValidateName(AName);

  FRepository.Update(AId, Trim(AName));
  Result := FRepository.GetById(AId);
end;

procedure TProjectService.DeleteProject(
  const AId: Integer
);
begin
  if AId <= 0 then
    raise EProjectValidationError.Create('Invalid project id');

  FRepository.Delete(AId);
end;

end.

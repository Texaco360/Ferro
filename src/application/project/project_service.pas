unit project_service;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  project_dto,
  project_repository;

type
  EProjectValidationError = class(Exception);

  TProjectService = class
  private
    FRepository: TProjectRepository;
    procedure ValidateName(const AName: String);

  public
    constructor Create(ARepository: TProjectRepository);

    function GetAll: TProjectDTOList;

    function GetById(
      const AId: Integer
    ): TProjectDTO;

    function CreateProject(
      const AInput: TProjectDTO
    ): TProjectDTO;

    function UpdateProject(
      const AId: Integer;
      const AInput: TProjectDTO
    ): TProjectDTO;

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

function TProjectService.GetAll: TProjectDTOList;
begin
  Result := FRepository.GetAll;
end;

function TProjectService.GetById(
  const AId: Integer
): TProjectDTO;
begin
  if AId <= 0 then
    raise EProjectValidationError.Create('Invalid project id');

  Result := FRepository.GetById(AId);
end;

function TProjectService.CreateProject(
  const AInput: TProjectDTO
): TProjectDTO;
begin
  ValidateName(AInput.Name);

  Result := FRepository.CreateProject(Trim(AInput.Name));
end;

function TProjectService.UpdateProject(
  const AId: Integer;
  const AInput: TProjectDTO
): TProjectDTO;
begin
  if AId <= 0 then
    raise EProjectValidationError.Create('Invalid project id');

  ValidateName(AInput.Name);

  Result := FRepository.Update(AId, Trim(AInput.Name));
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

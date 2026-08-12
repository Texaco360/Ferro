unit todo_service;

{$mode objfpc}{$H+}

interface

uses
	SysUtils,
	todo_dto,
	todo_repository;

type
	ETodoValidationError = class(Exception);

	TTodoService = class
	private
		FRepository: TTodoRepository;
		procedure ValidateTitle(const ATitle: String);

	public
		constructor Create(ARepository: TTodoRepository);

		function GetAll: TTodoDTOList;

		function GetById(
			const AId: Integer
		): TTodoDTO;

		function CreateTodo(
			const AInput: TTodoDTO
		): TTodoDTO;

		function UpdateTodo(
			const AId: Integer;
			const AInput: TTodoDTO
		): TTodoDTO;

		procedure DeleteTodo(
			const AId: Integer
		);
	end;

implementation

constructor TTodoService.Create(ARepository: TTodoRepository);
begin
	inherited Create;
	FRepository := ARepository;
end;

procedure TTodoService.ValidateTitle(const ATitle: String);
var
	TrimmedTitle: String;
begin
	TrimmedTitle := Trim(ATitle);

	if TrimmedTitle = '' then
		raise ETodoValidationError.Create('Title is required');

	if Length(TrimmedTitle) > 200 then
		raise ETodoValidationError.Create('Title must be <= 200 chars');
end;

function TTodoService.GetAll: TTodoDTOList;
begin
	Result := FRepository.GetAll;
end;

function TTodoService.GetById(
	const AId: Integer
): TTodoDTO;
begin
	if AId <= 0 then
		raise ETodoValidationError.Create('Invalid todo id');

	Result := FRepository.GetById(AId);
end;

function TTodoService.CreateTodo(
	const AInput: TTodoDTO
): TTodoDTO;
begin
	ValidateTitle(AInput.Title);

	Result := FRepository.CreateTodo(Trim(AInput.Title));
end;

function TTodoService.UpdateTodo(
	const AId: Integer;
	const AInput: TTodoDTO
): TTodoDTO;
begin
	if AId <= 0 then
		raise ETodoValidationError.Create('Invalid todo id');

	ValidateTitle(AInput.Title);

	Result := FRepository.Update(AId, Trim(AInput.Title), AInput.Completed);
end;

procedure TTodoService.DeleteTodo(
	const AId: Integer
);
begin
	if AId <= 0 then
		raise ETodoValidationError.Create('Invalid todo id');

	FRepository.Delete(AId);
end;

end.

unit todo_service;

{$mode objfpc}{$H+}

interface

uses
	SysUtils,
	fpjson,
	todo_repository;

type
	ETodoValidationError = class(Exception);

	TTodoService = class
	private
		FRepository: TTodoRepository;
		procedure ValidateTitle(const ATitle: String);

	public
		constructor Create(ARepository: TTodoRepository);

		function GetAll: TJSONArray;

		function GetById(
			const AId: Integer
		): TJSONObject;

		function CreateTodo(
			const ATitle: String
		): TJSONObject;

		function UpdateTodo(
			const AId: Integer;
			const ATitle: String;
			const ACompleted: Boolean
		): TJSONObject;

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

function TTodoService.GetAll: TJSONArray;
begin
	Result := FRepository.GetAll;
end;

function TTodoService.GetById(
	const AId: Integer
): TJSONObject;
begin
	if AId <= 0 then
		raise ETodoValidationError.Create('Invalid todo id');

	Result := FRepository.GetById(AId);
end;

function TTodoService.CreateTodo(
	const ATitle: String
): TJSONObject;
var
	TodoId: Integer;
begin
	ValidateTitle(ATitle);

	TodoId := FRepository.CreateTodo(Trim(ATitle));
	Result := FRepository.GetById(TodoId);
end;

function TTodoService.UpdateTodo(
	const AId: Integer;
	const ATitle: String;
	const ACompleted: Boolean
): TJSONObject;
begin
	if AId <= 0 then
		raise ETodoValidationError.Create('Invalid todo id');

	ValidateTitle(ATitle);

	FRepository.Update(AId, Trim(ATitle), ACompleted);
	Result := FRepository.GetById(AId);
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

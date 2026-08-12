unit base_dto;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  fpjson,
  jsonparser;

type
  EDTOValidationError = class(Exception);

  TBaseDTO = class
  protected
    class function ParseRequestBody(const ABody: String): TJSONObject; static;
    class function RequireStringField(
      const AObject: TJSONObject;
      const AFieldName: String
    ): String; static;
    class function RequireBooleanField(
      const AObject: TJSONObject;
      const AFieldName: String
    ): Boolean; static;
  end;

implementation

class function TBaseDTO.ParseRequestBody(const ABody: String): TJSONObject;
var
  Data: TJSONData;
begin
  Data := GetJSON(ABody);

  if Data.JSONType <> jtObject then
  begin
    Data.Free;
    raise EDTOValidationError.Create('Request body must be a JSON object');
  end;

  Result := TJSONObject(Data);
end;

class function TBaseDTO.RequireStringField(
  const AObject: TJSONObject;
  const AFieldName: String
): String;
var
  Value: TJSONData;
begin
  Value := AObject.Find(AFieldName);

  if Value = nil then
    raise EDTOValidationError.CreateFmt('Field "%s" is required', [AFieldName]);

  if Value.JSONType <> jtString then
    raise EDTOValidationError.CreateFmt('Field "%s" must be a string', [AFieldName]);

  Result := Value.AsString;
end;

class function TBaseDTO.RequireBooleanField(
  const AObject: TJSONObject;
  const AFieldName: String
): Boolean;
var
  Value: TJSONData;
begin
  Value := AObject.Find(AFieldName);

  if Value = nil then
    raise EDTOValidationError.CreateFmt('Field "%s" is required', [AFieldName]);

  if Value.JSONType <> jtBoolean then
    raise EDTOValidationError.CreateFmt('Field "%s" must be a boolean', [AFieldName]);

  Result := Value.AsBoolean;
end;

end.

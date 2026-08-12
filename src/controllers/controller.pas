unit controller;

{$mode objfpc}{$H+}


interface

uses
  SysUtils,
  Horse,
  fpjson;

type

  TBaseController = class
  protected
    class function ParamAsInt(
      Req: THorseRequest;
      const AName: String;
      const ADefault: Integer = 0
    ): Integer; static;

    class procedure SendJSON(
      Res: THorseResponse;
      Data: TJSONData;
      const AStatus: Integer = 200
    ); static;

    class procedure SendNoContent(
      Res: THorseResponse
    ); static;
  end;

implementation

class function TBaseController.ParamAsInt(
  Req: THorseRequest;
  const AName: String;
  const ADefault: Integer
): Integer;
begin
  Result := StrToIntDef(Req.Params[AName], ADefault);
end;

class procedure TBaseController.SendJSON(
  Res: THorseResponse;
  Data: TJSONData;
  const AStatus: Integer
);
begin
  Res
    .Status(AStatus)
    .ContentType('application/json')
    .Send(Data.AsJSON);
end;

class procedure TBaseController.SendNoContent(
  Res: THorseResponse
);
begin
  Res.Status(204).Send('');
end;

end.

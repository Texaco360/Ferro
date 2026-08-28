unit EventBus;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Contnrs, AppEvents;

type
  TEventHandler = procedure(const AEvent: TAppEvent) of object;
  TAppEventClass = class of TAppEvent;

  TSubscription = class
  public
    EventClass: TAppEventClass;
    Handler: TEventHandler;
    constructor Create(AEventClass: TAppEventClass; AHandler: TEventHandler);
  end;

  TEventBus = class
  private
    FSubscriptions: TObjectList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Subscribe(AEventClass: TAppEventClass; AHandler: TEventHandler);
    procedure Publish(AEvent: TAppEvent);
  end;

implementation

constructor TSubscription.Create(AEventClass: TAppEventClass; AHandler: TEventHandler);
begin
  inherited Create;
  EventClass := AEventClass;
  Handler := AHandler;
end;

constructor TEventBus.Create;
begin
  inherited Create;
  FSubscriptions := TObjectList.Create(True);
end;

destructor TEventBus.Destroy;
begin
  FSubscriptions.Free;
  inherited Destroy;
end;

procedure TEventBus.Subscribe(AEventClass: TAppEventClass; AHandler: TEventHandler);
begin
  FSubscriptions.Add(TSubscription.Create(AEventClass, AHandler));
end;

procedure TEventBus.Publish(AEvent: TAppEvent);
var
  I: Integer;
  Subscription: TSubscription;
begin
  if AEvent = nil then
    Exit;
  try
    for I := 0 to FSubscriptions.Count - 1 do
    begin
      Subscription := TSubscription(FSubscriptions[I]);
      if AEvent.InheritsFrom(Subscription.EventClass) then
        Subscription.Handler(AEvent);
    end;
  finally
    AEvent.Free;
  end;
end;

end.

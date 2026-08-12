unit app_routes;

{$mode delphi}{$H+}

interface

procedure RegisterRoutes;

implementation

uses
  Horse,
  todo_controller,
  project_controller; // $USES_END

procedure RegisterRoutes;

begin
  THorse.Get('/api/todos', TTodoController.GetAll);
  THorse.Get('/api/todos/:id', TTodoController.GetById);
  THorse.Post('/api/todos', TTodoController.Create);
  THorse.Put('/api/todos/:id', TTodoController.Update);
  THorse.Delete('/api/todos/:id', TTodoController.Delete);
  THorse.Get('/api/projects', TProjectController.GetAll);
  THorse.Get('/api/projects/:id', TProjectController.GetById);
  THorse.Post('/api/projects', TProjectController.Create);
  THorse.Put('/api/projects/:id', TProjectController.Update);
  THorse.Delete('/api/projects/:id', TProjectController.Delete);
  // $ROUTES_END
end;

end.

# FerroServer — Code Generation & Migrations

Two shell scripts cover the full lifecycle of adding new models and keeping the database schema in sync.

---

## Migration runner — `scripts/migrate.sh`

Manages schema versioning through a `schema_migrations` table in SQLite. Migrations are stored directly in `src/database/migrations.pas` as compiled Pascal code — no SQL files on disk, so the binary is fully self-contained (important for Tauri sidecar deployment).

### Commands

```bash
# Apply all pending migrations
./scripts/migrate.sh

# Show which migrations are applied / pending
./scripts/migrate.sh --status

# Drop every table and re-run all migrations from scratch
./scripts/migrate.sh --fresh
```

### How it works

On first run, a `schema_migrations` table is created. Each migration has a unique version string (e.g. `20260811_001_create_todos`). The runner checks which versions are already recorded and only executes the new ones. Each migration runs in its own transaction; if it succeeds the version is inserted into `schema_migrations`.

**The server also runs migrations automatically on startup** — you only need the CLI for development tooling (inspecting status, resetting a local DB).

### Adding a migration manually

Open `src/database/migrations.pas` and add a call to `AddMigration` inside `RegisterMigrations`, just before the `// $MIGRATIONS_END` sentinel:

```pascal
procedure RegisterMigrations;
begin
  if FRegistered then Exit;
  FRegistered := True;

  AddMigration(
    '20260811_001_create_todos',
    'CREATE TABLE IF NOT EXISTS todos (...)'
  );

  // Add your new migration here, before the sentinel:
  AddMigration(
    '20260812_001_add_priority_to_todos',
    'ALTER TABLE todos ADD COLUMN priority INTEGER NOT NULL DEFAULT 0'
  );
  // $MIGRATIONS_END
end;
```

**Version naming convention:** `YYYYMMDD_NNN_description`
- Date of creation
- Three-digit sequence number for same-day migrations
- Short snake_case description

Versions must be unique. Once a version is applied to any environment, do not change its SQL — write a new migration instead.

---

## Scaffold generator — `scripts/generate.sh`

Generates a complete CRUD skeleton for a new model: DTO, repository, controller, migration, and route registration — all in one command.

### Usage

```bash
./scripts/generate.sh <ModelName>
```

`ModelName` must be **PascalCase** with an uppercase first letter.

```bash
./scripts/generate.sh Invoice
./scripts/generate.sh ProjectTask
./scripts/generate.sh Category
```

### What gets created

Running `./scripts/generate.sh Invoice` produces:

| File | Description |
|---|---|
| `src/dto/invoice_dto.pas` | `TInvoiceDTO` record — scaffolded, not yet wired |
| `src/repositories/invoice_repository.pas` | `TInvoiceRepository` with full CRUD against SQLite |
| `src/controllers/invoice_controller.pas` | 5 Horse handler procedures |

And patches two existing files:

| File | Change |
|---|---|
| `src/database/migrations.pas` | Inserts `AddMigration(...)` call for `CREATE TABLE invoices` |
| `src/bootstrap/server_bootstrap.pas` | Adds `invoice_controller` to `uses` and 5 route registrations |

### Routes registered

```
GET    /api/invoices
GET    /api/invoices/:id
POST   /api/invoices
PUT    /api/invoices/:id
DELETE /api/invoices/:id
```

### After generating

```bash
# Build the project — no other manual steps needed
./scripts/build.sh
```

The new endpoints are immediately available. The migration runs automatically on next server start.

### Idempotency guard

Running the generator twice for the same model name exits with an error listing the conflicting files. No partial changes are made.

```
ERROR: Model "Invoice" already exists. Aborting.
  Exists: src/dto/invoice_dto.pas
  Exists: src/repositories/invoice_repository.pas
  Exists: src/controllers/invoice_controller.pas
```

---

## Default generated schema

Every generated model gets this minimal table:

```sql
CREATE TABLE IF NOT EXISTS {plural} (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  name       TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)
```

The single `name` field is a placeholder. **Customize the migration SQL before running `migrate.sh`** if your model needs different fields. Edit the `AddMigration` call that was inserted into `migrations.pas`.

The repository and controller also use `name` as the only writable field. Update them to match after editing the migration.

---

## Pluralization

The generator appends `s` to produce the table name and route path:

| Model | Table | Route prefix |
|---|---|---|
| `Project` | `projects` | `/api/projects` |
| `Invoice` | `invoices` | `/api/invoices` |
| `Category` | `categorys` ⚠️ | `/api/categorys` ⚠️ |

Irregular plurals (`Category → categories`, `Status → statuses`) need to be fixed manually in the generated migration SQL and the repository's SQL queries after generation.

---

## Full workflow example

```bash
# 1. Generate the skeleton
./scripts/generate.sh Project

# 2. (Optional) edit the migration to add more fields
#    Open src/database/migrations.pas and change the AddMigration SQL

# 3. Build
./scripts/build.sh

# 4. Test — the projects table is created automatically on server start
./scripts/run.sh
curl http://localhost:9010/api/projects        # → []
curl -X POST http://localhost:9010/api/projects \
     -H 'Content-Type: application/json' \
     -d '{"name":"My first project"}'         # → {"name":"My first project","id":1}
```

---

## Sentinel comments

The generator uses two marker comments in `server_bootstrap.pas` to know where to insert code. Do not remove them.

```pascal
// In the uses clause — new controllers are inserted before this line:
project_controller; // $USES_END

// In RegisterRoutes — new routes are inserted before this line:
  // $ROUTES_END
```

Similarly, `migrations.pas` contains:

```pascal
  // $MIGRATIONS_END
```

New `AddMigration` calls are inserted before this line by the generator.

Architecture.md: Build a full-stack mobile-companion application named **Pulse (Continuous Supply Chain Integrity Monitor)**.

## Purpose

Give developers and security engineers a lightweight mobile companion to check the security status of their software projects on the go. The app lets the user add Git repositories, trigger a manual scan, view detected components and CVEs, see drift between scans, and receive an email alert when a critical CVE or suspicious drift is found. This is not a full compliance/auditing dashboard — that use case is explicitly out of scope for this version (see `docs/PROPOSAL.md`).

## Use this stack

* Mobile Frontend: Flutter + Riverpod (state management) + go_router (routing) + dio (HTTP client)
* Backend: Python 3.11+ + FastAPI
* Database: PostgreSQL 16 (single relational database — no graph database in this version)
* ORM: SQLAlchemy 2.0 + Alembic (migrations)
* API style: REST API (synchronous — no task queue/worker in this version)
* SBOM Generation: Syft (invoked synchronously by the scan endpoint)
* Vulnerability Data Source: OSV.dev API only (no NVD, no CISA KEV in this version)
* Alerting: Email (SMTP) only
* Auth: JWT, single user role (no RBAC in this version)
* Use Docker Compose for PostgreSQL and the backend
* Use `.env.example` for database URL, SMTP credentials, and JWT secret

## Code rules

* Do not add comments unless truly necessary.
* Backend: use PascalCase for Pydantic schema class names and SQLAlchemy model class names; use snake_case for functions, variables, and database column names.
* Flutter: use PascalCase for classes, widgets, enums, and Riverpod providers/notifiers; use camelCase for local variables and function names.
* Keep code lines below 150 characters where practical.
* Use a clean and simple folder structure.
* Authentication uses JWT from the first version, but with a single implicit role — no admin/viewer/role distinctions in this version.

## Main entities

1. User

   * Id
   * Email
   * PasswordHash
   * CreatedAt

2. Project

   * Id
   * UserId
   * Name
   * Description
   * CreatedAt

3. Asset

   * Id
   * ProjectId
   * Name
   * RepositoryUrl
   * Owner
   * RepositoryName
   * IsActive
   * LastScannedAt
   * CreatedAt

4. ScanResult

   * Id
   * AssetId
   * ComponentCount
   * CriticalVulnerabilityCount
   * StartedAt
   * FinishedAt
   * Status

5. Component

   * Id
   * ScanResultId
   * Name
   * Version
   * Ecosystem
   * Purl
   * License

6. Vulnerability

   * Id
   * ComponentId
   * CveId
   * Severity
   * Description

7. DriftEvent

   * Id
   * AssetId
   * Type (Added, Removed, Changed)
   * ComponentName
   * Details
   * DetectedAt

8. AlertLog

   * Id
   * ProjectId
   * Type
   * Message
   * SentAt

## Database rules

* A Component is scoped to a single ScanResult (each scan stores its own full component snapshot) — components are never overwritten or deleted between scans, so historical snapshots stay intact for drift comparison.
* A Vulnerability must be unique by `ComponentId` and `CveId`.
* Never delete existing ScanResult, Component, or Vulnerability history.
* Drift is computed by diffing the newest ScanResult's components against the immediately preceding ScanResult's components for the same Asset.
* Update `Asset.LastScannedAt` after a successful scan.
* Use Alembic migrations and seed one example user, one project, two assets (public repositories), and two ScanResults per asset (to demonstrate drift out of the box).

## Backend features

1. Auth

   * Register and login endpoints, JWT issued on login.

2. CRUD Project

   * Create, list, detail, update, delete project (scoped to the logged-in user).

3. CRUD Asset

   * Add, edit, delete asset (Git repository) inside a project.
   * Validate and parse the repository URL (`https://github.com/owner/repository` or GitLab equivalent).

4. Manual Scan

   * Endpoint to trigger a scan for one asset. Runs synchronously and returns the result in the same request/response cycle (no background worker).
   * Steps: clone/read dependency manifest → run Syft to generate an SBOM → for each component, query OSV.dev for CVEs → persist a new ScanResult with its Components and Vulnerabilities → diff against the previous ScanResult to produce DriftEvents → if a critical CVE or drift is found, send an email alert and log it.
   * Return a result containing:

     * AssetId
     * ComponentCount
     * CriticalVulnerabilityCount
     * NewComponentCount
     * RemovedComponentCount
     * ChangedComponentCount
     * FinishedAt
     * Message
   * Show a meaningful error if the repository is private, invalid, unavailable, or OSV.dev's rate limit is reached.

5. Dashboard API

   * Return a project summary:

     * TotalAssets
     * TotalComponents
     * CriticalVulnerabilities
     * AssetsWithDrift
     * AssetsNeverScanned
   * Return per-asset risk data:

     * AssetId
     * AssetName
     * ComponentCount
     * CriticalVulnerabilityCount
     * LastScannedAt
     * RiskStatus
   * RiskStatus rules:

     * `CRITICAL`: at least one critical CVE in the latest scan
     * `WARNING`: any non-critical CVE or drift present in the latest scan
     * `HEALTHY`: no known issues, and asset has been scanned at least once
     * `NOT_SCANNED`: asset has never been scanned

6. Alert

   * Send one email when a scan finds a critical CVE or any drift.
   * Log every alert sent to `AlertLog` (no multi-channel config, no deduplication window in this version).

## Mobile app screens (Flutter)

1. Login / Register

   * Simple email + password form with validation.

2. Project List (home)

   * List of the user's projects with a summary badge (healthy/warning/critical count).
   * Button to create a new project.

3. Project Dashboard

   * Summary cards: total assets, total components, critical vulnerabilities, assets with drift.
   * List of assets with risk-status badge and last-scanned time.
   * Button: `Pindai Semua Aset` (scan all assets in the project, sequentially).

4. Asset Management (the feature implemented in full for the P4 assignment)

   * List of assets in a project — 6 required UI states apply here: initial loading, loaded, empty, error+retry, form validation, submit-loading.
   * Form to add a new asset by repository URL, with validation (required, must match GitHub/GitLab URL pattern).
   * Button: `Pindai Sekarang` per asset, disabled while a scan is in flight for that asset.
   * Shows last scanned time and component/CVE count per asset.

5. Scan Result Detail

   * Flat table/list of components found in the latest scan: name, version, license, highest CVE severity.
   * Section listing drift events since the previous scan (added/removed/changed).

6. Alerts

   * List of alerts sent for the project (type, message, sent time) — read-only in this version.

## UI requirements

* Use Indonesian language for all labels, buttons, messages, and validation.
* Use Material 3 widgets, clean and responsive layout, support both light and dark theme.
* Use simple lists, cards, and status badges. Use a confirmation dialog before delete. Every list screen must have an explicit empty state.
* Use status badge colors:

  * Healthy: green
  * Warning: orange/yellow
  * Critical: red
  * Not scanned: grey
* No interactive graph visualization in this version — component relationships are shown as a flat list, not a node graph.

## Required API routes

* `POST /api/auth/register`
* `POST /api/auth/login`
* `GET /api/projects`
* `POST /api/projects`
* `GET /api/projects/:id`
* `PUT /api/projects/:id`
* `DELETE /api/projects/:id`
* `GET /api/projects/:projectId/assets`
* `POST /api/projects/:projectId/assets`
* `PUT /api/assets/:id`
* `DELETE /api/assets/:id`
* `POST /api/assets/:id/scan`
* `GET /api/assets/:id/scan-results`
* `GET /api/assets/:id/scan-results/latest`
* `GET /api/assets/:id/drift-events`
* `GET /api/projects/:projectId/dashboard`
* `GET /api/projects/:projectId/alerts`

## Deliverables

* Complete Flutter app source code and FastAPI backend source code.
* SQLAlchemy models, Alembic migrations, and seed data.
* Docker Compose file for PostgreSQL and the backend.
* `.env.example`.
* README with installation, database migration, seed, backend startup, Flutter app startup (emulator/device), Docker usage, and SMTP/OSV.dev configuration.
* Widget tests covering the 6 required UI states for the Asset Management feature (per the P4 assignment).
* Ensure the application builds successfully and the full flow (add asset → scan → view results → see drift on second scan → receive alert) works end to end with at least one seeded example.

## Project structure

* Use a two-folder monorepo: a Flutter app and a FastAPI backend, communicating over REST.
* Structure:

```text
pulse/
  mobile/
    lib/
      main.dart
      app.dart
      routes/
        app_router.dart
      features/
        auth/
        project/
        asset_management/
          data/
          application/
          presentation/
      widgets/
      models/
      services/
        api_client.dart
    test/
  backend/
    app/
      api/
      core/
      models/
      schemas/
      services/
    alembic/
    tests/
  docs/
    architecture/
    PROPOSAL.md
  docker-compose.yml
  .env.example
```

## API contract requirements

* The backend is Python and the mobile app is Dart, so there is no single shared source file for models — the API contract is defined once via FastAPI's Pydantic schemas and documented through its auto-generated OpenAPI spec at `/docs`.
* Do not hand-duplicate field names/casing between backend Pydantic schemas and Flutter model classes; keep both aligned to the same field names as defined in this document (`AssetId`, `RiskStatus`, etc. at the API boundary, mapped to idiomatic Dart naming inside the app).
* Enums that matter on both sides (`RiskStatus`, `DriftEventType`) must be defined once in `backend/app/schemas` and mirrored as Dart enums in `mobile/lib/models`, kept in sync manually since no codegen step is used in this version.

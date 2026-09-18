Architecture.md: Build a full-stack web application named **Pulse (Continuous Supply Chain Integrity Monitor)**.

## Purpose

Help engineering and security teams monitor the integrity of their software supply chain. The application ingests SBOM (Software Bill of Materials) data from Git repositories, container images, or manual uploads, analyzes each component for multi-dimensional risk (CVE, license, abandonware, dependency confusion), continuously monitors dependency drift between scans, visualizes the dependency graph, and sends alerts when new risks are detected.

## Use this stack

* Backend: Python 3.11+ + FastAPI
* Frontend: Next.js 14 (App Router) + TypeScript + Tailwind CSS + shadcn/ui
* Relational Database: PostgreSQL 16
* Graph Database: Neo4j Community Edition (dependency graph)
* ORM: SQLAlchemy 2.0 + Alembic (migrations)
* Task Queue: Celery + Redis (async scanning, analysis, alerting)
* Scheduler: Celery Beat (periodic re-scans)
* Graph Visualization: Cytoscape.js
* Data Fetching: TanStack Query
* State Management: Zustand
* API style: REST API + WebSocket (live scan/alert updates)
* SBOM Generation: Syft
* Vulnerability Scanning: Grype (or Trivy)
* Vulnerability Data Sources: OSV.dev API, NVD API, CISA KEV feed
* File Storage: MinIO (S3-compatible) or local filesystem for MVP
* Use Docker Compose for PostgreSQL, Neo4j, Redis, MinIO, backend, and frontend
* Use `.env.example` for database URL, Neo4j credentials, SMTP, Telegram/Slack/Discord webhooks, and optional API keys

## Code rules

* Do not add comments unless truly necessary.
* Use PascalCase for Python classes, Pydantic schemas, SQLAlchemy models, and TypeScript types, interfaces, enums, and React components.
* Use snake_case for Python functions, variables, and database column names.
* Use camelCase for TypeScript local variables and function names.
* Keep code lines below 150 characters where practical.
* Use a clean and simple folder structure.
* Authentication uses JWT with role-based access control (Admin, Security Engineer, Developer, Viewer) from the first version — this application is multi-user by design.

## Main entities

1. Organization

   * Id
   * Name
   * CreatedAt

2. User

   * Id
   * OrganizationId
   * Email
   * PasswordHash
   * Role
   * CreatedAt

3. Project

   * Id
   * OrganizationId
   * Name
   * Description
   * CreatedAt

4. Asset

   * Id
   * ProjectId
   * Type (Repository, ContainerImage, Manual)
   * Source
   * CreatedAt

5. Sbom

   * Id
   * AssetId
   * Format (CycloneDx, Spdx)
   * Version
   * FilePath
   * CreatedAt

6. Component

   * Id
   * Name
   * Version
   * Ecosystem
   * Purl
   * License
   * Metadata

7. Vulnerability

   * Id
   * ComponentId
   * CveId
   * Severity
   * Cvss
   * Description

8. DriftEvent

   * Id
   * AssetId
   * Type (Added, Removed, Changed)
   * Details
   * DetectedAt

9. Alert

   * Id
   * ProjectId
   * Type
   * Severity
   * Message
   * Channel
   * SentAt

10. AlertConfig

    * Id
    * ProjectId
    * ChannelType
    * ConfigJson

11. ScanJob

    * Id
    * AssetId
    * Status
    * StartedAt
    * FinishedAt
    * ResultSummary

**Graph database (Neo4j) — mirrors relational data for traversal:**

* Nodes: `Component {Name, Version, Ecosystem, Purl}`, `Asset {Id, Name, Type}`, `Vulnerability {CveId, Severity}`
* Relationships: `(Asset)-[:CONTAINS]->(Component)`, `(Component)-[:DEPENDS_ON]->(Component)`, `(Component)-[:HAS_VULN]->(Vulnerability)`

## Database rules

* A Component must be unique by `Purl` (package URL) plus `Version`.
* A Vulnerability must be unique by `ComponentId` and `CveId`.
* Never delete existing Sbom, Component, or Vulnerability history during a re-scan.
* Every re-scan creates a new `Sbom` record and a new `ScanJob`; previous scans remain for audit and drift comparison.
* Drift is computed by diffing the latest `Sbom` against the immediately preceding `Sbom` for the same `Asset`.
* Update `LastSyncedAt`-equivalent (`ScanJob.FinishedAt`) after every successful scan.
* Use Alembic migrations and seed one example organization, one project, three assets (one repository, one container image, one manual SBOM upload), and sample components with a mix of safe and vulnerable versions.

## Backend features

1. CRUD Organization & User

   * Register, list, update, delete users. Assign role per user.

2. CRUD Project

   * Create, list, detail, update, delete project.

3. CRUD Asset

   * Add, edit, delete asset (repository, container image, or manual SBOM) inside a project.
   * Validate and parse GitHub/GitLab repository URLs and container image references.

4. SBOM Ingestion

   * Endpoint to upload a CycloneDX or SPDX file manually.
   * Endpoint to trigger a Git-based scan (auto-detect `package.json`, `requirements.txt`, `go.mod`, `pom.xml`, `Cargo.toml`).
   * Endpoint to trigger a container image scan via Syft.
   * Public API endpoint for CI/CD pipelines to push an SBOM directly.

5. Manual & Scheduled Scan Trigger

   * Endpoint to trigger a re-scan for one asset.
   * Endpoint to trigger a re-scan for all active assets in a project.
   * Celery Beat runs scheduled re-scans per the asset's configured interval (1h / 6h / daily / weekly).
   * Return a result containing:

     * AssetId
     * ComponentCount
     * NewComponentCount
     * RemovedComponentCount
     * ChangedComponentCount
     * DriftDetected
     * LastScannedAt
     * Message

6. Risk Analysis Engine

   * For every component, query OSV.dev and NVD for CVEs.
   * Detect risky licenses (for example GPL in a commercial context).
   * Flag abandonware (no release in the last 24 months, via npm/PyPI/Maven registry metadata).
   * Compute dependency confusion risk using Levenshtein distance against popular package names.
   * Compute a blast radius score: number of assets that contain a given vulnerable component.
   * If `GITHUB_TOKEN` is available, use it as a Bearer token for GitHub API requests; otherwise fall back to unauthenticated rate limits.
   * Show a meaningful error if a repository is private, invalid, unavailable, or an external API rate limit is reached.

7. Drift Detection

   * Diff the newest Sbom against the previous one for the same asset.
   * Classify each change as Added, Removed, or Changed.
   * Persist every drift event; never overwrite drift history.

8. Alert Engine

   * Configure channels per project: Email (SMTP), Telegram Bot, Slack Webhook, Discord Webhook.
   * Trigger on: new critical CVE, drift detected, risky license found, abandonware found.
   * Deduplicate similar alerts within a configurable time window before sending.

9. Dashboard & Reporting API

   * Return a project summary:

     * TotalAssets
     * TotalComponents
     * TotalVulnerabilities
     * CriticalVulnerabilities
     * AssetsWithDrift
     * AssetsNeverScanned
   * Return per-asset risk data:

     * AssetId
     * AssetName
     * ComponentCount
     * VulnerabilityCount
     * HighestSeverity
     * LastScannedAt
     * RiskStatus
   * RiskStatus rules:

     * `CRITICAL`: at least one unresolved critical CVE
     * `WARNING`: risky license, abandonware, or non-critical CVE present
     * `HEALTHY`: no known issues
   * Generate a PDF compliance report per project.
   * Export SBOM as CycloneDX or SPDX.
   * Export findings as SARIF.
   * Export raw data as CSV/JSON.

## Frontend pages

1. Dashboard

   * Project selector.
   * Summary cards: total assets, components, vulnerabilities, critical vulnerabilities, assets with drift.
   * Table showing each asset, component count, vulnerability count, highest severity, last scanned time, and risk status.
   * Button: `Scan All Assets`.
   * Show loading state, successful scan message, and error message.
   * Dashboard reads only from the database when opened. It must not trigger a scan automatically.

2. Project Management

   * List projects.
   * Form to create and edit projects.
   * Button to open project dashboard.

3. Asset Management

   * List assets in a selected project.
   * Form to add and edit repository URLs, container image references, or manual SBOM uploads.
   * Button: `Scan Now`.
   * Show last scan time and component count.

4. Dependency Graph

   * Interactive Cytoscape.js graph: node = component, edge = "depends on".
   * Node color by risk level (green/yellow/red).
   * Click a node to open a detail panel: version, CVEs, license, affected assets.
   * Filter by risk level or ecosystem.
   * Blast radius view: select a CVE and highlight every affected asset.

5. Component Detail

   * Show component information, license, and maintenance metadata.
   * Show CVE list with severity and description.
   * Show every asset that contains this component.

6. Alerts & Notifications

   * List recent alerts with severity and channel.
   * Form to configure alert channels (SMTP, Telegram, Slack, Discord) per project.

## UI requirements

* Use Indonesian language for all labels, buttons, messages, and validation.
* Create a clean, responsive dashboard with dark mode support.
* Use simple tables, cards, badges, forms, confirmation dialog before delete, and empty states.
* Use status badge colors:

  * Healthy: green
  * Warning: yellow
  * Critical: red
* Charts (trend of vulnerabilities over time) are optional and out of scope for the first version.

## Required API routes

* `GET /api/projects`
* `POST /api/projects`
* `GET /api/projects/:Id`
* `PUT /api/projects/:Id`
* `DELETE /api/projects/:Id`
* `GET /api/projects/:ProjectId/assets`
* `POST /api/projects/:ProjectId/assets`
* `PUT /api/assets/:Id`
* `DELETE /api/assets/:Id`
* `POST /api/assets/:Id/sbom/upload`
* `GET /api/assets/:Id/sbom/latest`
* `GET /api/assets/:Id/sbom/history`
* `POST /api/assets/:Id/scan`
* `POST /api/projects/:ProjectId/scan`
* `GET /api/assets/:Id/components`
* `GET /api/components/:Id`
* `GET /api/components/:Id/vulnerabilities`
* `GET /api/components/:Id/blast-radius`
* `GET /api/projects/:ProjectId/graph`
* `GET /api/projects/:ProjectId/drift-events`
* `GET /api/assets/:Id/drift-events`
* `GET /api/projects/:ProjectId/alerts`
* `POST /api/projects/:ProjectId/alert-configs`
* `PUT /api/alert-configs/:Id`
* `GET /api/projects/:ProjectId/dashboard`
* `GET /api/projects/:ProjectId/report/pdf`
* `GET /api/projects/:ProjectId/report/sarif`
* `GET /api/assets/:Id/sbom/export?format=cyclonedx`
* `WS /ws/projects/:ProjectId/live`

## Deliverables

* Complete frontend and backend source code.
* SQLAlchemy models, Alembic migration, and seed data.
* Docker Compose file for PostgreSQL, Neo4j, Redis, MinIO, backend, and frontend.
* `.env.example`.
* README with installation, database migration, seed, frontend/backend startup, Docker usage, and external API/token configuration.
* Ensure the application builds successfully and all basic CRUD plus manual scan/drift detection/alerting work end to end.

## Project structure

* Use a monorepo with a Python backend and a TypeScript frontend.
* Structure:

```text
pulse/
  backend/
    app/
      api/
      core/
      models/
      schemas/
      services/
      workers/
    alembic/
    tests/
  frontend/
    src/
      app/
      components/
      lib/
      hooks/
    public/
  docs/
    architecture/
  docker-compose.yml
  .env.example
```

## Shared contract requirements

* Because the backend is Python and the frontend is TypeScript, domain models cannot be shared as a single source file the way a TypeScript-only monorepo would.
* FastAPI's auto-generated OpenAPI schema is the single source of truth for the API contract.
* Generate a typed frontend client from the OpenAPI schema (for example with `openapi-typescript`) into `frontend/src/lib/api-types.ts` instead of hand-writing duplicate interfaces.
* Do not hand-duplicate request/response shapes between `backend/app/schemas` (Pydantic) and the frontend; regenerate the typed client whenever the backend schema changes.
* SQLAlchemy models remain backend-only; the API layer always maps them to Pydantic response schemas before returning data.
* Enums that matter on both sides (`RiskStatus`, `DriftEventType`, `AlertChannelType`, `AssetType`, `SbomFormat`) must be defined once in `backend/app/schemas` and exposed through the generated OpenAPI client, not redefined by hand in the frontend.

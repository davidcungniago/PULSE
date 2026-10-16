# Pulse — Agent Rules

Pulse is a mobile companion for monitoring software supply chain risk. The Flutter app lives at the repo root (lib/, test/). The FastAPI backend lives in /backend.
Read README.md, docs/architecture/Architecture.md, and docs/USER_STORIES.md before starting any task.

## Workflow

- One feature per task. Do not build anything the current prompt did not ask for.
- Follow Brief -> Plan -> Build -> Verify. In Plan, write no code and wait for my approval.
- Never run git commit, git push, git reset, or git checkout. I commit manually. At the end of a task, propose how to split the changes into commits, with messages.
- Run commands for real (flutter analyze, flutter test, pytest, the app itself) and paste the actual output. If you cannot run something in your environment, say so explicitly. Never report success without having run it.
- Fix root causes. If a test fails, determine whether the code or the test is wrong, and tell me which before changing anything.

## Code rules

- Format with dart format and ruff format. Never write long one-line widget trees.
- No comments unless truly necessary.
- All user-facing strings are in Indonesian.
- Dart: PascalCase types, camelCase members. Python: PascalCase classes, snake_case functions and columns.
- API JSON keys are PascalCase (Id, ProjectId, RepositoryUrl, ...). Pydantic uses an alias generator; Flutter models map them in fromJson/toJson.
- Error responses: {"Message": "<Indonesian text>"} with a correct HTTP status code.

## Architecture rules

- Flutter: Riverpod; layers widget -> notifier -> repository -> service. No business logic in widgets.
- Backend: routers stay thin. Business rules live in pure functions under app/services/ so they can be unit-tested without a database or network.
- External HTTP calls (GitHub raw, OSV.dev, SMTP) go through injectable clients. Tests must never touch the network.
- Never overwrite or delete scan history.
- Default database is SQLite (DATABASE_URL in .env). PostgreSQL via docker compose must also work. Tests use in-memory SQLite.
- Secrets come only from environment variables. Keep .env.example updated.
- Enable CORS on the backend so Flutter web (Chrome) can call it.
- Never read, print, or commit .env or any secrets.

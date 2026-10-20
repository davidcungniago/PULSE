# Paket prompt — Pulse MVP (final)

File ini berisi seluruh prompt AI yang dipakai untuk menuntaskan MVP, berurutan. Prompt ditulis dalam bahasa Inggris karena agent bekerja lebih akurat dengan itu. Catatan review di bawah tiap tahap ditulis sendiri setelah membaca diff.

## Aturan pakai

1. Satu tahap, satu sesi baru. Konteks terbawa lewat `AGENTS.md`, `docs/USER_STORIES.md` dan `docs/DESIGN.md`.
2. Mode: `Plan` untuk prompt Plan dan review. `Build` untuk Build dan Verify. Jangan pindah ke Build sebelum kamu membaca dan menyetujui plan.
3. Satu model per tahap. Model kedua hanya untuk review silang (Template T3).
4. Agent tidak pernah commit. Kamu yang commit setelah membaca diff dan menjalankan test sendiri.
5. Jangan lanjut ke tahap berikutnya sebelum `flutter analyze`, `flutter test`, dan `pytest` hijau di mesinmu.

Tambahkan dua baris ini ke akhir `AGENTS.md`:

```
- Read docs/DESIGN.md before any Flutter UI work. It is the design spec. Do not invent colors, spacing or copy outside it.
- The prompts used for this project are listed in docs/PROMPTS.md. Do not edit that file.
```

## Urutan tahap

| # | Tahap | Isi | User story |
|---|---|---|---|
| 1 | D1 | Fondasi desain Pulse Monitor | — |
| 2 | F2b | UI pemindaian dan daftar risiko | US-2, US-3 |
| 3 | F3a, F3b | Deteksi drift (backend, lalu Flutter) | US-4 |
| 4 | F4a, F4b | Dashboard dan Pusat pemantauan | US-5 |
| 5 | F5a, F5b | Autentikasi | US-7 |
| 6 | F6a, F6b | Alert email | US-6 |
| 7 | H1 | Penyempurnaan dan regresi | semua |
| 8 | H2 | HowToRun.md dan checklist_mvp.md | semua |
| 9 | H3 | Siap-review | semua |

Garis potong kalau waktu mepet: kerjakan sampai tahap 4 dulu, lalu H1 sampai H3. Auth dan alert (tahap 5 dan 6) kalau tidak sempat dipindahkan resmi ke "Fitur yang Tidak Dikerjakan" di README.

---

## Template

### T1 — Build

```
The plan is approved (with these changes: <your changes, or "none">).
Implement exactly the approved plan for <FEATURE>. Production code only: do not write tests yet. Do not add anything outside the plan. If something extra seems necessary, stop and ask.
Follow AGENTS.md and docs/DESIGN.md. When done: list every file created or modified, run the formatters and linters (dart format and flutter analyze; ruff check and ruff format for the backend), and paste the real output. Do not commit.
```

### T2 — Verify

```
Verify <FEATURE> against <US-x> in docs/USER_STORIES.md.

1. For each acceptance criterion, tell me how to check it manually (exact steps and expected result). If you can run something yourself, do it and show the real output.
2. Write meaningful tests for the business rules of this feature, including invalid and boundary cases from the acceptance criteria, not only the happy path.
   - Backend: pytest in backend/tests, offline only (fake HTTP clients, fake mailer, in-memory SQLite).
   - Flutter: flutter test with fake repositories, and animate: false for every pulse widget.
   - Use descriptive test names.
3. Run the FULL suites: pytest from backend/ with its .venv, and flutter analyze plus flutter test from the repo root. Paste the real summary lines. If something fails, say whether the code or the test is wrong before changing anything. Never delete or skip a test to get green.
4. Give me a table: AC id | verified by (test name or manual step) | result. Mark anything not proven as NOT VERIFIED.
5. Propose two commits: (a) production code, (b) tests, with the file list and conventional commit messages. Do not commit.
```

### T3 — Review silang (model kedua, mode Plan)

```
Review only. Do not edit any file and do not commit.
Read the git diff of the current uncommitted changes and docs/USER_STORIES.md for <US-x>.
Report: (1) acceptance criteria that are not actually satisfied, with file and line; (2) bugs and unhandled edge cases (invalid input, empty data, failures); (3) business rules that have no meaningful test; (4) anything that violates AGENTS.md or docs/DESIGN.md. Rank findings by severity. Be specific and do not pad the list.
```

---

## D1 — Fondasi desain

Mode `Plan`. Setelah disetujui: T1, lalu T2 plus tambahan di bawah.

```
FEATURE D1: Design foundation ("Pulse Monitor"). Read AGENTS.md and docs/DESIGN.md completely first. docs/DESIGN.md is the spec.

Goal: build the shared design system and restyle the existing screens WITHOUT changing behavior or API calls. No new packages. No new features.

BRIEF
1. Theme: lib/theme/ with color tokens for dark (default) and light, ThemeData for both, and text styles. Remove hard-coded colors from existing widgets.
2. Pure logic, all unit-tested:
   - buildWaveform(...) exactly as specified in docs/DESIGN.md (contract, parameter table, determinism, ectopic beats, flat for notScanned).
   - a stable FNV-1a 32-bit hash of a string id, used as the seed.
   - contrastRatio(Color, Color) and badge-background compositing (tint over surface).
3. Widgets: PulseTrace (CustomPainter, static and sweep modes, animate flag, reduced-motion aware, RepaintBoundary), PulseBanner, VitalTile, SeverityBadge with a NEW Severity enum (critical, high, medium, low, unknown, safe) separate from RiskStatus, a restyled StatusBadge for RiskStatus, ConstrainedPage (max width 560, centered), restyled EmptyState and ErrorState, and ProjectMonitorCard and AssetCard shells.
4. Restyle existing screens structurally only: wrap them in ConstrainedPage, replace the oversized summary grid on the dashboard with PulseBanner plus three VitalTile, and use the new badges. Screens that still use mock data keep it for now.
5. Login and register hero: a static healthy PulseTrace.
6. All existing tests must stay green. Update them only where widget structure changed.

Plan only. Do NOT write code. Give: files to create or modify, class and function signatures, step order, how each rule in docs/DESIGN.md will be verified, risks, and at most 5 open questions, each with your recommended answer. Then wait for my approval.
```

Tambahan untuk T2 (sisipkan di langkah 2):

```
Required tests for D1:
- buildWaveform: determinism (same inputs, identical points); for the same seed the peak amplitude order critical > warning > healthy; notScanned is flat with isFlat true; hasDrift adds ectopicXs only when not flat; every y stays within [0, height]; the seed hash gives the same value for the same id and differs for different ids.
- contrastRatio and badges: every Severity and RiskStatus badge text/background pair is at least 4.5:1 in BOTH themes.
- Widgets (animate: false): PulseTrace exposes the Semantics label; SeverityBadge shows the right Indonesian label for every severity; ConstrainedPage limits width to 560.
Manual check: run in Edge with the device toolbar at 390x844, in both themes, and report what you could not verify.
```

**Catatan review saya (isi sendiri):**
- Yang saya review dan ubah:
- Cara verifikasi:
- Mengapa:
- Commit:

---

## F2b — UI pemindaian dan daftar risiko (US-2, US-3)

Mode `Build` untuk langkah 1 (laporan saja), lalu T2.

```
Check-first task for F2b (the Flutter side of the scan feature). Follow AGENTS.md, docs/DESIGN.md and docs/USER_STORIES.md (US-2 and US-3). The backend scan endpoints are done and tested.

Step 1 (report only, no edits): list what already exists in the Flutter app for scanning: the "Pindai Sekarang" button, the scan service calls, the scan result screen, how severity is shown, and the timeouts. For each of US-2.1, US-2.3, US-2.4, US-2.5 and US-3.1 to US-3.5, say how it behaves today. Be explicit about what is missing or still mocked.

Step 2 (build only what is missing), using these decisions:
- Use the design system: SeverityBadge with the Severity enum (including "Tidak diketahui"), AssetCard, EmptyState, ErrorState, ConstrainedPage. No new colors.
- JSON is PascalCase. Parse GET /api/assets/{id}/scan-results/latest: a JSON null body means "never scanned" (empty state). Components arrive already sorted by the backend; keep that order.
- "Pindai Sekarang" per asset: disabled with a spinner while in flight, second tap ignored. The scan call timeout is 90 seconds; other calls stay at 10 seconds. While a scan runs, the PulseTrace of that asset or screen shows the sweep (animate honoring reduced motion).
- On success: refresh the asset list and show a SnackBar with a "Lihat hasil" action. No auto-navigation. Tapping an asset opens the result screen.
- Result screen: loading, empty state when null (an invitation to scan), error with "Coba Lagi", and the component list (name@version in monospace, license, severity badge). Show the skipped-entry count from the scan response. No drift section yet (F3).
- Show 422 and 502 server messages through the existing api_error_mapper.
- Remove any leftover mock data on this screen.

Step 3: T2 requirements apply (fake repositories, no network): widget tests for US-2.1 (opening screens never calls startScan), US-2.3 (spinner, disabled, second tap ignored), US-2.4 (list refreshes after success), US-2.5 (error plus "Coba Lagi" retries), US-3.1 to US-3.5 (row content, order, safe state, empty state, SeverityBadge used).

Run dart format, flutter analyze and the FULL flutter test. Paste the real output. Do not commit. Propose two commits: feat and test.
```

**Catatan review saya (isi sendiri):**
- Yang saya review dan ubah:
- Cara verifikasi:
- Mengapa:
- Commit:

---

## F3a — Drift, backend (US-4)

Mode `Plan`. Setelah disetujui: T1, T2.

```
FEATURE F3a: Drift detection, backend (US-4 in docs/USER_STORIES.md). Follow AGENTS.md. Existing conventions: layout backend/app/{api,core,db,models,schemas,services}, UUID string ids, PascalCase JSON, errors as {"Message": "..."}, user-scoped queries, offline tests.

BRIEF
- Pure function detect_drift(previous, current) in app/services/drift.py.
  - Component identity is (ecosystem, name). Versions are compared by string equality only.
  - Types: Added, Removed, Changed. Changed details: "Versi berubah dari X ke Y."
  - previous is None for the first scan of an asset: return no events (never "everything added").
  - Deterministic order: Added, Removed, Changed, then by name.
- DriftEvent model: id, asset_id, scan_result_id (the scan that produced it), type, component_name, ecosystem, details, detected_at. Alembic migration, reviewed by hand. Update docs/architecture/Architecture.md for ScanResultId and Ecosystem.
- Scan flow: after building the new scan, load the previous successful scan's components, compute drift, and persist the events in the SAME transaction as the scan. A failed scan stores neither.
- POST /api/assets/{id}/scan response adds IsFirstScan, NewComponentCount, RemovedComponentCount and ChangedComponentCount.
- GET /api/assets/{id}/scan-results/latest adds DriftEvents: the events produced by that scan.
- GET /api/assets/{id}/drift-events: all events for the asset, newest first. Another user's asset returns 404.
- Never delete or modify existing events or scans.
- Out of scope: dashboard, alerts, auth, Flutter.

Plan only. Do NOT write code. Give: files, API contract, step order, how each AC of US-4 will be verified, risks, and at most 5 open questions with recommended answers. Then wait for my approval.
```

Tambahan untuk T2: tes murni `detect_drift` (first scan, tidak berubah, Added, Removed, Changed, gabungan, ekosistem berbeda dengan nama sama, urutan), dan tes API dengan fetcher palsu: scan kedua setelah manifest berubah, scan pertama tanpa drift, scan ulang tanpa perubahan tanpa event, event tersimpan permanen, scan gagal tidak menyimpan event.

## F3b — Drift, Flutter

Mode `Plan`, lalu T1 dan T2.

```
FEATURE F3b: Drift in Flutter (US-4). Follow AGENTS.md, docs/DESIGN.md and docs/USER_STORIES.md. The backend (F3a) is done.

BRIEF
- Models: DriftEvent (PascalCase JSON), add the drift counts to the scan response model and DriftEvents to the latest scan model.
- Result screen: a drift section listing events with type label (Ditambahkan, Dihapus, Diubah), component name and details; the drift color from docs/DESIGN.md. Empty states: first scan "Pemindaian pertama. Belum ada pembanding." and later scans without changes "Tidak ada perubahan sejak pemindaian sebelumnya."
- After a scan, the SnackBar mentions the drift count when it is greater than zero.
- PulseTrace on the result screen gets hasDrift = events not empty.
- Out of scope: dashboard.

Plan only. Do NOT write code. Give files, steps, how each AC of US-4 is verified in the UI, risks, and at most 5 open questions with recommended answers. Then wait for my approval.
```

**Catatan review saya (isi sendiri) untuk F3a dan F3b:**
- Yang saya review dan ubah:
- Cara verifikasi:
- Mengapa:
- Commit:

---

## F4a — Dashboard, backend (US-5)

```
FEATURE F4a: Project dashboard, backend (US-5 in docs/USER_STORIES.md). Follow AGENTS.md and the existing backend conventions.

BRIEF
- Pure function compute_risk_status(has_been_scanned, critical_count, non_critical_count, drift_event_count) -> RiskStatus in app/services/risk_status.py, exactly as US-5 AC2 (CRITICAL, WARNING, HEALTHY, NOT_SCANNED). "Non-critical" counts every non-CRITICAL vulnerability, including UNKNOWN severity.
- Pure function aggregate_project_status(statuses) -> RiskStatus: the worst among scanned assets (CRITICAL > WARNING > HEALTHY); NOT_SCANNED when no asset was scanned or the project has no assets.
- GET /api/projects/{projectId}/dashboard, computed from the database from each asset's LATEST scan:
  - Summary: TotalAssets, TotalComponents, CriticalVulnerabilities, AssetsWithDrift (latest scan has drift events), AssetsNeverScanned.
  - Assets: AssetId, AssetName, ComponentCount, CriticalVulnerabilityCount, VulnerabilityCount, DriftEventCount, LastScannedAt, RiskStatus.
  - Opening this endpoint never triggers a scan.
- GET /api/projects adds AssetCount and RiskStatus to every project.
- Another user's project returns 404. Prefer grouped queries over per-asset queries where it is simple.
- Out of scope: Flutter, alerts, auth.

Plan only. Do NOT write code. Give files, API contract, steps, AC verification, risks, and at most 5 open questions with recommended answers. Then wait for my approval.
```

Tambahan untuk T2: tes murni `compute_risk_status` (semua cabang dan batas, UNKNOWN dihitung non-kritis), `aggregate_project_status`, dan tes API (belum dipindai, kritis, peringatan karena CVE non-kritis, peringatan karena drift saja, sehat, project kosong, ringkasan menghitung hanya scan terbaru, dashboard tidak memanggil fetcher, project orang lain 404).

## F4b — Dashboard dan Pusat pemantauan, Flutter

```
FEATURE F4b: Dashboard and "Pusat pemantauan" in Flutter (US-5). Follow AGENTS.md, docs/DESIGN.md and docs/USER_STORIES.md. The backend (F4a) is done.

BRIEF
- Project list screen becomes "Pusat pemantauan": ProjectMonitorCard with a mini STATIC PulseTrace (seed from the project id) and the project RiskStatus from the API. Loading, empty ("Belum ada project. Buat project pertama untuk mulai memantau."), error with "Coba Lagi".
- Dashboard screen reads GET /api/projects/{id}/dashboard: PulseBanner (status label and sub line from the data, for example "2 CVE kritis di 1 aset"), three VitalTile (Komponen, CVE kritis, Drift), the asset list with StatusBadge and relative time. Remove ALL mock numbers.
- A pure function formatRelativeTime(now, then) in Indonesian ("baru saja", "5 menit lalu", "2 jam lalu", "3 hari lalu", else a date), unit-tested at its boundaries. Use it instead of a bare clock time.
- "Pindai Semua Aset": scans active assets one by one with progress ("Memindai 2 dari 3"). A failure on one asset never stops the others. At the end show a per-asset summary (success or the server message). The button is disabled while running and a second tap is ignored. The banner trace sweeps while running (animate honoring reduced motion). Opening the dashboard never scans.
- Out of scope: auth, alerts.

Plan only. Do NOT write code. Give files, steps, how each AC of US-5 is verified, risks, and at most 5 open questions with recommended answers. Then wait for my approval.
```

Tambahan untuk T2: tes widget dengan repository palsu (loading, data, empty, error + retry, tombol "Pindai Semua Aset" berurutan dan tidak berhenti saat satu gagal, tidak ada scan saat dashboard dibuka, tombol nonaktif saat berjalan), dan tes murni `formatRelativeTime`.

**Catatan review saya (isi sendiri) untuk F4a dan F4b:**
- Yang saya review dan ubah:
- Cara verifikasi:
- Mengapa:
- Commit:

---

## F5a — Autentikasi, backend (US-7)

```
FEATURE F5a: Authentication, backend (US-7 in docs/USER_STORIES.md). Follow AGENTS.md and the existing backend conventions.

BRIEF
- Endpoints: POST /api/auth/register, POST /api/auth/login (JSON body, not a form), GET /api/auth/me. Register returns 201 with Id and Email. Login returns AccessToken and TokenType.
- Validation: email format; password minimum 6 and maximum 72 characters; email stored lowercase; duplicate email returns 409. Error messages in Indonesian as {"Message": "..."}.
- Pure functions in app/services/security.py: hash_password and verify_password (use the `bcrypt` package directly, a malformed hash returns False), create_access_token and decode_access_token (PyJWT, HS256, expiry, clear distinction between an expired and an invalid token).
- Replace the temporary get_current_user (demo user) in api/deps.py with real JWT (Authorization: Bearer; HTTPBearer(auto_error=False) so errors use the {"Message"} shape). Missing, invalid or expired token returns 401. Every endpoint except health, register and login requires a token. All existing user scoping stays.
- Settings: JWT_SECRET, JWT_EXPIRE_MINUTES, APP_ENV (default "dev"). If JWT_SECRET is empty: in dev use a fixed dev-only secret and log a warning; when APP_ENV=prod refuse to start. Update .env.example.
- The seeded demo user keeps working (bcrypt hash). Report its email and password so they can be documented.
- Update every existing backend test that relied on the temporary demo user (use a login fixture).
- Out of scope: Flutter, alerts.

Plan only. Do NOT write code. Give files, API contract, steps, AC verification for US-7, risks, and at most 5 open questions with recommended answers. Then wait for my approval.
```

Tambahan untuk T2: tes murni `security.py` (hash dan verify, hash salah, token valid, kedaluwarsa, rusak), tes API (register valid, duplikat 409, kata sandi pendek dan terlalu panjang 422, email tidak valid, login salah 401, endpoint terproteksi tanpa token 401, project/aset/scan milik user lain 404, `me`).

## F5b — Autentikasi, Flutter

```
FEATURE F5b: Authentication in Flutter (US-7). Follow AGENTS.md, docs/DESIGN.md and docs/USER_STORIES.md. The backend (F5a) is done.

BRIEF
- Real AuthService against the API. Store the token with shared_preferences (already a dependency). Note the limitation (browser storage) in the plan.
- An auth state provider that loads the token on startup, with a loading state while it does. go_router redirect from that state: unauthenticated users go to /login; authenticated users skip login and register.
- Dio interceptor: attach the Bearer token. On 401 (except from login and register) clear the token, go to /login and show "Sesi berakhir, silakan masuk kembali."
- Login and register screens: validation (email format, password at least 6 characters), submit loading with the button disabled and a second tap ignored, server errors shown inline (409, 401, 422 via api_error_mapper). Register then logs in automatically.
- Profile screen shows the email from GET /api/auth/me and a working logout.
- Out of scope: password reset, social login.

Plan only. Do NOT write code. Give files, steps, AC verification, risks, and at most 5 open questions with recommended answers. Then wait for my approval.
```

Tambahan untuk T2: tes widget validasi form login dan register, tombol nonaktif saat kirim, redirect guard (tanpa token ke /login, dengan token ke /projects), interceptor 401 menghapus token dan mengarahkan ke login.

**Catatan review saya (isi sendiri) untuk F5a dan F5b:**
- Yang saya review dan ubah:
- Cara verifikasi:
- Mengapa:
- Commit:

---

## F6a — Alert email, backend (US-6)

```
FEATURE F6a: Email alerts, backend (US-6 in docs/USER_STORIES.md). Follow AGENTS.md and the existing backend conventions.

BRIEF
- Pure function should_alert(previous_critical_cve_ids, current_critical_cve_ids, drift_event_count) -> decision with reasons. Alert when the current scan has a critical CVE id that is not in the previous scan (a first scan counts as "no previous"), or when drift_event_count > 0. Otherwise no alert.
- Pure function build_alert_message(asset_name, new_critical_cve_ids, drift_items) -> (subject, body), in Indonesian, listing at most 10 CVE ids then "dan N lainnya", with drift counts. No secrets in the content.
- EmailSender protocol. SmtpEmailSender reads SMTP_HOST, SMTP_PORT, SMTP_USERNAME, SMTP_PASSWORD, SMTP_FROM, SMTP_USE_TLS from the environment. If SMTP is not configured, sending raises a clear error. The recipient is the project owner's email.
- AlertLog model: id, project_id, asset_id (nullable), asset_name, type, message, status (Sent or Failed), error_detail (nullable), sent_at. Alembic migration reviewed by hand.
- After a scan is committed, evaluate should_alert. If it fires, send the email and write an AlertLog. Any sender failure or missing configuration is caught: the scan still returns 200 and the log is Failed. No alert and no log when nothing qualifies.
- POST /scan response adds AlertStatus (Sent, Failed or null).
- GET /api/projects/{projectId}/alerts: newest first. Another user's project returns 404.
- docker-compose: add an optional `mail` profile with Mailpit (SMTP 1025, UI 8025) and document SMTP_USE_TLS=false for it. Validate with `docker compose config` only and do not claim it was run. Update .env.example.
- Out of scope: Flutter, deduplication windows, multiple channels.

Plan only. Do NOT write code. Give files, API contract, steps, AC verification for US-6, risks, and at most 5 open questions with recommended answers. Then wait for my approval.
```

Tambahan untuk T2: tes murni `should_alert` (CVE kritis baru, CVE kritis yang sama muncul lagi tidak memicu alert, scan pertama dengan kritis, drift saja, tidak ada apa-apa), `build_alert_message` (batas 10 CVE), dan tes API dengan pengirim palsu (terkirim, pengirim gagal tetap 200 dan log Failed, SMTP tidak terkonfigurasi log Failed, tidak ada temuan tanpa log).

## F6b — Alert email, Flutter

```
FEATURE F6b: Alerts in Flutter (US-6). Follow AGENTS.md, docs/DESIGN.md and docs/USER_STORIES.md. The backend (F6a) is done.

BRIEF
- Alerts screen reads GET /api/projects/{id}/alerts: each item shows the type icon, message, a status badge (Terkirim or Gagal) and relative time (reuse formatRelativeTime). Loading, empty ("Belum ada alert. Alert muncul saat pemindaian menemukan CVE kritis baru atau drift."), error with "Coba Lagi".
- After a scan, if AlertStatus is Sent, the SnackBar says an alert email was sent; if Failed, say it could not be sent (Indonesian, no exclamation marks).
- The bell icon in the dashboard app bar opens the alerts screen.

Plan only. Do NOT write code. Give files, steps, AC verification, risks, and at most 5 open questions with recommended answers. Then wait for my approval.
```

**Catatan review saya (isi sendiri) untuk F6a dan F6b:**
- Yang saya review dan ubah:
- Cara verifikasi:
- Mengapa:
- Commit:

---

## H1 — Penyempurnaan dan regresi

Mode `Build`. Satu sesi, tanpa fitur baru.

```
Final hardening pass. No new features. Follow AGENTS.md, docs/DESIGN.md and docs/USER_STORIES.md.

1. Walk through every screen and flow. Each must handle loading, empty data, invalid input and failure with a clear Indonesian message and a retry where it makes sense. List every gap you find first, then fix them.
2. Search lib/ and test/ for leftovers: mock data, Future.delayed used as a fake service, the temporary "Mode Demo (Debug)" toggle, dead code, unused imports. Remove them.
3. Visual QA in both themes (dark and light) at 390x844 and at desktop width: contrast, tap targets of at least 48dp, nothing overflowing, no raw English or internal error text visible to the user.
4. Backend: confirm error shapes are {"Message": "..."} for 401, 404, 409, 422, 502 and 500, with no stack traces; CORS accepts only localhost origins; secrets come only from the environment; .gitignore covers .env, *.db, .venv and caches.
5. Fix README.md so every command and path matches the real repo. Check every link resolves.
6. Full regression: ruff check and ruff format --check, the FULL pytest suite from backend/ with its .venv, then flutter analyze and the FULL flutter test from the repo root. Paste the real output. If anything fails, say whether the code or the test is wrong before changing it. Never delete or skip a test to get green.
7. Do not commit. Propose commits with conventional messages.
```

## H2 — HowToRun.md dan checklist_mvp.md

```
Create two documents in the repo root, in Indonesian.

1. HowToRun.md
   - Prerequisites (Python 3.11 or newer, Flutter, Git; Docker optional).
   - Backend: run every command from the backend/ folder (create .venv, activate it, pip install -r requirements-dev.txt, copy .env.example to .env and which values to set, alembic upgrade head, python -m app.seed, uvicorn app.main:app --reload).
   - Flutter: from the repo root, flutter pub get, flutter run -d edge (or chrome), and how to pass --dart-define=API_BASE_URL.
   - The seeded demo account (email and password).
   - Running all tests (pytest and flutter test).
   - Demo setup: create your own public GitHub repo with a requirements.txt or package.json that pins an old vulnerable version, add it as an asset, scan it, edit the manifest on GitHub, wait about 5 minutes because GitHub raw content is cached, and scan again to see drift.
   - Optional: docker compose and the mail profile (state clearly that these were only validated with `docker compose config`).
   - Troubleshooting: wrong folder, "Data awal belum dibuat" (run the seed), CORS, port already in use, Dart "Out of memory" (close apps, flutter clean, restart).
   Every command must be copy-pastable and you must have verified it.

2. checklist_mvp.md
   A table with the columns: Fitur | User story | Acceptance criteria | Nama test atau langkah manual | Status pengujian.
   Cover US-1 to US-7 and every acceptance criterion. Mark PASSED only for what you ran and saw pass in this session. Anything not done or not proven is BELUM. At the bottom, paste the real pytest and flutter test summary lines with today's date.

Do not commit.
```

## H3 — Siap-review

```
Prepare the MVP for review. Do not add features. Do not commit.

1. MVP definition: in at most 10 lines, state what the MVP is (the features and user stories actually implemented) and what is intentionally NOT included. Check it against README.md and docs/USER_STORIES.md and flag any mismatch.
2. Run it: follow HowToRun.md exactly as written, from a fresh .venv. Report each command and its real result. If a step in HowToRun.md is wrong, fix the document and tell me what you changed.
3. Tests: list every test file (path plus the business rule it covers). Then run ALL tests (backend pytest and flutter test) and paste the real summary lines. Everything must pass. If something fails, tell me whether the code or the test is wrong before touching it. Never delete or skip a test.
4. Walk the main flow end to end (register, login, create project, add asset, scan, risk list, second scan, drift, dashboard, alert). Tell me which steps you verified yourself and which I must verify manually.
5. Update checklist_mvp.md: mark PASSED only for what you ran and saw pass in this session, with the date and the real test summary lines.
```

---

## Konvensi commit

| Tahap | Commit kode | Commit test |
|---|---|---|
| D1 | `feat(app): add Pulse Monitor design system` | `test(app): add waveform, contrast and design widget tests` |
| F2b | `feat(app): wire scan and component risk list` | `test(app): add scan flow widget tests` |
| F3a | `feat(backend): add drift detection` | `test(backend): add drift detection tests` |
| F3b | `feat(app): show drift events on scan result` | `test(app): add drift UI tests` |
| F4a | `feat(backend): add project dashboard and risk status` | `test(backend): add risk status and dashboard tests` |
| F4b | `feat(app): add dashboard and monitoring center` | `test(app): add dashboard tests` |
| F5a | `feat(backend): add JWT authentication` | `test(backend): add auth tests` |
| F5b | `feat(app): add login, register and auth guard` | `test(app): add auth flow tests` |
| F6a | `feat(backend): add email alerts` | `test(backend): add alert rule and flow tests` |
| F6b | `feat(app): add alerts screen` | `test(app): add alerts tests` |
| H1 | `chore: hardening and regression fixes` | — |
| H2 | `docs: add HowToRun and MVP checklist` | — |

## Skrip demo (demo.mp4, 4 sampai 5 menit)

1. Tunjukkan `pytest` dan `flutter test` lulus semua.
2. Jalankan backend dan Flutter. Register, lalu login.
3. Buat project dan tambah aset valid. Tunjukkan validasi: URL palsu dan duplikat.
4. Pindai repo demo. Tunjukkan garis denyut menyapu, lalu daftar komponen terurut menurut severity.
5. Ubah manifest di GitHub, pindai ulang, dan tunjukkan drift (denyut anomali biru).
6. Dashboard: status berubah, lalu "Pindai Semua Aset".
7. Email alert masuk (Mailpit atau mailbox). Kalau SMTP belum dikonfigurasi, tunjukkan log "Gagal".
8. Satu kasus error dengan "Coba Lagi" (matikan backend atau pakai repo yang tidak ada).
9. Tampilkan `git log --oneline`.

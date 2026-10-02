# P4 — Dokumentasi Fitur: Asset Management

Fitur yang diimplementasikan penuh untuk memenuhi requirement P4: state management (Riverpod), form dengan validasi, dan enam kondisi UI wajib. Fitur ini menampilkan daftar aset (repository Git) dalam sebuah project, dan memungkinkan pengguna menambahkan aset baru lewat form dengan validasi URL.

## 1. Ringkasan Implementasi

- **State management:** Riverpod (`flutter_riverpod`)
- **Pemisahan tanggung jawab:**
  - `presentation/` — widget & screen, tidak ada logika bisnis
  - `application/` — notifier (`AssetListNotifier`, `AddAssetNotifier`), menyimpan state
  - `data/` — `AssetRepository`, komunikasi dengan service/API
- **Lokasi kode:** `lib/features/asset_management/`
- **Lokasi test:** `test/features/asset_management/asset_list_screen_test.dart`

## 2. Prompt AI yang Digunakan

Seluruh fitur ini dibangun menggunakan Codex (agentic coding assistant), dengan beberapa iterasi prompt berikut. 

### Prompt 1 — Implementasi awal fitur Asset Management

![alt text](image.png)
![alt text](assets/images/image-1.png)
![alt text](assets/images/image-2.png)
Build the initial Flutter project structure and UI prototype for an app named Pulse, a mobile companion for developers/security engineers to monitor software supply chain risk (SBOM/CVE scanning).
prototype pass : screens can use mock/ hardened data for now, no real API writing is requiredyet except for a thin service layer with placeholder implementations.

Use Flutter 3.x, Material 3, Riverpod (flutter_riverpod) for future state management wiring, go_router for routing, and dio for the HTTP client dependency (even if unused by real calls yet).

Follow this exact folder structure:

lib/
  main.dart
  app.dart
  routes/
    app_router.dart
  screens/
    login_screen.dart
    register_screen.dart
    project_list_screen.dart
    project_dashboard_screen.dart
    asset_management_screen.dart
    scan_result_detail_screen.dart
    alerts_screen.dart
    profile_screen.dart
  widgets/
    primary_button.dart
    app_text_field.dart
    status_badge.dart
    risk_summary_card.dart
    empty_state.dart
    error_state.dart
    loading_indicator.dart
  models/
    user_model.dart
    project_model.dart
    asset_model.dart
    scan_result_model.dart
    component_model.dart
    vulnerability_model.dart
    drift_event_model.dart
    alert_log_model.dart
  services/
    api_client.dart
    auth_service.dart
    project_service.dart
    asset_service.dart
    scan_service.dart
    dashboard_service.dart
    alert_service.dart

Screens to build (as UI prototypes with mock data, in Indonesian for all labels/buttons/messages):
1. login_screen.dart â€” email + password fields (using AppTextField), a PrimaryButton "Masuk", and a link to register.
2. register_screen.dart â€” same pattern for account creation.
3. project_list_screen.dart â€” list of projects as cards, each showing name and a StatusBadge summarizing risk (healthy/warning/critical count), a floating action button to create a project. Include an EmptyState for when there are no projects.
4. project_dashboard_screen.dart â€” summary cards (RiskSummaryCard) for total assets, total components, critical vulnerabilities, assets with drift, plus a list of assets with a StatusBadge and last-scanned time, and a "Pindai Semua Aset" button.
5. asset_management_screen.dart â€” list of assets with an add-asset form entry point. Leave the deep implementation of this screen's real logic for a separate task â€” for now build the static UI shell only (list, empty state, a floating action button to open an add form) so it can be replaced/extended later.
6. scan_result_detail_screen.dart â€” flat table/list of components (name, version, license, highest CVE severity) and a section listing drift events (added/removed/changed) using mock data.
7. alerts_screen.dart â€” read-only list of past alerts (type, message, sent time).
8. profile_screen.dart â€” shows logged-in user email, a logout button.

Reusable widgets:
- primary_button.dart: a button with label, onPressed, and an optional isLoading flag that shows a small spinner and disables tapping while true.
- app_text_field.dart: a text field wrapper with label, controller, optional validator, and error text display.
- status_badge.dart: a colored pill widget taking a status enum (healthy/warning/critical/notScanned) and rendering the correct color (green/orange/red/grey) and Indonesian label.
- risk_summary_card.dart: a card showing a number, a label, and an icon â€” used for dashboard summary stats.
- empty_state.dart: icon + message + optional action button, reusable across any list screen.
- error_state.dart: icon + error message + a "Coba Lagi" retry button that takes an onRetry callback.
- loading_indicator.dart: a centered CircularProgressIndicator wrapper.

Models (plain Dart classes with fromJson/toJson, matching this field naming): User(id, email), Project(id, name, description, createdAt), Asset(id, projectId, name, repositoryUrl, owner, repositoryName, isActive, lastScannedAt), ScanResult(id, assetId, componentCount, criticalVulnerabilityCount, startedAt, finishedAt, status), Component(id, name, version, ecosystem, license), Vulnerability(id, componentId, cveId, severity, description), DriftEvent(id, assetId, type, componentName, details, detectedAt), AlertLog(id, projectId, type, message, sentAt).

Services: create one class per service (AuthService, ProjectService, AssetService, ScanService, DashboardService, AlertService), each with method stubs matching this backend API (see below), currently returning mock/hardcoded data via Future.delayed to simulate network latency. ApiClient wraps a dio instance with a configurable baseUrl.

Backend API these services will eventually call:
POST /api/auth/register, POST /api/auth/login, GET/POST /api/projects, GET/PUT/DELETE /api/projects/:id, GET/POST /api/projects/:projectId/assets, PUT/DELETE /api/assets/:id, POST /api/assets/:id/scan, GET /api/assets/:id/scan-results, GET /api/assets/:id/scan-results/latest, GET /api/assets/:id/drift-events, GET /api/projects/:projectId/dashboard, GET /api/projects/:projectId/alerts.

Routing (app_router.dart, go_router): /login, /register, /projects (project list, initial route after login), /projects/:id (dashboard), /projects/:id/assets, /projects/:id/scan-results/:assetId, /projects/:id/alerts, /profile. Use a simple redirect stub for auth-gating (can be a hardcoded bool for now, to be replaced by real auth state later).

Requirements:
- No business logic beyond simple mock data inside screens â€” screens only build UI and call services.
- Do not add comments unless something is genuinely non-obvious.
- Keep widgets small and composed from the reusable widgets listed above rather than duplicating UI code.
- After generating the code, list every file you created and briefly explain how routing connects the screens, so I can review it before I extend it further.

### Prompt 2 — Perbaikan bug compile (missing parenthesis)

![alt text](assets/images/image-3.png)
The Flutter test suite fails to compile with these errors:

1. lib/features/asset_management/presentation/widgets/add_asset_form.dart:27:20
   Error: Can't find ')' to match '('.
   The build method's return statement has a missing closing parenthesis â€” SafeArea(, Padding(, and Column( are opened but not all are closed before the trailing semicolon.

2. test/features/asset_management/asset_list_screen_test.dart:73 and :77
   Error: Undefined name 'projectId'.
   The test references a bare `projectId` identifier that is never declared in the file (used both in `AssetListScreen(projectId: projectId)` and inside `_asset()`).

Fix both:
1. Reformat add_asset_form.dart's build method with proper multi-line formatting (run it through `dart format` conventions â€” do not keep it as one dense line) and fix the missing closing parenthesis so it compiles.
2. In asset_list_screen_test.dart, declare a top-level constant, e.g. `const projectId = 'project-1';`, near the top of the file, and make sure every asset/test fixture that references a project id uses this same constant consistently.

### Prompt 3 — Perbaikan test yang gagal (2 dari 6 kondisi)
![alt text](assets/images/image-4.png)
The Flutter widget test suite now compiles, but 2 of 6 tests fail:

1. Test: "menampilkan daftar aset saat data tersedia" (line ~24)
   Failure: expected to find exactly one widget with text "pulse/api", found 0.
   Investigate lib/features/asset_management/presentation/widgets/asset_list_item.dart and see how it actually renders the owner/repositoryName fields. Either:
   - the widget renders them as separate Text widgets (e.g. owner and repositoryName in different widgets, or with a different separator than "/"), in which case fix the test's expectation to match the real rendered output, or
   - the widget is missing this display entirely, in which case add it.
   Decide which is correct based on what asset_list_item.dart is supposed to show per the original spec (owner/repo shown together, human-readable), then fix whichever side (widget or test) is wrong so the intent is actually satisfied, not just so the test passes.

2. Test: "menonaktifkan submit dan menampilkan spinner saat aset dikirim" (line ~66)
   Failure: StateError: Bad state: Too many elements (from Iterable.single) â€” the finder used at that line matches more than one widget when the test expects exactly one.
   Find the finder used at test/features/asset_management/asset_list_screen_test.dart:66 and make it specific

### Prompt 4 — Perbaikan StatusBadge, tombol Pindai Semua Aset, dan debug toggle untuk demo state

Three fixes needed in the Pulse Flutter app:

1. lib/screens/scan_result_detail_screen.dart currently renders its own custom-styled status badges for severity (visible as washed-out pink/green pills), instead of reusing the existing lib/widgets/status_badge.dart widget used everywhere else in the app. Refactor this screen to use StatusBadge consistently, mapping severity/status values to the same enum StatusBadge already accepts elsewhere.

2. The "Pindai Semua Aset" button on project_dashboard_screen.dart currently does nothing when tapped. Wire it to at least: show a loading state on the button while the mock scan call runs (reuse PrimaryButton's isLoading pattern), and show a SnackBar on completion, e.g. "Pemindaian selesai (mode simulasi)." It doesn't need a real backend call yet â€” just visible feedback instead of silence.

3. I need to manually verify and screenshot 4 UI states on the Asset Management screen that don't naturally occur with the current mock data: initial loading, empty state, error state with retry, and the submitting/disabled-button state during add-asset submit. Add a temporary, clearly-marked debug affordance â€” for example a small dropdown or button row visible only in debug mode (kDebugMode) on asset_list_screen.dart â€” that lets me force the AssetListNotifier into each of these states on demand (loading / empty list / error / normal data), so I can screenshot each one without editing code every time. Make it obvious this is a debug-only tool (e.g. a labeled row "Mode Demo (Debug)") so I remember to remove it before final submission.

After these three fixes, run flutter analyze and flutter test and show me the full output confirming nothing is broken
## 3. Hasil Widget Test
![alt text](assets/images/image-5.png)
Dijalankan dengan:

```bash
flutter test test/features/asset_management/asset_list_screen_test.dart
```

Screenshot hasil akhir (semua PASS):

![alt text](assets/images/image-6.png)

## 4. Bukti Enam Kondisi UI

| # | Kondisi | Screenshot | Catatan |
|---|---|---|---|
| 1 | Initial loading | ![alt text](assets/images/image-8.png)| Ditampilkan saat pertama kali membuka layar Asset Management, sebelum data dimuat. |
| 2 | Data berhasil dimuat | ![alt text](assets/images/image-9.png) | Daftar aset (API Utama, Aplikasi Web) tampil dengan badge status. |
| 3 | Empty state | ![alt text](assets/images/image-11.png) | Ditampilkan saat project belum memiliki aset. |
| 4 | Error state + tombol retry | ![alt text](assets/images/image-12.png) | Muncul saat pengambilan data gagal; tombol "Coba Lagi" memicu pengambilan ulang. |
| 5 | Validasi input form |![alt text](assets/images/image-10.png)| Field URL repositori kosong/tidak valid menampilkan pesan error dan menonaktifkan tombol submit. |
| 6 | Loading saat submit (tombol nonaktif) | ![alt text](assets/images/image-13.png) | Tombol "Tambah Aset" menampilkan spinner dan tidak bisa ditekan ulang selama proses submit berlangsung. |

*(Kondisi 1, 3, 4, dan 6 diambil menggunakan debug toggle "Mode Demo (Debug)" yang sengaja ditambahkan sementara di `asset_list_screen.dart` untuk memaksa state tertentu — dihapus sebelum submission final.)*

## 5. Bagian yang Saya Review/Perbaiki Sendiri

- **Tombol submit saat loading:** memverifikasi bahwa `onPressed` benar-benar bernilai `null` saat `status == AddAssetStatus.submitting` di `add_asset_notifier.dart` (bukan sekadar menampilkan spinner secara visual) — ini yang benar-benar mencegah double-tap, bukan `isLoading` saja.
- **Regex validasi URL:** memeriksa `validateRepositoryUrl` di `add_asset_notifier.dart` untuk memastikan polanya benar-benar terikat ke domain `github.com`/`gitlab.com` (anchored), bukan sekadar mengandung kata "github"/"gitlab" di mana saja dalam string.
- **Reset error state saat retry:** memeriksa `asset_list_notifier.dart` untuk memastikan `state` di-set ke `AsyncValue.loading()` sebelum fetch ulang dijalankan, sehingga UI benar-benar kembali ke kondisi loading saat tombol retry ditekan, bukan diam di kondisi error lama.
- **Bug compile ditemukan manual:** dua kali menemukan `Error: Can't find ')' to match '('` saat menjalankan `flutter test`/`flutter run` secara nyata (di `add_asset_form.dart`, lalu di `login_screen.dart`/`register_screen.dart`) — kode yang dihasilkan Codex sempat diklaim "siap" padahal belum pernah benar-benar dikompilasi/dijalankan. Ini dikonfirmasi dan diperbaiki dengan menjalankan `flutter test` dan `flutter run` sendiri, bukan hanya percaya laporan dari AI.
- **Bug test yang gagal:** dua dari enam test sempat gagal (`find.text("pulse/api")` tidak ketemu, dan finder widget mengembalikan "Too many elements"). Diperiksa apakah akar masalah ada di widget atau di ekspektasi test sebelum meminta perbaikan, bukan langsung menganggap test yang salah.
- **StatusBadge tidak konsisten:** ditemukan bahwa `scan_result_detail_screen.dart` tidak memakai widget `StatusBadge` yang sudah ada (warnanya beda dari layar lain) — menunjukkan requirement "reusable widget" sempat tidak diikuti sepenuhnya oleh kode yang dihasilkan AI.

## 6. Catatan Tambahan

- Seluruh percakapan dengan Codex dan output terminal asli didokumentasikan sebagai bukti bahwa setiap klaim "berhasil"/"semua test lulus" diverifikasi ulang secara manual, sesuai requirement tanggung jawab atas kode yang dikumpulkan.
- Backend belum terhubung nyata (masih menggunakan mock data via service layer) — sesuai scope MVP yang didefinisikan di `docs/architecture/Architecture.md`.

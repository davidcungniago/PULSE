# Hasil uji security dan verifikasi fresh clone

Tanggal: 27 Oktober 2026. Lingkungan: Windows, Python 3.13, Flutter 3.47.5 / Dart 3.13.4. Ini pemeriksaan security terarah dan regresi aplikasi, bukan sertifikasi aman atau pentest menyeluruh.

## Identitas sumber yang diuji

Fresh clone nyata dari `https://github.com/davidcungniago/PULSE.git` ke `.verification/fresh-20261027`, commit `196e5d3d7b6e8a8b95a71426c5963e3b16ef7a4e`. Working tree clone bersih sebelum instalasi. Virtualenv Python dibuat baru dan dependency diunduh; Flutter menjalankan `pub get` dari clone. Cache unduhan SDK/package masih dapat digunakan, tetapi virtualenv, database, dan hasil build lama tidak disalin.

Baseline remote lulus 91 tes backend dan 89 tes Flutter. Setelah itu, sembilan file kandidat backend/deployment disalin secara eksplisit ke clone: `app/main.py`, `services/http_client.py`, `services/repository_url.py`, `services/safe_logging.py`, `tests/test_security_regression.py` (semuanya di bawah `backend/`), `backend/Dockerfile`, `backend/.dockerignore`, `backend/.env.example`, dan `docker-compose.yml`. Kandidat lulus 116 tes backend. Tidak ada perubahan kode Dart pada tugas ini; build web berasal dari kode Flutter clone yang telah lulus tes.

Perubahan kandidat belum di-commit/push. Karena itu hasil kandidat **bukan klaim bahwa branch remote sudah berisi perbaikan**. README, laporan, dan workflow baru disiapkan di working tree utama. Ulangi CI pada SHA PR sesudah perubahan di-push.

## Temuan dan catatan perubahan

| Temuan | Dampak | Perubahan | Bukti/batas |
|---|---|---|---|
| Dockerfile `COPY . .` tanpa ignore context | File `.env`, database, atau virtualenv lokal berpotensi masuk image | Allowlist `.dockerignore`, COPY eksplisit kode/migrasi, user container non-root | Review konfigurasi; build image terhalang daemon Docker |
| Compose tidak meneruskan JWT_SECRET | Registrasi/login tidak dapat berjalan pada container baru | Secret wajib dari environment; tanpa default bawaan | `compose config --quiet` berhasil dengan secret sementara; tes missing-secret menghasilkan 503 |
| Password PostgreSQL statis, port DB publik | Credential bersama dan exposure yang tidak perlu | Password environment, port DB tidak dipublikasikan; API bind localhost | Konfigurasi diperiksa, PostgreSQL runtime belum diuji |
| SQLite berada pada writable layer container | Data berisiko hilang saat container diganti | Named volume `/data`, migrasi saat startup | Migrasi SQLite lokal berhasil; persistensi volume container belum diuji |
| Origin Compose wildcard | Browser dari origin tak diinginkan dapat membaca respons jika memiliki token | Origin demo eksplisit, regex kosong pada Compose | Tes allowed origin / denied origin lulus; CORS bukan pengganti autentikasi |
| URL menerima segmen `.`/`..` | Normalisasi path dapat mengubah target repository | Tolak dot-segment dan gunakan fullmatch nama | Kasus traversal/host palsu/internal ditolak |
| HTTP client mengikuti redirect otomatis | Target redirect dapat keluar dari host awal | Nonaktifkan redirect; respons 3xx ditangani sebagai kegagalan upstream | MockTransport membuktikan hanya satu request, tidak mengikuti redirect localhost |
| Access log/exception mentah dapat mengandung informasi sensitif | Query, kredensial, atau detail internal berpotensi terekspos | Middleware log metadata allowlist; pesan 500 generik; `--no-access-log` pada deployment | Tes menyisipkan nilai sintetis di query/header/body/exception; nilainya tidak muncul dalam log/response |

Menonaktifkan redirect berarti repository yang hanya tersedia melalui redirect perlu diperbarui ke URL canonical. Riwayat scan tidak dihapus atau ditimpa. Runtime smoke scan repository GitHub publik tetap berhasil setelah perubahan.

## Cakupan security otomatis

`backend/tests/test_security_regression.py` menambah 25 kasus: delapan URL traversal/host, redirect HTTP, CORS, sanitasi error/log, tiga belas rute resource lintas akun/tanpa token, dan konfigurasi JWT kosong. Semua menggunakan SQLite in-memory/fake transport, tanpa GitHub/OSV/SMTP nyata. Tes autentikasi sebelumnya juga mencakup hash password, password salah, JWT kedaluwarsa, signature salah, algoritme JWT salah, duplikasi akun, dan preservasi riwayat scan.

Jalankan ulang dari `backend/`:

```powershell
.venv/Scripts/python.exe -m pytest -q -p no:cacheprovider
```

## Output aktual

Berikut petikan keluaran terminal (baris progres berulang dan unduhan dependency tidak disertakan):

```text
git clone https://github.com/davidcungniago/PULSE.git .verification/fresh-20261027
Cloning into '.verification/fresh-20261027'...

git rev-parse HEAD
196e5d3d7b6e8a8b95a71426c5963e3b16ef7a4e

flutter analyze
Analyzing fresh-20261027...
No issues found! (ran in 6.1s)

flutter test --no-pub --concurrency=1 --reporter expanded
00:15 +89: All tests passed!

pytest -q -p no:cacheprovider (baseline remote)
91 passed, 1 warning in 3.70s

ruff format --check app tests scripts alembic (kandidat)
70 files already formatted

ruff check app tests scripts (kandidat)
All checks passed!

pytest -q -p no:cacheprovider (kandidat di clone)
116 passed, 1 warning in 10.01s

dart format --output=none --set-exit-if-changed lib test
Formatted 101 files (0 changed) in 0.17 seconds.

flutter build web --no-pub --no-wasm-dry-run --dart-define=API_BASE_URL=http://127.0.0.1:8765
Compiling lib\main.dart for the Web... 27.6s
√ Built build\web

alembic upgrade head (database kosong)
INFO  [alembic.runtime.migration] Context impl SQLiteImpl.
INFO  [alembic.runtime.migration] Will assume non-transactional DDL.
INFO  [alembic.runtime.migration] Running upgrade  -> 9e1e22ab1535, initial schema
INFO  [alembic.runtime.migration] Running upgrade 9e1e22ab1535 -> c1a2b3d4e5f6, scan results, components and vulnerabilities
INFO  [alembic.runtime.migration] Running upgrade c1a2b3d4e5f6 -> d2e3f4a5b6c7

python -m scripts.smoke_api
PASS: register -> POST project -> POST asset -> GET asset -> dashboard -> database session baru
Database demo tersimpan; tidak ada token atau kata sandi yang dicetak.
```

Peringatan pytest: `StarletteDeprecationWarning: Using httpx with starlette.testclient is deprecated; install httpx2 instead.` Build web memberi peringatan font `packages/cupertino_icons/CupertinoIcons`; build tetap exit 0. Tidak dilakukan upgrade dependency massal untuk menyembunyikan peringatan.

Percobaan Flutter suite pertama di clone terhenti pada dua tes dengan `Out of memory` dari runtime Dart, bukan assertion. Setelah instalasi dependency selesai, seluruh suite dijalankan ulang dengan satu worker dan lulus 89 tes tanpa mengubah kode/test Flutter. Catatan ini tidak dihapus dari laporan.

## Run dan deployment demo yang benar-benar diuji

API kandidat berjalan pada `http://127.0.0.1:8765` menggunakan SQLite baru `backend/release-verification.db` di folder clone dan kunci JWT acak khusus demo. Web release dilayani dengan `python -m http.server 8766 --bind 127.0.0.1 --directory build/web`, lalu dibuka di browser pada `http://127.0.0.1:8766`.

Alur nyata: token sesi lama ditolak 401 dan diarahkan ke login; register akun baru; daftar proyek kosong; buat proyek; daftar aset kosong; URL invalid menonaktifkan submit dan menampilkan error inline; URL GitHub valid tersimpan; tombol scan menghasilkan HTTP 200 dan waktu sinkronisasi terbarui; reload halaman tetap memuat proyek dari API. Script smoke juga membaca aset melalui sesi database baru. Server ini hanya demo lokal, bukan hosting publik atau bukti deployment Android/iOS.

Contoh log **aktual** dari proses tersebut, tanpa payload atau credential:

```json
{"Event":"http_request","RequestId":"e946a6f4daee4ac89276db9b400d61b2","Method":"GET","Route":"/api/projects","Status":401,"DurationMs":2}
{"Event":"http_request","RequestId":"32386ccefea64a28b00e29f23c352a03","Method":"POST","Route":"/api/projects/{projectId}/assets","Status":201,"DurationMs":14}
{"Event":"http_request","RequestId":"5d3fbf87a5284e54837178a22bdfbd5f","Method":"POST","Route":"/api/assets/{assetId}/scan","Status":200,"DurationMs":3177}
```

Panduan penyebab/error dan tindakan perbaikan ada di [SAFE-LOGS.md](SAFE-LOGS.md).

Paket frontend demo: `.verification/pulse-web-demo-20261027.zip`, 14.085.013 byte, SHA256 `82E1168F76AC0EAE40B9B18B81E6FB7380AB1307EE7ACB538FD4CB9C7BE654F4`. Paket hanya berisi `build/web`, tanpa backend/database/secret; API_BASE_URL tertanam `http://127.0.0.1:8765`. Layani paket di localhost:8766 dan jalankan backend pada port 8765 dengan origin tersebut diizinkan. Untuk URL lain, build ulang. Artifact ini diabaikan Git, tidak di-push.

## Yang belum selesai atau belum terbukti

- `docker compose -p pulse-verify-20261027 config --quiet` exit 0. Build image benar-benar dicoba, tetapi gagal karena daemon Docker Desktop tidak tersedia, bahkan setelah aplikasi Docker Desktop dicoba dijalankan. Output: `failed to connect to the docker API at npipe:////./pipe/dockerDesktopLinuxEngine ... The system cannot find the file specified.` Karena itu **Docker build, runtime container, dan PostgreSQL belum dinyatakan lulus**. Jalankan ulang panduan README setelah Docker Desktop sehat.
- Workflow PR dan template dibuat, tetapi belum dijalankan oleh GitHub. Tidak dibuat commit, push, atau PR aktual. Pemilik perlu commit/push branch lalu memilih base/head PR; setelah itu lampirkan URL/check CI nyata.
- Tidak ada deployment publik, pengujian Android/iOS, kamera fisik, atau pengiriman SMTP nyata pada tugas ini.
- Belum ada rate limit login/register/scan, MFA, revokasi JWT server-side, atau kebijakan password kuat di luar kontrak MVP minimal 6 karakter. Jangan membuka demo ke internet tanpa kontrol tambahan.
- Dependency Python masih menggunakan rentang versi, dan GitHub Actions menggunakan tag versi action, belum SHA penuh. Build mendatang bisa memperoleh dependency berbeda. Tidak dilakukan audit CVE seluruh dependency pada tugas ini; lulus tes bukan bukti semua dependency bebas kerentanan.
- Validasi URL dan penolakan redirect mengurangi permukaan SSRF, tetapi bukan pengganti egress firewall/allowlist jaringan. URL upstream dari environment tetap menjadi tanggung jawab operator.
- Tidak dilakukan pemindaian historis Git terhadap secret. `.gitignore` tidak menghapus file yang sudah terlacak; snapshot browser historis yang telah terlacak tidak dihapus pada tugas ini.

## Usulan pemisahan commit (manual oleh pemilik)

1. `fix(security): constrain repository fetches and sanitize request logs`
2. `fix(deploy): isolate secrets and persist demo database`
3. `ci: verify pull requests and publish local web demo artifact`
4. `docs: document fresh clone security evidence and safe troubleshooting`

Referensi konfigurasi: [Docker build context dan dockerignore](https://docs.docker.com/build/concepts/context/), [GitHub workflow syntax dan permissions](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax).

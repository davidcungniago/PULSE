# AI Log — Pulse MVP

Catatan proses per fitur dengan alur Brief, Plan, Build, Verify, Commit.

Pembagian pengisian:
- "Apa yang dikerjakan AI Agent" boleh diisi dari output agent.
- "Apa yang saya review dan ubah", "Cara verifikasi", dan "Mengapa perubahan diperlukan" ditulis sendiri berdasarkan review nyata terhadap diff. Ini bagian yang akan ditanyakan saat demo.

---

## F1a - Backend (US-1)

- **Brief:** F1a = backend saja (langkah 1-8 rencana). Membangun backend FastAPI di `/backend`: model SQLAlchemy 2.0 (User, Project, Asset), migrasi awal Alembic, dan seed idempoten (satu user demo ber-hash bcrypt, satu project "Platform Pembayaran", dua aset: express dan lodash). Endpoint hanya yang dibutuhkan UI saat ini: health check, `GET/POST /api/projects`, `GET/POST /api/projects/{projectId}/assets` (body POST aset hanya `RepositoryUrl`; Name diturunkan dari nama repo). Validasi URL repository sebagai fungsi murni `app/services/repository_url.py`: https saja, host tepat `github.com`/`gitlab.com`, tepat `owner/repo`, akhiran `.git` dan tanda miring di akhir diabaikan, query/fragment/port/userinfo dan input kosong ditolak, duplikat dalam satu project mengembalikan 409 (case-insensitive + jaring `IntegrityError`). Semua key JSON PascalCase via alias generator Pydantic; error `{"Message": ...}` berbahasa Indonesia; exception tak tertangani menjadi 500 tanpa stack trace. `get_current_user` sementara mengembalikan user demo dan seluruh query di-scope `user_id` agar F5 cukup menukar dependency. CORS diaktifkan, `.env.example` (SQLite default), `Dockerfile`, dan `docker-compose.yml` (profil postgres opsional). Flutter tidak disentuh.
- **Apa yang dikerjakan AI Agent:** Membuat seluruh isi `backend/`: `app/core/config.py`, `app/db/{base,session}.py`, `app/models/{user,project,asset}.py`, `app/schemas/{base,user,project,asset}.py` (alias `to_pascal`, `populate_by_name=True`), `app/services/{repository_url,asset_service,project_service}.py`, `app/api/{deps,health,projects,assets}.py`, `app/main.py` (CORS + handler error), `app/seed.py`, `alembic/` (env.py memakai settings, migrasi awal `9e1e22ab1535` hasil autogenerate lalu direview manual), `tests/` (39 test), `requirements.txt`, `requirements-dev.txt`, `pyproject.toml`, `.env.example`, `Dockerfile`, `.gitignore`, dan `docker-compose.yml` di root. ID memakai UUID4 string; unique constraint `(project_id, repository_url)`; FK `ondelete=CASCADE`. `main.py` tidak memanggil `create_all` (hanya test yang memakainya). `ruff check` + `ruff format` bersih, `pytest` 39 lulus, dan `alembic upgrade head` di file SQLite baru berhasil. `docker compose` **hanya divalidasi dengan `docker compose config` (profil default dan `--profile postgres`) dan tidak pernah dijalankan**.
- **Apa yang saya review dan ubah:**
- **Cara verifikasi:**
- **Mengapa perubahan diperlukan:**
- **Commit:** `hash` — pesan

---

## F2 — Pemindaian manual dan daftar risiko komponen (US-2, US-3)

- **Brief:**
- **Apa yang dikerjakan AI Agent:**
- **Apa yang saya review dan ubah:**
- **Cara verifikasi:**
- **Mengapa perubahan diperlukan:**
- **Commit:** `hash` — pesan

---

## F3 — Deteksi drift (US-4)

- **Brief:**
- **Apa yang dikerjakan AI Agent:**
- **Apa yang saya review dan ubah:**
- **Cara verifikasi:**
- **Mengapa perubahan diperlukan:**
- **Commit:** `hash` — pesan

---

## F4 — Dashboard ringkasan risiko (US-5)

- **Brief:**
- **Apa yang dikerjakan AI Agent:**
- **Apa yang saya review dan ubah:**
- **Cara verifikasi:**
- **Mengapa perubahan diperlukan:**
- **Commit:** `hash` — pesan

---

## F5 — Autentikasi (US-7)

- **Brief:**
- **Apa yang dikerjakan AI Agent:**
- **Apa yang saya review dan ubah:**
- **Cara verifikasi:**
- **Mengapa perubahan diperlukan:**
- **Commit:** `hash` — pesan

---

## F6 — Alert email (US-6)

- **Brief:**
- **Apa yang dikerjakan AI Agent:**
- **Apa yang saya review dan ubah:**
- **Cara verifikasi:**
- **Mengapa perubahan diperlukan:**
- **Commit:** `hash` — pesan

---

## Penyempurnaan akhir (error handling, regresi, dokumentasi)

- **Apa yang dikerjakan AI Agent:**
- **Apa yang saya review dan ubah:**
- **Cara verifikasi:**
- **Mengapa perubahan diperlukan:**
- **Commit:** `hash` — pesan

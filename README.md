# 🔍 Pulse

### Continuous Supply Chain Integrity Monitor — Mobile Companion

**Aplikasi mobile pendamping bagi developer dan security engineer untuk memantau risiko rantai pasok perangkat lunak (SBOM & CVE) kapan pun, dari genggaman.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B.svg)](https://flutter.dev/)
[![Python](https://img.shields.io/badge/Python-3.11%2B-blue.svg)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.110-009688.svg)](https://fastapi.tiangolo.com/)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED.svg)](https://www.docker.com/)

---

## 📖 Daftar Isi

- [Deskripsi Masalah](#-deskripsi-masalah)
- [Profil Target Pengguna](#-profil-target-pengguna)
- [Manfaat Aplikasi](#-manfaat-aplikasi)
- [Fitur Inti (MVP)](#-fitur-inti-mvp)
- [Fitur yang Tidak Dikerjakan](#-fitur-yang-tidak-dikerjakan)
- [Kriteria Keberhasilan](#-kriteria-keberhasilan)
- [Arsitektur](#-arsitektur)
- [Struktur Repository](#-struktur-repository)
- [Tech Stack](#-tech-stack)
- [Memulai](#-memulai)
- [Cara Pakai](#-cara-pakai)
- [Lisensi](#-lisensi)
- [Kontak](#-kontak)

---

## 🧩 Deskripsi Masalah

Serangan siber modern semakin sering menyasar **rantai pasok perangkat lunak (software supply chain)**, bukan aplikasi secara langsung. Insiden seperti SolarWinds (2020), Log4Shell (2021), event-stream (2018), dan XZ Utils (2024) menunjukkan pola yang sama: sebuah komponen/dependency yang dipercaya disusupi, dan organisasi baru sadar setelah dampaknya meluas.

Masalah intinya:

- Developer dan security engineer sering **tidak tahu secara real-time** apakah ada CVE kritis baru yang mempengaruhi proyek mereka, karena mereka harus membuka dashboard/tool secara manual di laptop.
- Ketika ada **dependensi baru yang muncul tanpa tercatat** (potensi supply chain attack) atau CVE kritis dipublikasikan, tidak ada cara cepat untuk mengetahuinya saat sedang tidak di depan komputer.
- Tools SBOM/CVE yang ada (Syft, Grype, Snyk, Dependabot) semuanya berbasis web/CLI — tidak ada cara ringan untuk memantau status keamanan proyek dari HP saat bepergian, di sela rapat, atau di luar jam kerja.

## 👤 Profil Target Pengguna

**Persona utama: Developer / Security Engineer sebagai "on-the-go monitor"**

- Sudah punya alat utama (dashboard web/CI-CD) untuk kerja detail sehari-hari.
- Butuh **companion app di HP** untuk cek cepat: "apakah project saya aman hari ini?", tanpa perlu membuka laptop.
- Ingin memicu scan manual dan melihat notifikasi/alert penting langsung dari genggaman, bukan melakukan analisis mendalam di mobile.
- Terbiasa dengan UI mobile modern: list, card, badge status, form sederhana — bukan visualisasi kompleks (graf interaktif, dashboard multi-panel).

Pulse versi mobile **tidak** menyasar CISO/auditor yang butuh laporan kepatuhan mendalam (PDF/SARIF) sebagai pengguna utama — itu tetap relevan untuk versi web/dashboard di masa depan, tapi bukan fokus rilis pertama ini.

## 💡 Manfaat Aplikasi

- **Visibilitas cepat**: developer bisa tahu status risiko semua project dalam hitungan detik, dari HP.
- **Deteksi dini tanpa harus standby di laptop**: alert dikirim begitu ada CVE kritis baru atau drift dependensi mencurigakan.
- **Kontrol manual, bukan otomatis membabi buta**: scan hanya berjalan saat pengguna menekan tombol, sehingga pengguna tetap punya kendali penuh dan biaya API eksternal (OSV.dev) tetap terkendali.
- **Onboarding ringan**: tidak perlu setup rumit — cukup tambahkan repo, tekan scan, lihat hasil.

## ✨ Fitur Inti (MVP)

1. **Manajemen Proyek & Aset** — CRUD project, tambah aset berupa URL repository Git.
2. **Scan Manual** — tombol "Pindai Sekarang" memicu backend memuat dan mem-parse manifest (`requirements.txt`, `package.json`) dari repo GitHub publik, lalu mengecek CVE ke OSV.dev secara sinkron.
3. **Daftar Risiko per Komponen** — tabel flat berisi nama komponen, versi, lisensi, dan severity CVE tertinggi.
4. **Drift Detection Sederhana** — bandingkan hasil scan terbaru dengan scan sebelumnya per aset; tandai komponen yang baru muncul, hilang, atau berubah versi.
5. **Dashboard Ringkas** — jumlah aset, jumlah komponen, jumlah CVE kritis, aset dengan drift terbaru.
6. **Alert Satu Channel (Email)** — kirim notifikasi saat scan menemukan CVE kritis baru atau drift.
7. **Autentikasi Sederhana** — login single-user/JWT dasar (tanpa role-based access kompleks di MVP).

> **Catatan keterbatasan pemindaian:** scan tidak memakai Syft, melainkan mem-parse manifest secara langsung. Hanya versi yang *pinned*/baseline pada manifest (`package.json`, `requirements.txt`) yang dipindai — range versi (mis. `^1.2.0`, `>=2,<3`) tidak di-resolve ke versi konkret. Karena itu field lisensi komponen ditampilkan sebagai **"Tidak diketahui"**.

## 🚧 Fitur yang Tidak Dikerjakan

Supaya realistis untuk diselesaikan dalam satu semester, hal-hal berikut sengaja tidak dikerjakan dulu:

- Visualisasi graf dependensi interaktif — diganti tabel flat.
- Multi-channel alert (Telegram/Slack/Discord) — hanya email di MVP.
- Integrasi NVD API dan CISA KEV feed — hanya OSV.dev.
- Export laporan PDF/SARIF/compliance report.
- Scheduled/otomatis re-scan (Celery Beat) — scan hanya manual via tombol.
- Graph database (Neo4j) — relasi dependensi disimpan flat di database relasional (SQLite/PostgreSQL).
- Role-based access control multi-role (Admin/Security Engineer/Developer/Viewer) — cukup satu jenis user login.
- Container image scanning — fokus hanya repository Git (package.json, requirements.txt, dll) di MVP.
- Dependency confusion detection & abandonware scoring — kandidat fase berikutnya jika waktu tersisa.

## ✅ Kriteria Keberhasilan

- [ ] Pengguna bisa membuat project dan menambahkan minimal satu aset (repo Git) dari aplikasi Flutter.
- [ ] Tombol "Pindai Sekarang" berhasil memicu backend mem-parse manifest dan mengembalikan daftar komponen + CVE dari OSV.dev.
- [ ] Hasil scan tersimpan permanen (tidak pernah menimpa/menghapus histori scan sebelumnya).
- [ ] Scan kedua pada aset yang sama berhasil mendeteksi dan menampilkan minimal satu jenis drift (komponen baru/hilang/berubah versi) menggunakan data uji.
- [ ] Dashboard menampilkan ringkasan yang akurat sesuai data di database (bukan hasil hardcode).
- [ ] Notifikasi email terkirim saat ditemukan CVE kritis baru pada suatu scan.
- [ ] Aplikasi Flutter menangani seluruh 6 kondisi UI wajib (loading awal, data berhasil dimuat, empty state, error state + retry, validasi form, loading saat submit) pada minimal fitur Asset Management.
- [ ] Aplikasi dapat di-build dan dijalankan end-to-end (backend dengan SQLite default, atau PostgreSQL via Docker Compose opsional; Flutter app di emulator/device) oleh orang lain mengikuti instruksi di bawah.

---

## 🏗️ Arsitektur

```
┌──────────────────────────────┐
│   FLUTTER APP (repo root)    │
│  Login · Dashboard · Assets  │
│  Scan Result · Alerts        │
└───────────────┬───────────────┘
                │ HTTPS (REST)
┌───────────────▼───────────────┐
│   BACKEND (FastAPI - Python)  │
│  Auth · Project · Asset ·     │
│  Scan (sync) · Dashboard      │
└───────────────┬───────────────┘
                │
┌───────────────▼───────────────┐
│   SQLite (default) /          │
│   PostgreSQL (opsional)       │
└────────────────────────────────┘
                │
┌───────────────▼───────────────┐
│   EXTERNAL (Gratis)           │
│   GitHub raw · OSV.dev · SMTP │
└────────────────────────────────┘
```

Detail arsitektur lengkap, skema data, dan API contract ada di [`docs/architecture/Architecture.md`](docs/architecture/Architecture.md).

Dokumentasi implementasi fitur Asset Management (state management, form, validasi, enam kondisi UI, dan prompt AI yang digunakan) ada di [`docs/P4-asset-management.md`](docs/P4-asset-management.md).

---

## 📁 Struktur Repository

Aplikasi Flutter berada di **root repository**; backend berada di folder `backend/`.

```text
PULSE/
  lib/                      # kode aplikasi Flutter (root)
    main.dart
    app.dart
    routes/
    screens/
    widgets/
    models/
    services/
    features/
      asset_management/
        data/
        application/
        presentation/
  test/
    features/
      asset_management/
  backend/                  # backend FastAPI
    app/
      api/
      core/
      models/
      schemas/
      services/
    alembic/
    tests/
    .env.example
  docs/
    architecture/
    P4-asset-management.md
  pubspec.yaml
  docker-compose.yml        # opsional (PostgreSQL)
```

---

## 🛠️ Tech Stack

**Mobile:** Flutter · Riverpod (state management) · go_router · dio

**Backend:** Python 3.11+ · FastAPI · SQLAlchemy 2.0 · Alembic · Pydantic · JWT

**Database:** SQLite (default) · PostgreSQL 16 (opsional via Docker Compose)

**Security Tools (open-source):** Manifest parsing (`requirements.txt`, `package.json` dari GitHub raw) · OSV.dev API (CVE lookup)

**DevOps:** Docker & Docker Compose (opsional, hanya untuk PostgreSQL)

---

## 🚀 Memulai

### Prasyarat

- [Python 3.11+](https://www.python.org/downloads/) (untuk menjalankan backend dengan SQLite default)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x) + emulator atau device
- Git
- Docker & Docker Compose — *opsional*, hanya jika ingin memakai PostgreSQL

### Backend

```bash
# 1. Clone repository
git clone https://github.com/davidcungniago/PULSE.git
cd PULSE

# 2. Siapkan environment backend (SQLite default)
cd backend
cp .env.example .env
# Isi kredensial SMTP untuk alert email (opsional untuk demo)

# 3. Install dependency lalu jalankan migrasi & seed
pip install -r requirements.txt
alembic upgrade head
python -m app.seed
uvicorn app.main:app --reload --port 8000

# API docs tersedia di: http://localhost:8000/docs
```

Seed membuat **satu user, satu project, dan dua asset** (repo GitHub publik) — tanpa hasil scan palsu. Jalankan "Pindai Sekarang" dari aplikasi untuk mengisi data komponen/CVE.

**Opsional — PostgreSQL via Docker Compose** (default tetap SQLite):

```bash
docker compose up -d --build
docker compose exec backend alembic upgrade head
docker compose exec backend python -m app.seed
```

### Mobile App

Panduan integrasi API, autentikasi, notifikasi email, kamera QR, unit test, serta alur demo penilaian tersedia di [P6/P7](docs/P6-P7.md). Backend kini membutuhkan `JWT_SECRET` minimal 32 karakter dari environment. Register melalui aplikasi untuk membuat akun; seed bersifat opsional dan membutuhkan `DEMO_PASSWORD`.

```bash
# Dari root repository (aplikasi Flutter ada di root, bukan di subfolder terpisah)
flutter pub get
flutter run
# Pastikan API_BASE_URL mengarah ke backend (mis. http://10.0.2.2:8000 untuk emulator Android)
```

---

## 📘 Cara Pakai

1. **Register/Login** di aplikasi Flutter.
2. **Buat project baru**, misal "Backend E-Commerce".
3. **Tambahkan aset** — masukkan URL repository Git.
4. Tekan **"Pindai Sekarang"** — backend mem-parse manifest dan mengecek CVE.
5. Lihat **daftar komponen & CVE** dari hasil scan.
6. Scan ulang di lain waktu untuk melihat **drift** — komponen baru/hilang/berubah versi.
7. Jika ditemukan CVE kritis atau drift, kamu akan menerima **email alert** otomatis.

---

## 📄 Lisensi

Proyek ini menggunakan lisensi **MIT** — lihat file [`LICENSE`](LICENSE) untuk detail lengkap.

---

## 📬 Kontak

**Author:** David Cungniago
**Email:** david.cungniago@student.pradita.ac.id
**GitHub:** [@davidcungniago](https://github.com/davidcungniago)

> Proyek ini dikembangkan sebagai Tugas Akhir mata kuliah *Uji Penetrasi Sistem Jaringan Keamanan* dan portofolio cyber security.

---

<p align="center">Dibuat dengan 🔍 untuk keamanan rantai pasok perangkat lunak yang lebih baik.</p>

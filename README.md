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
2. **Scan Manual** — tombol "Pindai Sekarang" memicu backend men-generate SBOM (via Syft) dan mengecek CVE ke OSV.dev secara sinkron.
3. **Daftar Risiko per Komponen** — tabel flat berisi nama komponen, versi, lisensi, dan severity CVE tertinggi.
4. **Drift Detection Sederhana** — bandingkan hasil scan terbaru dengan scan sebelumnya per aset; tandai komponen yang baru muncul, hilang, atau berubah versi.
5. **Dashboard Ringkas** — jumlah aset, jumlah komponen, jumlah CVE kritis, aset dengan drift terbaru.
6. **Alert Satu Channel (Email)** — kirim notifikasi saat scan menemukan CVE kritis baru atau drift.
7. **Autentikasi Sederhana** — login single-user/JWT dasar (tanpa role-based access kompleks di MVP).


## ✅ Kriteria Keberhasilan

- [ ] Pengguna bisa membuat project dan menambahkan minimal satu aset (repo Git) dari aplikasi Flutter.
- [ ] Tombol "Pindai Sekarang" berhasil memicu backend men-generate SBOM dan mengembalikan daftar komponen + CVE dari OSV.dev.
- [ ] Hasil scan tersimpan permanen (tidak pernah menimpa/menghapus histori scan sebelumnya).
- [ ] Scan kedua pada aset yang sama berhasil mendeteksi dan menampilkan minimal satu jenis drift (komponen baru/hilang/berubah versi) menggunakan data uji.
- [ ] Dashboard menampilkan ringkasan yang akurat sesuai data di database (bukan hasil hardcode).
- [ ] Notifikasi email terkirim saat ditemukan CVE kritis baru pada suatu scan.
- [ ] Aplikasi Flutter menangani seluruh 6 kondisi UI wajib (loading awal, data berhasil dimuat, empty state, error state + retry, validasi form, loading saat submit) pada minimal fitur Asset Management.
- [ ] Aplikasi dapat di-build dan dijalankan end-to-end (backend via Docker Compose, Flutter app di emulator/device) oleh orang lain mengikuti instruksi di bawah.

---

## 🏗️ Arsitektur

```
┌──────────────────────────────┐
│   FLUTTER APP (mobile)       │
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
│   PostgreSQL (single DB)      │
└────────────────────────────────┘
                │
┌───────────────▼───────────────┐
│   EXTERNAL TOOLS (Gratis)     │
│   Syft · OSV.dev · SMTP       │
└────────────────────────────────┘
```

Detail arsitektur lengkap, skema data, dan API contract ada di [`docs/architecture/Architecture.md`](docs/architecture/Architecture.md).

---

## 🛠️ Tech Stack

**Mobile:** Flutter · Riverpod (state management) · go_router · dio

**Backend:** Python 3.11+ · FastAPI · SQLAlchemy 2.0 · Alembic · Pydantic · JWT

**Database:** PostgreSQL 16

**Security Tools (open-source):** Syft (SBOM generation) · OSV.dev API (CVE lookup)

**DevOps:** Docker & Docker Compose

---

## 🚀 Memulai

### Prasyarat

- [Docker](https://www.docker.com/) & Docker Compose
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x) + emulator atau device
- Git

### Backend

```bash
# 1. Clone repository
git clone https://github.com/davidcungniago/PULSE.git
cd PULSE

# 2. Salin file environment
cp .env.example .env
# Isi kredensial SMTP untuk alert email

# 3. Jalankan PostgreSQL & backend
docker compose up -d --build

# 4. Jalankan migrasi & seed data
docker compose exec backend alembic upgrade head
docker compose exec backend python -m app.seed

# API docs tersedia di: http://localhost:8000/docs
```

### Mobile App

```bash
cd mobile
flutter pub get
flutter run
# Pastikan API_BASE_URL di konfigurasi mobile mengarah ke backend (mis. http://10.0.2.2:8000 untuk emulator Android)
```

---

## 📘 Cara Pakai

1. **Register/Login** di aplikasi Flutter.
2. **Buat project baru**, misal "Backend E-Commerce".
3. **Tambahkan aset** — masukkan URL repository Git.
4. Tekan **"Pindai Sekarang"** — backend men-generate SBOM dan mengecek CVE.
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

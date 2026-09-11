# 🔍 Pulse

### Continuous Supply Chain Integrity Monitor

**Platform monitoring integritas rantai pasok perangkat lunak berbasis SBOM (Software Bill of Materials) untuk deteksi dini ancaman supply chain.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Build Status](https://img.shields.io/github/actions/workflow/status/yourusername/pulse/ci.yml?branch=main)](.github/workflows/ci.yml)
[![Python](https://img.shields.io/badge/Python-3.11%2B-blue.svg)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.110-009688.svg)](https://fastapi.tiangolo.com/)
[![Next.js](https://img.shields.io/badge/Next.js-14-black.svg)](https://nextjs.org/)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED.svg)](https://www.docker.com/)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

---

## 📖 Daftar Isi

- [Latar Belakang](#-latar-belakang)
- [Apa yang Pulse Lakukan](#-apa-yang-pulse-lakukan)
- [Fitur Utama](#-fitur-utama)
- [Demo](#-demo)
- [Arsitektur](#-arsitektur)
- [Tech Stack](#-tech-stack)
- [Memulai](#-memulai)
- [Cara Pakai](#-cara-pakai)
- [Roadmap](#-roadmap)
- [Kontribusi](#-kontribusi)
- [Lisensi](#-lisensi)
- [Kontak](#-kontak)

---

## 🧩 Latar Belakang

Serangan siber modern semakin sering menyasar **rantai pasok perangkat lunak (software supply chain)**, bukan aplikasi secara langsung. Beberapa insiden nyata yang menjadi latar belakang proyek ini:

| Insiden | Tahun | Dampak |
|---|---|---|
| **SolarWinds** | 2020 | Backdoor disusupkan ke build pipeline resmi → 18.000+ organisasi terdampak |
| **Log4Shell** | 2021 | Satu library (`log4j`) dipakai jutaan aplikasi → krisis keamanan global |
| **event-stream** | 2018 | Kontrol maintainer npm diserahkan ke pihak jahat → backdoor tersebar |
| **XZ Utils** | 2024 | Backdoor ditanam oleh "kontributor tepercaya" selama 2 tahun sebelum terdeteksi |

Masalah intinya: kebanyakan organisasi **tidak tahu persis komponen apa saja** yang ada di dalam software mereka, butuh waktu lama untuk menilai dampak CVE baru, dan **tidak ada yang memantau perubahan dependensi** dari waktu ke waktu — sehingga serangan seperti SolarWinds bisa lolos tanpa terdeteksi.

## 💡 Apa yang Pulse Lakukan

Pulse mengumpulkan **SBOM** dari berbagai sumber (repo Git, container image, upload manual), menganalisis risiko tiap komponen secara multi-dimensi (bukan cuma CVE), memantau **drift** dependensi secara berkelanjutan, dan memvisualisasikan seluruh rantai pasok dalam graf interaktif — lengkap dengan alert dini dan laporan kepatuhan untuk audit.

Pulse dirancang sebagai **orkestrator** di atas tools open-source yang sudah teruji (Syft, Grype, OSV.dev, NVD), mengisi celah yang belum ada di tools open-source manapun secara terintegrasi: kombinasi **drift detection + analisis risiko multi-dimensi + visualisasi graf**, sepenuhnya gratis dan self-hosted.

| Aspek | Dependabot | Snyk | Syft/Grype | **Pulse** |
|---|:---:|:---:|:---:|:---:|
| SBOM Generation | ❌ | ✅ | ✅ | ✅ |
| CVE Scan | ✅ | ✅ | ✅ | ✅ |
| License Analysis | ❌ | ⚠️ | ❌ | ✅ |
| **Drift Detection** | ❌ | ❌ | ❌ | **✅** |
| Visual Graph | ❌ | ⚠️ | ❌ | ✅ |
| Blast Radius | ❌ | ❌ | ❌ | ✅ |
| Open Source | ❌ | ❌ | ✅ | ✅ |
| Self-hosted | ❌ | ❌ | ✅ | ✅ |

---

## ✨ Fitur Utama

**📦 Manajemen Proyek & Aset**
- Multi-project, multi-aset (repo Git, container image, SBOM vendor)
- Role-based access control: Admin, Security Engineer, Developer, Viewer

**📥 Ingesti SBOM**
- Upload manual (CycloneDX JSON/XML, SPDX JSON/tag-value)
- Integrasi Git (GitHub/GitLab) — auto-scan `package.json`, `requirements.txt`, `go.mod`, `pom.xml`, `Cargo.toml`
- Scan container image via Syft
- API endpoint untuk integrasi CI/CD

**🔬 Analisis Risiko Multi-Dimensi**
- CVE lookup (OSV.dev + NVD API)
- Deteksi lisensi berisiko
- Deteksi abandonware (tidak update > 24 bulan)
- Dependency confusion risk (Levenshtein distance)
- Skor popularitas & maintenance
- Analisis blast radius

**🔄 Continuous Monitoring & Drift Detection**
- Re-scan terjadwal (1 jam / 6 jam / harian / mingguan)
- SBOM diff antar waktu scan
- Deteksi dependensi baru, versi berubah, atau hilang tanpa tercatat
- Auto-cek CVE baru terhadap aset yang sudah ada

**🕸️ Visualisasi Graf Interaktif**
- Graf dependensi dengan color-coding risiko
- Panel detail per komponen
- Filter berdasarkan level risiko/ekosistem
- Blast radius view per CVE

**🔔 Alert & Notifikasi**
- Email, Telegram, Slack, Discord
- Deduplikasi alert dalam time window

**📄 Laporan & Ekspor**
- Compliance report (PDF)
- Export SBOM (CycloneDX/SPDX)
- Export SARIF untuk integrasi tools lain
- Export CSV/JSON

> 🧪 **Fase 2 (Nice-to-have):** integrasi CI/CD, PR bot otomatis, Policy-as-Code, multi-tenant, CISA KEV feed, SLSA level check, dukungan VEX.

---

## 🖼️ Demo

> 📸 *Screenshot dan demo akan ditambahkan di sini setelah aplikasi selesai dikembangkan.*

| Dashboard | Graf Dependensi | Blast Radius |
|---|---|---|
| `docs/images/dashboard-placeholder.png` | `docs/images/graph-placeholder.png` | `docs/images/blast-radius-placeholder.png` |

---

## 🏗️ Arsitektur

```
┌─────────────────────────────────────────────────────────────┐
│                    FRONTEND (Next.js/React)                 │
│  Dashboard · Graf Visualisasi · Alert Config · Report       │
└──────────────────────────┬──────────────────────────────────┘
                            │ HTTPS / WebSocket
┌──────────────────────────▼──────────────────────────────────┐
│                  API GATEWAY (Nginx / Traefik)               │
└──────────────────────────┬──────────────────────────────────┘
                            │
┌──────────────────────────▼──────────────────────────────────┐
│                  BACKEND (FastAPI - Python)                  │
│  Auth API │ Project API │ SBOM API │ Alert API               │
└──────┬──────────────────────────────────────────┬────────────┘
       │                                           │
┌──────▼────────────┐                  ┌───────────▼──────────┐
│  TASK QUEUE        │                  │  DATABASE            │
│  (Celery + Redis)  │                  │  PostgreSQL (meta)   │
│  Worker: Scan       │                  │  Neo4j (graf)        │
│  Worker: Analyze    │                  │  Redis (cache)       │
│  Worker: Alert      │                  └───────────────────────┘
└──────┬────────────┘
       │
┌──────▼──────────────────────────────────────────────────────┐
│           EXTERNAL TOOLS & API (Gratis)                      │
│  Syft · Grype · OSV.dev · NVD API · GitHub API                │
└─────────────────────────────────────────────────────────────┘
```

Detail arsitektur lengkap, skema data, dan API contract ada di [`docs/architecture/`](docs/architecture/).

---

## 🛠️ Tech Stack

**Backend:** Python 3.11+ · FastAPI · SQLAlchemy 2.0 · Alembic · Celery · Redis · Pydantic · JWT (python-jose)

**Frontend:** Next.js 14 (App Router) · TypeScript · Tailwind CSS · shadcn/ui · Cytoscape.js · TanStack Query · Zustand

**Database & Storage:** PostgreSQL 16 · Neo4j Community (graf dependensi) · Redis 7 · MinIO (opsional)

**Security Tools (open-source):** Syft (SBOM generation) · Grype / Trivy (vulnerability scan)

**External APIs (gratis):** OSV.dev · NVD API · CISA KEV · GitHub API · npm/PyPI/Maven registry

**DevOps:** Docker & Docker Compose · GitHub Actions · Nginx/Traefik

---

## 🚀 Memulai

### Prasyarat

- [Docker](https://www.docker.com/) & Docker Compose
- Git

### Instalasi

```bash
# 1. Clone repository
git clone https://github.com/yourusername/pulse.git
cd pulse

# 2. Salin file environment
cp .env.example .env
# Sesuaikan nilai di .env sesuai kebutuhan (SMTP, Telegram bot token, dsb.)

# 3. Jalankan seluruh stack
docker compose up -d --build

# 4. Jalankan migrasi database
docker compose exec backend alembic upgrade head

# 5. Buka aplikasi
# Frontend : http://localhost:3000
# API docs : http://localhost:8000/docs
```

### Menjalankan secara lokal (tanpa Docker, untuk development)

```bash
# Backend
cd backend
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload

# Frontend
cd frontend
npm install
npm run dev
```

---

## 📘 Cara Pakai

1. **Buat akun & login** melalui halaman `/register`.
2. **Buat project baru**, misal "E-Commerce Backend".
3. **Tambahkan aset** — hubungkan repo GitHub, masukkan nama container image, atau upload file SBOM manual.
4. Pulse akan otomatis men-generate/mem-parsing SBOM dan menjalankan analisis risiko (CVE, lisensi, abandonware, dsb).
5. Pantau **dashboard** dan **graf dependensi** untuk melihat status risiko tiap komponen.
6. Atur **channel alert** (email/Telegram/Slack) di halaman konfigurasi project.
7. Saat ada CVE baru atau drift terdeteksi, Pulse mengirim notifikasi otomatis.
8. Unduh **laporan kepatuhan** (PDF/SARIF) untuk keperluan audit.

---

## 🗺️ Roadmap

| Minggu | Fokus | Deliverable |
|---|---|---|
| 1–2 | Riset & desain | Proposal, wireframe, ERD, arsitektur |
| 3–4 | Backend core | Auth, project CRUD, setup database |
| 5–6 | SBOM ingest | Parser CycloneDX/SPDX, integrasi Syft |
| 7 | Vulnerability analysis | Integrasi OSV.dev, NVD, Grype |
| 8 | Drift detection | SBOM diff engine, alert |
| 9 | Frontend dashboard | Next.js + shadcn/ui |
| 10 | Visualisasi graf | Cytoscape.js + blast radius view |
| 11 | Alert & Report | Email/Telegram, PDF, SARIF |
| 12 | Testing & dokumentasi | Unit test, README, video demo |

Rencana Fase 2: integrasi CI/CD, PR bot otomatis, Policy-as-Code, multi-tenant, dukungan VEX & SLSA level check.

---

## 🤝 Kontribusi

Kontribusi sangat terbuka! Silakan baca [`CONTRIBUTING.md`](CONTRIBUTING.md) untuk panduan lengkap. Alur singkatnya:

1. Fork repository ini
2. Buat branch baru (`git checkout -b fitur/nama-fitur`)
3. Commit perubahan (`git commit -m 'feat: tambah fitur X'`)
4. Push ke branch (`git push origin fitur/nama-fitur`)
5. Buka Pull Request

---

## 📄 Lisensi

Proyek ini menggunakan lisensi **MIT** — lihat file [`LICENSE`](LICENSE) untuk detail lengkap.

---

## 📬 Kontak

**Author:** David Cungniago
**Email:** david.cungniago@student.pradita.ac.id
**GitHub:** [@davidcungniago](https://github.com/yourusername)

> Proyek ini dikembangkan sebagai Tugas Akhir mata kuliah *Uji Penetrasi Sistem Jaringan Keamanan* dan portofolio cyber security.

---

<p align="center">Dibuat dengan 🔍 untuk keamanan rantai pasok perangkat lunak yang lebih baik.</p>

# Log aman, penyebab error, dan tindakan perbaikan

Jalankan Uvicorn dengan `--no-access-log`. Middleware Pulse mencatat metadata yang diizinkan, bukan seluruh request. Request ID dibuat server; header ID dari klien tidak dipercaya. Route yang dicatat berupa template (`{project_id}`), bukan ID/URL mentah. Body, email, Authorization, cookie, query string, password, connection string, dan detail exception tidak dicatat. Jangan mengaktifkan HTTP/SQL debug logging pada deployment yang memproses kredensial.

Contoh berikut sintetis untuk dokumentasi, bukan bukti pengujian:

```json
{"Event":"http_request","RequestId":"contoh-01","Method":"GET","Route":"/api/projects","Status":401,"DurationMs":2}
{"Event":"http_request","RequestId":"contoh-02","Method":"POST","Route":"/api/projects/{project_id}/assets","Status":422,"DurationMs":3}
{"Event":"http_request","RequestId":"contoh-03","Method":"POST","Route":"/api/assets/{asset_id}/scan","Status":502,"DurationMs":15002}
{"Event":"http_request","RequestId":"contoh-04","Method":"GET","Route":"/api/projects","Status":500,"DurationMs":4}
```

Status HTTP tidak selalu menentukan satu penyebab. Gunakan waktu, route, `X-Request-ID` dari respons, dan konfigurasi deployment yang diperiksa secara privat. Jangan menyalin token/body ke laporan. Exception tak terduga menghasilkan pesan publik `Terjadi kesalahan pada server.`; konsekuensinya log standar tidak menyediakan stack trace. Reproduksi dengan data sintetis di lingkungan terisolasi untuk diagnosis lebih lanjut.

| Gejala | Kemungkinan penyebab | Tindakan perbaikan |
|---|---|---|
| 401 | Token hilang, invalid, kedaluwarsa, atau kunci JWT berubah | Masuk kembali; periksa keberadaan konfigurasi JWT tanpa mencetak nilainya. Pastikan kunci stabil setelah restart. |
| 404 pada resource | ID tidak ada atau milik akun lain | Periksa akun/proyek yang dipilih. Jangan menghapus pemeriksaan pemilik agar request lolos. |
| 409 aset/proyek | Duplikat, perubahan URL aset bersejarah, atau penghapusan proyek berisi aset | Gunakan aset yang sudah ada/buat identitas baru; pertahankan riwayat. |
| 422 | Payload atau repository tidak valid/tidak didukung | Perbaiki URL HTTPS GitHub/GitLab; scan saat ini hanya GitHub publik. Baca `Message` respons. |
| 502/504 scan | GitHub/OSV tidak tersedia, timeout, rate limit, atau redirect ditolak | Periksa koneksi dan layanan eksternal; retry setelah jeda. Jangan menonaktifkan validasi host/redirect. |
| 503 autentikasi | JWT_SECRET kosong/terlalu pendek | Atur secret minimal 32 karakter melalui environment, lalu restart API. |
| 500 | Error tak terduga, migrasi belum ada, atau masalah database | Cocokkan RequestId/waktu; cek health, migrasi, izin volume, dan koneksi. Reproduksi terisolasi, bukan menampilkan exception mentah ke pengguna. |
| Browser gagal CORS | Origin/port frontend tidak masuk allowlist | Atur `CORS_ORIGINS` sesuai origin persis; build ulang jika API_BASE_URL salah. Jangan memakai `*` sebagai solusi produksi. |
| Email gagal terkirim | SMTP kosong, autentikasi/TLS gagal, atau provider menolak | Periksa host/port/TLS dan kredensial melalui konfigurasi privat; scan tetap tersimpan. |
| Docker pipe tidak ditemukan | Docker Desktop/daemon belum siap | Mulai Docker Desktop dan tunggu `docker version` menampilkan Server sebelum build. |
| Dart `Out of memory` | Resource Windows/commit memory tidak cukup | Selesaikan proses build lain, gunakan satu worker, lalu ulang seluruh suite; jangan mengubah assertion. |
| pytest cache access denied | Izin folder cache | Gunakan `-p no:cacheprovider` atau perbaiki izin folder cache milik proyek. |

Jangan menjalankan `docker compose config` tanpa `--quiet` untuk laporan publik: hasil render dapat mengandung secret environment. Jangan mengunggah `docker inspect`, output environment, `.env`, database, atau dump HTTP mentah. Sebelum membagikan log, lakukan review manual. Log proxy/server hosting harus menerapkan aturan sanitasi yang sama; middleware aplikasi tidak mengendalikan log pihak lain.

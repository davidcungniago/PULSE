# User Stories & Acceptance Criteria — Pulse MVP

Lima story pertama (US-1 sampai US-5) adalah inti MVP Version 1. US-6 dan US-7 dikerjakan pada tahap menuntaskan MVP.

---

## US-1 — Menambahkan aset repository

Sebagai developer, saya ingin menambahkan URL repository GitHub/GitLab ke sebuah project, agar repository tersebut bisa dipindai.

**Acceptance criteria**

1. URL berformat `https://github.com/{owner}/{repo}` atau `https://gitlab.com/{owner}/{repo}` diterima. Akhiran `.git` dan garis miring di akhir diabaikan.
2. URL kosong ditolak dengan pesan "URL repositori wajib diisi."
3. URL yang bukan GitHub/GitLab asli (misalnya `https://evilgithub.com/a/b`), tanpa `https`, atau tanpa nama repo ditolak dengan pesan yang jelas.
4. URL yang sama tidak bisa ditambahkan dua kali dalam satu project.
5. Aset yang berhasil ditambahkan tersimpan di database (tetap ada setelah backend di-restart) dan muncul di daftar aset.
6. Selama proses kirim berlangsung, tombol tidak bisa ditekan ulang.

---

## US-2 — Pemindaian manual

Sebagai developer, saya ingin menekan tombol "Pindai Sekarang" pada sebuah aset, agar komponen dan kerentanan (CVE) repository tersebut terdeteksi.

**Acceptance criteria**

1. Pemindaian hanya berjalan saat tombol ditekan. Membuka layar apa pun tidak memicu pemindaian.
2. Setiap pemindaian membuat catatan hasil baru. Hasil sebelumnya tidak dihapus atau ditimpa.
3. Tombol nonaktif dan menampilkan indikator loading selama pemindaian berjalan.
4. Pemindaian yang berhasil memperbarui waktu "terakhir dipindai" pada aset.
5. Repository tidak ditemukan/private, tidak ada manifest yang didukung (`requirements.txt` / `package.json`), atau layanan CVE tidak bisa dihubungi menampilkan pesan error yang jelas dengan tombol "Coba Lagi". Data pemindaian sebelumnya tetap utuh.

---

## US-3 — Melihat daftar risiko komponen

Sebagai developer, saya ingin melihat daftar komponen hasil pemindaian terakhir beserta tingkat risikonya, agar tahu komponen mana yang harus diprioritaskan.

**Acceptance criteria**

1. Setiap komponen menampilkan nama, versi, lisensi (atau "Tidak diketahui"), dan severity CVE tertinggi.
2. Daftar diurutkan dari severity tertinggi: Kritis, Tinggi, Sedang, Rendah, Tidak diketahui, lalu tanpa CVE.
3. Komponen tanpa CVE ditampilkan dengan status aman.
4. Aset yang belum pernah dipindai menampilkan empty state dengan ajakan untuk memindai.
5. Severity ditampilkan dengan widget `StatusBadge` yang sama di seluruh aplikasi.

---

## US-4 — Deteksi drift dependensi

Sebagai security engineer, saya ingin tahu perubahan dependensi sejak pemindaian sebelumnya, agar dependensi mencurigakan yang muncul tiba-tiba bisa segera dicek.

**Acceptance criteria**

1. Pemindaian pertama suatu aset tidak menghasilkan drift.
2. Pemindaian berikutnya dibandingkan dengan pemindaian sebelumnya untuk aset yang sama.
3. Komponen baru dicatat sebagai Added, komponen yang hilang sebagai Removed, dan komponen dengan versi berbeda sebagai Changed (versi lama ke versi baru).
4. Jika tidak ada perubahan, tidak ada drift event yang dibuat.
5. Drift event tersimpan permanen dan ditampilkan di layar hasil pemindaian.

---

## US-5 — Dashboard ringkasan risiko project

Sebagai developer, saya ingin melihat ringkasan risiko seluruh aset dalam satu project, agar saya tahu status keamanan project dalam hitungan detik.

**Acceptance criteria**

1. Dashboard menampilkan total aset, total komponen, total CVE kritis, dan jumlah aset dengan drift (dari pemindaian terbaru), dihitung dari database.
2. Setiap aset punya RiskStatus:
   - `CRITICAL`: ada CVE kritis pada pemindaian terbaru.
   - `WARNING`: ada CVE non-kritis atau drift pada pemindaian terbaru.
   - `HEALTHY`: sudah dipindai dan tidak ada masalah.
   - `NOT_SCANNED`: belum pernah dipindai.
3. Membuka dashboard tidak memicu pemindaian.
4. "Pindai Semua Aset" memindai aset satu per satu. Kegagalan satu aset tidak menghentikan aset lain dan dilaporkan per aset.
5. Project tanpa aset menampilkan empty state. Kegagalan memuat menampilkan pesan error dengan tombol "Coba Lagi".

---

## US-6 — Alert email (tahap menuntaskan MVP)

Sebagai security engineer, saya ingin menerima email saat ada temuan penting, agar saya tidak perlu membuka aplikasi untuk tahu ada masalah.

**Acceptance criteria**

1. Email terkirim saat pemindaian menemukan CVE kritis yang belum ada di pemindaian sebelumnya, atau ada drift.
2. Jika tidak ada keduanya, email tidak dikirim.
3. Setiap alert tercatat di riwayat alert dan tampil di layar Alert.
4. SMTP yang tidak dikonfigurasi atau gagal tidak menggagalkan pemindaian. Alert dicatat sebagai gagal terkirim.

---

## US-7 — Autentikasi sederhana (tahap menuntaskan MVP)

Sebagai pengguna, saya ingin masuk dengan akun saya sendiri, agar project saya tidak terlihat oleh orang lain.

**Acceptance criteria**

1. Register menerima email valid dan kata sandi minimal 6 karakter. Email yang sudah terdaftar ditolak.
2. Kata sandi tersimpan dalam bentuk hash, bukan teks asli.
3. Login yang berhasil mengembalikan token. Kredensial salah ditolak dengan pesan yang jelas.
4. Semua endpoint selain register dan login membutuhkan token.
5. Pengguna hanya bisa melihat dan mengubah project miliknya.
6. Token tidak valid atau kedaluwarsa mengarahkan pengguna kembali ke layar login.

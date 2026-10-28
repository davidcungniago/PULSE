## Ringkasan

- Perubahan:
- Alasan:
- Risiko/kompatibilitas:

## Bukti verifikasi

- Commit/branch yang diuji:
- [ ] Fresh clone dan instalasi dependency baru
- [ ] `flutter analyze`
- [ ] `flutter test --concurrency=1 --reporter expanded`
- [ ] `pytest -q -p no:cacheprovider`
- [ ] `ruff check` dan `ruff format --check`
- [ ] Build web dan migrasi database kosong
- [ ] Run aplikasi + alur register/proyek/aset/reload
- [ ] Deployment yang diklaim benar-benar dijalankan
- [ ] Tidak ada `.env`, token, password, database pengguna dalam diff/artifact

Lampirkan output aktual dan tandai langkah yang belum dijalankan. Jangan mencentang hanya karena workflow telah ditambahkan.

## Security dan operasional

- Temuan/perbaikan terkait:
- Contoh log tersanitasi dan tindakan perbaikan:
- Konfigurasi baru/migrasi:
- Cara rollback tanpa menghapus database/riwayat:

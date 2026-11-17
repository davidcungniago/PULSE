# Pulse — Design spec ("Pulse Monitor")

This is the design source of truth for all Flutter UI work. Do not invent colors, spacing, or copy outside this file.

## Concept

The ECG trace is the visual language of the product. The health of a project is the rhythm of a heartbeat. Everything else stays quiet: tonal surfaces, no shadows, and color is used only to express risk.

## Theme

- Dark-first. The default theme is dark (a monitor screen). The light theme must stay fully usable: same layout, same semantic hues, darker text shades for contrast.
- All tokens live in `lib/theme/`. No hard-coded colors in widgets.

| Token | Dark | Light |
|---|---|---|
| bg | #0F1512 | #F6F5F0 |
| surface | #161E1A | #FFFFFF |
| surfaceTrace | #121A16 | #EEF2EF |
| line | #26312C | #D9DDD8 |
| gridMinor | #1B2621 | #E3E8E4 |
| gridMajor | #26332C | #CBD3CD |
| text | #E9E5D8 | #1A211D |
| textMuted | #9AA59E | #5B665F |

### Status and severity colors

`Fill` is used for traces, dots and badge backgrounds (as a tint). `Text on light` is the darker shade used for text in the light theme. In the dark theme, badge text uses the fill color.

| Name | Fill | Text on light |
|---|---|---|
| healthy | #4ADE80 | #15803D |
| warning | #EAB308 | #A16207 |
| critical | #EF4444 | #B91C1C |
| notScanned | #9CA3AF | #4B5563 |
| scanning | #60A5FA | #1D4ED8 |
| drift (ectopic) | #93C5FD | #1D4ED8 |

Severity is a separate enum from RiskStatus.

| Severity | Label (Indonesian) | Fill | Text on light |
|---|---|---|---|
| critical | Kritis | #EF4444 | #B91C1C |
| high | Tinggi | #F97316 | #C2410C |
| medium | Sedang | #EAB308 | #A16207 |
| low | Rendah | #60A5FA | #1D4ED8 |
| unknown | Tidak diketahui | #9CA3AF | #4B5563 |
| safe | Aman | #22C55E | #15803D |

Badge rule: tonal. Background is the fill color at 16% alpha composited over the surface. Text contrast against the composited background must be at least 4.5:1 in BOTH themes. If a pair fails, darken or lighten the text shade. No pale text on a pale background.

## Layout and type

- Max content width 560dp, centered (`ConstrainedPage`). Page padding 16. Spacing grid 8.
- Radius: cards 16, chips and badges 12, tiles 8. No elevation or shadows. Separate surfaces with tone plus a 1dp `line` border.
- Default font for UI. Monospace (`fontFamily: 'monospace'`, with fallback `Courier New`) for `package@version`, CVE ids and vital numbers.
- Scale: 11 caption, 13 secondary, 14 label (w500), 16 body, 22 numbers (w500, monospace), 22 heading. Two weights only (400 and 500).
- Tap targets at least 48dp.

## The pulse trace

Three parts: a pure function, a painter, and a widget.

### Pure function contract

```dart
class Waveform {
  final List<Offset> points;
  final List<double> ectopicXs;
  final bool isFlat;
}

Waveform buildWaveform({
  required RiskStatus status,
  required int seed,
  required double width,
  required double height,
  bool hasDrift = false,
});
```

- One point per pixel column, x from 0 to width - 1, y in pixels (0 is the top).
- Deterministic: the same inputs always give the identical output. All randomness comes from `Random(seed)`.
- Project seed: a stable FNV-1a 32-bit hash of the project id string. Do not use `String.hashCode` (not stable across runs).
- Baseline y = 0.64 * height. Scale = 0.24 * height per unit. Clamp y to [0, height].
- Time mapping: 110 pixels per second of signal time (1 pixel = 1/110 s).

### Beat shape

Sum of gaussians `g(dt, mu, sigma) = exp(-((dt - mu) / sigma)^2 / 2)`, where dt is seconds since the beat's R peak:

| Wave | Amplitude | mu (s) | sigma (s) |
|---|---|---|---|
| P | 0.12 * pScale | -0.18 | 0.04 |
| Q | -0.12 | -0.035 | 0.012 |
| R | rAmp | 0 | rSigma |
| S | -0.22 | +0.04 | 0.014 |
| T | tAmp | +0.28 | 0.06 |
| ST | st | +0.13 | 0.09 |

Parameters per status. `±` is a total spread: `value + (random - 0.5) * spread`.

| status | interval s | rAmp | rSigma | tAmp | st | pScale | noise | fib |
|---|---|---|---|---|---|---|---|---|
| healthy | 0.92 ± 0.04 | 1.0 ± 0.04 | 0.012 | 0.26 | 0 | 1.0 | 0.012 | 0 |
| warning | 0.78 ± 0.5 | 1.25 ± 0.5 | 0.014 | 0.42 | 0.22 | 0.8 | 0.03 | 0 |
| critical | 0.46 ± 0.28 | 1.9 ± 0.7 | 0.026 | -0.2 | 0.35 | 0.3 | 0.05 | 0.22 |

- noise: uniform random in +-noise/2 per sample.
- fib (critical only): add `fib * sin(t * 95 + sin(t * 7) * 3) * (0.5 + 0.5 * sin(t * 1.3))`.
- notScanned: flat line at the baseline (all y equal), `isFlat = true`, no beats. The painter draws a dashed grey line with the label "Tanpa sinyal".

### Drift: ectopic beat

When `hasDrift` is true and status is not notScanned, every 4th beat is replaced by an ectopic beat:
- It occurs 0.6 * interval after the previous beat, followed by a pause of 1.2 * interval.
- Shape: `1.5 * 0.9 * g(dt, 0, 0.045) - 0.3 * g(dt, 0.3, 0.09)`. No P wave.
- Its peak x position goes into `ectopicXs`. The painter colors that beat in the drift color and draws a small triangle marker above the peak.

### Painter and widget

- Grid: minor lines every 12dp, major lines every 60dp, on `surfaceTrace`.
- Trace stroke 1.8, round joins, color = status fill (scanning state uses the scanning color).
- Static mode draws the full trace. Sweep mode (used only while a scan runs) draws a bright head dot, erases a 26dp gap ahead of the head, and moves at 110dp/s times 1.6.
- Widget `PulseTrace` takes `status`, `seed`, `hasDrift`, `scanning`, `animate`.

### Animation rules

- Static by default. Animate only in the dashboard banner while a scan runs, and in the login and register hero (healthy, slow).
- Never run an infinite animation inside list items.
- Animation is off when `animate == false` or `MediaQuery.disableAnimations` is true. Tests always pass `animate: false`. Dispose controllers. Wrap painters in `RepaintBoundary`.
- Accessibility: `Semantics(label: "Status: <label>. <sub>")`. Never rely on color alone: shape and a text label are always present.

## Triage

The project dashboard answers "what should I do now?" before "how many?".

- `PulseBanner` shows the project status plus a factual summary of what changed or is missing.
- `VitalLine` is one monospace readout (`4 aset · 128 komponen · 2 kritis · 1 drift`) and replaces the three large vital tiles. It uses 13dp monospace, muted labels, text-colored numbers, and the critical shade for a non-zero critical count.
- `TriageCard` shows at most three leads. The remaining leads are revealed with "Lihat semua (N)".
- Order: critical CVE, drift, warning, never scanned. Inside a bucket, more critical assets first, then asset name.
- Each asset appears at most once, under the most urgent reason.
- Each lead has exactly one action: "Lihat temuan", "Lihat perubahan", or "Pindai sekarang".
- A project with an empty queue shows "Tidak ada tindakan. Denyut stabil." and the last scan time.
- Project status aggregates assets: any critical asset makes the project critical; otherwise any warning asset makes it warning; a project where every asset is not scanned is not scanned; a partially scanned project is warning; otherwise healthy.
- Do not claim a number of new findings unless the API provides it. Summary lines only state what is known.
- After "Pindai semua aset" or a single scan from triage, show `ScanReportSheet` with one row per asset (finished or failed with reason) instead of raw text.

## Radar

Radar is the local shortlist of repositories the user wants to watch before they become assets. The name replaces "Daftar Pantau". Its data stays on the device.

- The app bar and every error use "Radar".
- Each item keeps its local note and priority; editing stays local.
- Each item has one promotion action: "Jadikan aset". It opens `PromoteSheet`.
- `PromoteSheet` lists the user's projects with loading, empty, error and retry states. Empty copy: "Belum ada proyek. Buat proyek terlebih dahulu."
- Promotion creates the asset from the item URL, then removes the item from Radar. If asset creation fails, including a duplicate URL, the item stays and the API message is shown in the sheet.
- The sheet blocks dismissal while submitting. On success it closes and the screen shows "Aset ditambahkan ke <nama proyek>."
- Do not remove a Radar item unless the asset was created.

## Components

- `PulseTrace`, `PulseBanner` (trace + status label + sub line + drift legend), `VitalTile` (label + monospace number), `VitalLine`
- `TriageCard` (kind badge, asset name, reason, last scan, one action), `ScanReportSheet`
- `SeverityBadge` (uses `Severity`), `StatusBadge` (uses `RiskStatus`, restyled)
- `ProjectMonitorCard` (mini static trace + name + status), `AssetCard` (name, status, relative time, scan action)
- Radar item (name, URL, note, priority badge, edit, delete, "Jadikan aset"), `PromoteSheet` (project list + promotion state)
- `ConstrainedPage`, `EmptyState`, `ErrorState` (restyled, same behavior)

## Microcopy (Indonesian)

- Sentence case. Labels and headings have no terminal punctuation. Helper text and empty-state body end with a period. Verb first on buttons. No "successfully", no "please", no exclamation marks.
- Use "proyek", "repositori", "aset", and "pemindaian" in UI copy. Do not write "project" or "repository". "URL repositori" is the only fixed phrase with "repositori".
- Use the ellipsis character "…" for progress text, never a period.
- Status labels: healthy "Sehat", warning "Peringatan", critical "Perlu tindakan", notScanned "Belum dipindai".
- Sub lines: healthy "Tidak ada temuan", notScanned "Tanpa sinyal. Pindai untuk mulai.", scanning "Memindai…".
- Dashboard summary lines: "N aset perlu tindakan", "N aset berubah sejak pemindaian terakhir", "N aset berperingatan", "N belum dipindai", joined with " · ". Calm state "Tidak ada tindakan. Denyut stabil."
- Triage headings and actions: "Perlu tindakan", "Lihat semua (N)", "Ringkas", "Lihat temuan", "Lihat perubahan", "Pindai sekarang".
- Vital line labels: "aset", "komponen", "kritis", "drift".
- Relative time: "baru saja", "N menit lalu", "N jam lalu", "kemarin", "N hari lalu", "N minggu lalu". Cards prefix it with "Dipindai "; a never-scanned card uses "Belum pernah dipindai".
- Drift legend: "Segitiga menandai drift dependensi."
- Scan report: "Pemindaian selesai.", "N dari M aset selesai.", per-asset "Selesai".
- Radar: title "Radar", add "Tambah repositori", promote "Jadikan aset", picker title "Jadikan aset", picker body "Pilih proyek untuk <nama>.", empty "Belum ada proyek. Buat proyek terlebih dahulu.", error "Radar tidak dapat dimuat.", success "Aset ditambahkan ke <nama proyek>.", confirm "Hapus repositori?" and "<nama> akan dihapus dari Radar di perangkat ini."
- Form and action headings: "Buat akun", "Buat proyek", "Tambah aset", "Kelola aset", "Ringkasan proyek", "Tambah repositori", "Ubah repositori", "Coba lagi", "Pindai QR repositori".
- Home title "Pusat pemantauan". Dashboard tile labels "Komponen", "CVE kritis", "Drift".
- Severity labels are fixed (table above). Drift types: "Ditambahkan", "Dihapus", "Diubah".
- Empty states: an invitation, not an apology, for example "Belum ada proyek. Buat proyek pertama untuk mulai memantau."

## Not in scope

New packages, custom font bundles, illustrations, splash screens, page transitions, charts, and any animation beyond the rules above.

## P6/P7 extension approved for implementation

The P7 scope adds `mobile_scanner` for QR repository input and `flutter_secure_storage` for authenticated sessions. Existing colors, spacing, typography and constrained layouts remain unchanged.

New Indonesian copy: "Pindai QR repositori", "Arahkan kamera ke QR berisi URL repositori.", "Batal", "QR harus berisi URL repositori GitHub atau GitLab.", "Kamera tidak tersedia atau izin ditolak. Aktifkan izin kamera, atau kembali untuk mengetik URL.", "Ubah aset", "Ubah proyek", "Simpan", "Nama", "Nama wajib diisi.", "Aset aktif", "Hapus proyek", "Hapus proyek?", "Hanya proyek tanpa aset yang dapat dihapus.", "Aset ditambahkan.", "Email terkirim", "Email gagal terkirim", "Menunggu pengiriman", "Sesi berakhir. Masuk kembali.", "Data tidak dapat dimuat. Coba lagi.", "Pemindaian selesai.", "Belum ada aset. Tambahkan repositori untuk mulai memantau.", "Belum ada peringatan. Pindai aset untuk memeriksa risiko.", "Tidak ada perubahan dependensi.", "Tidak ada komponen dengan versi yang didukung.".

Email notifications are delivered by the backend when a new critical CVE or drift is detected; device push notifications are not part of this implementation. Email delivery failure is shown in alert history and does not discard a scan. Camera permission is requested only after the user opens the QR scanner; manual URL input remains available after refusal or cancellation.

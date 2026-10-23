enum Severity {
  critical('Kritis'),
  high('Tinggi'),
  medium('Sedang'),
  low('Rendah'),
  unknown('Tidak diketahui'),
  safe('Aman');

  const Severity(this.label);
  final String label;
}

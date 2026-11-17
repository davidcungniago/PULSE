class ScanAttempt {
  const ScanAttempt({required this.assetId, this.name, this.error});
  final String assetId;
  final String? name;
  final String? error;

  bool get succeeded => error == null;
}

class ScanReport {
  const ScanReport(this.attempts);
  final List<ScanAttempt> attempts;

  int get succeeded => attempts.where((attempt) => attempt.succeeded).length;
  int get failed => attempts.length - succeeded;
  bool get hasFailures => failed > 0;

  String get summary => hasFailures
      ? '$succeeded dari ${attempts.length} aset selesai.'
      : 'Pemindaian selesai.';
}

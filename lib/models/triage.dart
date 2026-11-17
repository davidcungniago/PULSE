import '../services/dashboard_service.dart';
import '../widgets/status_badge.dart';

enum TriageKind {
  critical('Kritis'),
  drift('Drift'),
  warning('Peringatan'),
  notScanned('Belum dipindai');

  const TriageKind(this.label);
  final String label;
}

class TriageEntry {
  const TriageEntry({required this.kind, required this.asset});
  final TriageKind kind;
  final AssetRiskSummary asset;

  bool get scans => kind == TriageKind.notScanned;

  String get reason => switch (kind) {
        TriageKind.critical => '${asset.criticalVulnerabilityCount} CVE kritis',
        TriageKind.drift => 'Perubahan dependensi',
        TriageKind.warning => 'Peringatan keamanan',
        TriageKind.notScanned => 'Belum pernah dipindai',
      };

  String get actionLabel => switch (kind) {
        TriageKind.critical || TriageKind.warning => 'Lihat temuan',
        TriageKind.drift => 'Lihat perubahan',
        TriageKind.notScanned => 'Pindai sekarang',
      };
}

List<TriageEntry> buildTriageQueue(List<AssetRiskSummary> assets) {
  final entries = <TriageEntry>[];
  for (final asset in assets) {
    TriageKind? kind;
    if (asset.status == RiskStatus.critical) {
      kind = TriageKind.critical;
    } else if (asset.hasDrift) {
      kind = TriageKind.drift;
    } else if (asset.status == RiskStatus.warning) {
      kind = TriageKind.warning;
    } else if (asset.status == RiskStatus.notScanned) {
      kind = TriageKind.notScanned;
    }
    if (kind != null) entries.add(TriageEntry(kind: kind, asset: asset));
  }
  entries.sort((a, b) {
    final byKind = a.kind.index.compareTo(b.kind.index);
    if (byKind != 0) return byKind;
    if (a.kind == TriageKind.critical) {
      final byCount = b.asset.criticalVulnerabilityCount
          .compareTo(a.asset.criticalVulnerabilityCount);
      if (byCount != 0) return byCount;
    }
    return a.asset.name.toLowerCase().compareTo(b.asset.name.toLowerCase());
  });
  return entries;
}

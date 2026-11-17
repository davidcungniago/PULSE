import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/models/triage.dart';
import 'package:pulse/services/dashboard_service.dart';
import 'package:pulse/widgets/status_badge.dart';

void main() {
  test('triage order is critical, drift, warning, never scanned', () {
    final queue = buildTriageQueue([
      _asset('Belum', RiskStatus.notScanned),
      _asset('Peringatan', RiskStatus.warning),
      _asset('Drift', RiskStatus.warning, hasDrift: true),
      _asset('Kritis', RiskStatus.critical, critical: 3),
      _asset('Aman', RiskStatus.healthy),
    ]);
    expect(queue.map((entry) => entry.asset.name),
        ['Kritis', 'Drift', 'Peringatan', 'Belum']);
  });

  test('most critical asset comes first inside the critical bucket', () {
    final queue = buildTriageQueue([
      _asset('Sedikit', RiskStatus.critical, critical: 1),
      _asset('Banyak', RiskStatus.critical, critical: 4),
    ]);
    expect(queue.map((entry) => entry.asset.name), ['Banyak', 'Sedikit']);
    expect(queue.first.reason, '4 CVE kritis');
    expect(queue.first.actionLabel, 'Lihat temuan');
  });

  test('never scanned leads scan directly', () {
    final queue = buildTriageQueue([_asset('Baru', RiskStatus.notScanned)]);
    expect(queue.single.scans, isTrue);
    expect(queue.single.actionLabel, 'Pindai sekarang');
  });

  test('healthy assets do not create a lead', () {
    expect(buildTriageQueue([_asset('Aman', RiskStatus.healthy)]), isEmpty);
  });
}

AssetRiskSummary _asset(String name, RiskStatus status,
        {int critical = 0, bool hasDrift = false}) =>
    AssetRiskSummary(
        assetId: name,
        name: name,
        status: status,
        criticalVulnerabilityCount: critical,
        hasDrift: hasDrift);

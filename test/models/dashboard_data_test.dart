import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/services/dashboard_service.dart';
import 'package:pulse/widgets/status_badge.dart';

void main() {
  test('any critical asset makes the project critical', () {
    final data = _data([
      _asset('Aman', RiskStatus.healthy),
      _asset('Kritis', RiskStatus.critical),
    ]);
    expect(data.status, RiskStatus.critical);
    expect(data.statusLine, '1 aset perlu tindakan');
  });

  test('partially scanned project is warning, fully unscanned is not scanned',
      () {
    final partial = _data([
      _asset('Aman', RiskStatus.healthy),
      _asset('Baru', RiskStatus.notScanned),
    ]);
    expect(partial.status, RiskStatus.warning);
    expect(partial.statusLine, '1 belum dipindai');

    final empty = _data([
      _asset('A', RiskStatus.notScanned),
      _asset('B', RiskStatus.notScanned),
    ]);
    expect(empty.status, RiskStatus.notScanned);
    expect(empty.statusLine, 'Tanpa sinyal. Pindai untuk mulai.');
  });

  test('summary reports drift and missing scans', () {
    final data = _data([
      _asset('Berubah', RiskStatus.warning, hasDrift: true),
      _asset('Baru', RiskStatus.notScanned),
    ]);
    expect(data.statusLine,
        '1 aset berubah sejak pemindaian terakhir · 1 belum dipindai');
  });

  test('fully scanned clean project is calm', () {
    final data = _data([_asset('Aman', RiskStatus.healthy)]);
    expect(data.statusLine, 'Tidak ada tindakan. Denyut stabil.');
  });
}

DashboardData _data(List<AssetRiskSummary> assets) => DashboardData(
    totalAssets: assets.length,
    totalComponents: 0,
    criticalVulnerabilities: 0,
    assetsWithDrift: 0,
    assets: assets);

AssetRiskSummary _asset(String name, RiskStatus status,
        {bool hasDrift = false}) =>
    AssetRiskSummary(
        assetId: name, name: name, status: status, hasDrift: hasDrift);

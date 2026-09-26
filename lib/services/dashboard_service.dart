import '../widgets/status_badge.dart';

class AssetRiskSummary {
  const AssetRiskSummary({required this.assetId, required this.name, required this.status, this.lastScannedAt});
  final String assetId;
  final String name;
  final RiskStatus status;
  final DateTime? lastScannedAt;
}

class DashboardData {
  const DashboardData({required this.totalAssets, required this.totalComponents, required this.criticalVulnerabilities, required this.assetsWithDrift, required this.assets});
  final int totalAssets;
  final int totalComponents;
  final int criticalVulnerabilities;
  final int assetsWithDrift;
  final List<AssetRiskSummary> assets;
}

class DashboardService {
  Future<DashboardData> getDashboard(String projectId) async { await Future<void>.delayed(const Duration(milliseconds: 400)); return DashboardData(totalAssets: 2, totalComponents: 121, criticalVulnerabilities: 2, assetsWithDrift: 1, assets: [AssetRiskSummary(assetId: 'asset-1', name: 'API Utama', status: RiskStatus.critical, lastScannedAt: DateTime.now().subtract(const Duration(hours: 2))), AssetRiskSummary(assetId: 'asset-2', name: 'Aplikasi Web', status: RiskStatus.warning, lastScannedAt: DateTime.now().subtract(const Duration(days: 1)))]); }
}

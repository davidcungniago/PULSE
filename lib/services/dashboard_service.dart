import '../widgets/status_badge.dart';
import 'api_client.dart';
import '../models/date_time_utils.dart';

class AssetRiskSummary {
  const AssetRiskSummary(
      {required this.assetId,
      required this.name,
      required this.status,
      this.lastScannedAt});
  final String assetId;
  final String name;
  final RiskStatus status;
  final DateTime? lastScannedAt;
}

class DashboardData {
  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
        totalAssets: json['TotalAssets'] as int,
        totalComponents: json['TotalComponents'] as int,
        criticalVulnerabilities: json['CriticalVulnerabilities'] as int,
        assetsWithDrift: json['AssetsWithDrift'] as int,
        assets: (json['Assets'] as List)
            .map((item) => AssetRiskSummary(
                  assetId: item['AssetId'] as String,
                  name: item['AssetName'] as String,
                  status: switch (item['RiskStatus']) {
                    'CRITICAL' => RiskStatus.critical,
                    'WARNING' => RiskStatus.warning,
                    'HEALTHY' => RiskStatus.healthy,
                    _ => RiskStatus.notScanned,
                  },
                  lastScannedAt: item['LastScannedAt'] == null
                      ? null
                      : parseUtcIso8601(item['LastScannedAt'] as String)
                          .toLocal(),
                ))
            .toList(),
      );
  const DashboardData(
      {required this.totalAssets,
      required this.totalComponents,
      required this.criticalVulnerabilities,
      required this.assetsWithDrift,
      required this.assets});
  final int totalAssets;
  final int totalComponents;
  final int criticalVulnerabilities;
  final int assetsWithDrift;
  final List<AssetRiskSummary> assets;

  RiskStatus get status {
    for (final status in [
      RiskStatus.critical,
      RiskStatus.warning,
      RiskStatus.healthy
    ]) {
      if (assets.any((asset) => asset.status == status)) return status;
    }
    return RiskStatus.notScanned;
  }

  String get statusLine => switch (status) {
        RiskStatus.notScanned => 'Tanpa sinyal. Pindai untuk mulai.',
        RiskStatus.healthy => 'Tidak ada temuan',
        _ => '$criticalVulnerabilities CVE kritis · $totalAssets aset',
      };
}

class DashboardService {
  DashboardService(this.client);
  final ApiClient client;
  Future<DashboardData> getDashboard(String projectId) async {
    return DashboardData.fromJson((await client.dio
            .get<Map<String, dynamic>>('/api/projects/$projectId/dashboard'))
        .data!);
  }
}

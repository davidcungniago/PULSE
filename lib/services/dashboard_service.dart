import '../widgets/status_badge.dart';
import 'api_client.dart';
import '../models/date_time_utils.dart';

class AssetRiskSummary {
  const AssetRiskSummary(
      {required this.assetId,
      required this.name,
      required this.status,
      this.lastScannedAt,
      this.componentCount = 0,
      this.criticalVulnerabilityCount = 0,
      this.hasDrift = false});
  final String assetId;
  final String name;
  final RiskStatus status;
  final DateTime? lastScannedAt;
  final int componentCount;
  final int criticalVulnerabilityCount;
  final bool hasDrift;
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
                  componentCount: item['ComponentCount'] as int? ?? 0,
                  criticalVulnerabilityCount:
                      item['CriticalVulnerabilityCount'] as int? ?? 0,
                  hasDrift: item['HasDrift'] as bool? ?? false,
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
    if (assets.any((asset) => asset.status == RiskStatus.critical)) {
      return RiskStatus.critical;
    }
    if (assets.any((asset) => asset.status == RiskStatus.warning)) {
      return RiskStatus.warning;
    }
    if (assets.every((asset) => asset.status == RiskStatus.notScanned)) {
      return RiskStatus.notScanned;
    }
    if (assets.any((asset) => asset.status == RiskStatus.notScanned)) {
      return RiskStatus.warning;
    }
    return RiskStatus.healthy;
  }

  int get assetsNeverScanned =>
      assets.where((asset) => asset.status == RiskStatus.notScanned).length;

  String get statusLine {
    if (assets.isEmpty) return 'Tanpa sinyal. Pindai untuk mulai.';
    if (assetsNeverScanned == assets.length) {
      return 'Tanpa sinyal. Pindai untuk mulai.';
    }
    final critical =
        assets.where((asset) => asset.status == RiskStatus.critical).length;
    final drift = assets.where((asset) => asset.hasDrift).length;
    final warning = assets
        .where((asset) => asset.status == RiskStatus.warning && !asset.hasDrift)
        .length;
    final parts = <String>[
      if (critical > 0)
        '$critical aset perlu tindakan'
      else if (drift > 0)
        '$drift aset berubah sejak pemindaian terakhir'
      else if (warning > 0)
        '$warning aset berperingatan',
      if (assetsNeverScanned > 0) '$assetsNeverScanned belum dipindai',
    ];
    if (parts.isEmpty) return 'Tidak ada tindakan. Denyut stabil.';
    return parts.join(' · ');
  }
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

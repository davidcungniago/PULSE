import 'package:pulse/features/monitoring/data/monitoring_repository.dart';
import 'package:pulse/models/monitoring_models.dart';
import 'package:pulse/services/api_client.dart';
import 'package:pulse/services/dashboard_service.dart';
import 'package:pulse/widgets/status_badge.dart';

class FakeMonitoringRepository extends MonitoringRepository {
  FakeMonitoringRepository() : super(ApiClient());
  final scanned = <String>[];
  String? failAsset;

  @override
  Future<DashboardData> dashboard(String id) async => DashboardData(
        totalAssets: 4,
        totalComponents: 128,
        criticalVulnerabilities: 2,
        assetsWithDrift: 1,
        assets: [
          AssetRiskSummary(
              assetId: 'asset-1',
              name: 'API utama',
              status: RiskStatus.critical,
              componentCount: 64,
              criticalVulnerabilityCount: 2,
              lastScannedAt: DateTime.utc(2026, 10, 29, 8)),
          AssetRiskSummary(
              assetId: 'asset-2',
              name: 'Webhook',
              status: RiskStatus.warning,
              componentCount: 32,
              hasDrift: true,
              lastScannedAt: DateTime.utc(2026, 10, 29, 7)),
          AssetRiskSummary(
              assetId: 'asset-3',
              name: 'Worker',
              status: RiskStatus.warning,
              componentCount: 20,
              lastScannedAt: DateTime.utc(2026, 10, 28, 8)),
          const AssetRiskSummary(
              assetId: 'asset-4', name: 'Docs', status: RiskStatus.notScanned),
        ],
      );
  @override
  Future<ScanDetail?> latest(String id) async => ScanDetail.fromJson({
        'Components': [
          {
            'Name': 'example',
            'Version': '1.0',
            'License': 'MIT',
            'HighestSeverity': 'CRITICAL',
            'Vulnerabilities': [
              {'CveId': 'CVE-DEMO'}
            ]
          }
        ],
      }, []);
  @override
  Future<List<AlertEntry>> alerts(String id) async => [
        AlertEntry.fromJson({
          'Type': 'Temuan keamanan',
          'Message': 'Temuan kritis pada API.',
          'DeliveryStatus': 'FAILED',
          'SentAt': '2026-10-23T00:00:00Z',
        })
      ];
  @override
  Future<void> scan(String id) async {
    scanned.add(id);
    if (id == failAsset) throw StateError('offline');
  }
}

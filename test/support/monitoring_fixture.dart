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
  Future<DashboardData> dashboard(String id) async => const DashboardData(
        totalAssets: 1,
        totalComponents: 1,
        criticalVulnerabilities: 1,
        assetsWithDrift: 0,
        assets: [
          AssetRiskSummary(
              assetId: 'asset-1',
              name: 'API utama',
              status: RiskStatus.critical)
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

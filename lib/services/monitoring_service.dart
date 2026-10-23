import 'api_client.dart';
import 'dashboard_service.dart';
import 'scan_service.dart';
import 'alert_service.dart';
import '../models/monitoring_models.dart';

class MonitoringService {
  MonitoringService(this.client);
  final ApiClient client;
  Future<DashboardData> dashboard(String id) =>
      DashboardService(client).getDashboard(id);
  Future<ScanDetail?> latest(String id) =>
      ScanService(client).getLatestScanResult(id);
  Future<List<AlertEntry>> alerts(String id) =>
      AlertService(client).getAlerts(id);
  Future<void> scan(String id) => ScanService(client).startScan(id);
}

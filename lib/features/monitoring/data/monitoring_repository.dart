import '../../../services/api_client.dart';
import '../../../services/dashboard_service.dart';
import '../../../services/monitoring_service.dart';
import '../../../models/monitoring_models.dart';

class MonitoringRepository {
  MonitoringRepository(ApiClient client) : service = MonitoringService(client);
  final MonitoringService service;
  Future<DashboardData> dashboard(String id) => service.dashboard(id);
  Future<ScanDetail?> latest(String id) => service.latest(id);
  Future<List<AlertEntry>> alerts(String id) => service.alerts(id);
  Future<void> scan(String id) => service.scan(id);
}

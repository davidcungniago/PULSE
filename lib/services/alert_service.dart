import '../models/monitoring_models.dart';
import 'api_client.dart';

class AlertService {
  AlertService(this.client);
  final ApiClient client;

  Future<List<AlertEntry>> getAlerts(String id) async =>
      (await client.dio.get<List<dynamic>>('/api/projects/$id/alerts'))
          .data!
          .map((item) => AlertEntry.fromJson(item as Map<String, dynamic>))
          .toList();
}

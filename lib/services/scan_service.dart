import 'package:dio/dio.dart';
import '../models/monitoring_models.dart';
import 'api_client.dart';

class ScanService {
  ScanService(this.client);
  final ApiClient client;

  Future<void> startScan(String id) async {
    await client.dio.post<dynamic>('/api/assets/$id/scan',
        options: Options(receiveTimeout: const Duration(minutes: 5)));
  }

  Future<ScanDetail?> getLatestScanResult(String id) async {
    final response = await client.dio
        .get<Map<String, dynamic>>('/api/assets/$id/scan-results/latest');
    if (response.data == null) return null;
    final drift =
        (await client.dio.get<List<dynamic>>('/api/assets/$id/drift-events'))
            .data!;
    return ScanDetail.fromJson(response.data!, drift);
  }
}

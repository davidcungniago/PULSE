import 'api_client.dart';

class ManagementService {
  ManagementService(this.client);
  final ApiClient client;
  Future<void> updateProject(String id, String name, String description) async {
    await client.dio.put<dynamic>('/api/projects/$id',
        data: {'Name': name, 'Description': description});
  }

  Future<void> deleteProject(String id) async {
    await client.dio.delete<dynamic>('/api/projects/$id');
  }

  Future<void> updateAsset(
      String id, String name, String url, bool active) async {
    await client.dio.put<dynamic>('/api/assets/$id',
        data: {'Name': name, 'RepositoryUrl': url, 'IsActive': active});
  }
}

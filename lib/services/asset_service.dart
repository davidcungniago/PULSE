import 'package:dio/dio.dart';

import '../models/asset_model.dart';
import 'api_client.dart';

class AssetService {
  AssetService({required ApiClient client}) : _dio = client.dio;

  final Dio _dio;

  Future<List<Asset>> getAssets(String projectId) async {
    final response =
        await _dio.get<List<dynamic>>('/api/projects/$projectId/assets');
    final data = response.data;
    if (data == null) {
      throw const FormatException('Respons daftar aset tidak valid.');
    }
    return data
        .map((item) => Asset.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Asset> createAsset(
    String projectId, {
    required String repositoryUrl,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/projects/$projectId/assets',
      data: {'RepositoryUrl': repositoryUrl},
    );
    return Asset.fromJson(response.data!);
  }
}

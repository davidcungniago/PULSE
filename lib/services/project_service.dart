import 'package:dio/dio.dart';

import '../models/project_model.dart';
import 'api_client.dart';

class ProjectService {
  ProjectService({required ApiClient client}) : _dio = client.dio;

  final Dio _dio;

  Future<List<Project>> getProjects() async {
    final response = await _dio.get<List<dynamic>>('/api/projects');
    final data = response.data ?? const [];
    return data
        .map((item) => Project.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Project> createProject({
    required String name,
    required String description,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/projects',
      data: {'Name': name, 'Description': description},
    );
    return Project.fromJson(response.data!);
  }
}

import '../models/project_model.dart';

class ProjectService {
  Future<List<Project>> getProjects() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return [Project(id: 'project-1', name: 'Platform Pembayaran', description: 'Layanan backend utama.', createdAt: DateTime(2026, 9, 1)), Project(id: 'project-2', name: 'Portal Pelanggan', description: 'Aplikasi web pelanggan.', createdAt: DateTime(2026, 9, 10))];
  }
  Future<Project> getProject(String id) async => (await getProjects()).firstWhere((project) => project.id == id, orElse: () => Project(id: id, name: 'Proyek', description: '', createdAt: DateTime.now()));
  Future<Project> createProject({required String name, required String description}) async => Project(id: 'project-baru', name: name, description: description, createdAt: DateTime.now());
  Future<Project> updateProject(String id, {required String name, required String description}) async => Project(id: id, name: name, description: description, createdAt: DateTime.now());
  Future<void> deleteProject(String id) async => Future<void>.delayed(const Duration(milliseconds: 300));
}

import '../../../services/management_service.dart';

class ManagementRepository {
  ManagementRepository(this.service);
  final ManagementService service;
  Future<void> project(String id, String name, String description) =>
      service.updateProject(id, name, description);
  Future<void> remove(String id) => service.deleteProject(id);
  Future<void> asset(String id, String name, String url, bool active) =>
      service.updateAsset(id, name, url, active);
}

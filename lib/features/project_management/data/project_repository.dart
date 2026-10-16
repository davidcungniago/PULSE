import '../../../models/project_model.dart';
import '../../../services/project_service.dart';

class ProjectRepository {
  ProjectRepository({required ProjectService projectService})
      : _projectService = projectService;

  final ProjectService _projectService;

  Future<List<Project>> getProjects() => _projectService.getProjects();

  Future<Project> createProject({
    required String name,
    required String description,
  }) =>
      _projectService.createProject(name: name, description: description);
}

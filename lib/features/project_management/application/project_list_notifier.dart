import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/project_model.dart';
import '../../../services/api_client.dart';
import '../../../services/project_service.dart';
import '../data/project_repository.dart';

final projectRepositoryProvider = Provider<ProjectRepository>(
  (ref) => ProjectRepository(
    projectService: ProjectService(client: ref.watch(apiClientProvider)),
  ),
);

final projectListProvider =
    AsyncNotifierProvider<ProjectListNotifier, List<Project>>(
        ProjectListNotifier.new);

class ProjectListNotifier extends AsyncNotifier<List<Project>> {
  @override
  Future<List<Project>> build() =>
      ref.read(projectRepositoryProvider).getProjects();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(projectRepositoryProvider).getProjects());
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/api_client.dart';
import '../../../services/management_service.dart';
import '../../../services/repository_url.dart';
import '../../monitoring/application/monitoring_notifier.dart';
import '../../project_management/application/project_list_notifier.dart';
import '../../asset_management/application/asset_list_notifier.dart';
import '../data/management_repository.dart';

final managementRepositoryProvider = Provider((ref) =>
    ManagementRepository(ManagementService(ref.read(apiClientProvider))));
final editProvider =
    NotifierProvider.autoDispose<EditNotifier, AsyncValue<bool>>(
        EditNotifier.new);

class EditNotifier extends AutoDisposeNotifier<AsyncValue<bool>> {
  @override
  AsyncValue<bool> build() => const AsyncData(false);
  String? nameError(String? value) =>
      value == null || value.trim().isEmpty ? 'Nama wajib diisi.' : null;
  String? urlError(String? value) => repositoryUrlError(value ?? '');
  Future<void> save(
      {required String id,
      required String name,
      required String detail,
      required bool isAsset,
      required bool active}) async {
    if (state.isLoading) return;
    final error = nameError(name) ?? (isAsset ? urlError(detail) : null);
    if (error != null) {
      state = AsyncError(error, StackTrace.current);
      return;
    }
    await _run(() => isAsset
        ? ref
            .read(managementRepositoryProvider)
            .asset(id, name.trim(), detail.trim(), active)
        : ref
            .read(managementRepositoryProvider)
            .project(id, name.trim(), detail.trim()));
  }

  Future<void> remove(String id) =>
      _run(() => ref.read(managementRepositoryProvider).remove(id));
  Future<void> _run(Future<void> Function() action) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    try {
      await action();
      ref.invalidate(projectListProvider);
      ref.invalidate(assetListProvider);
      ref.invalidate(dashboardProvider);
      state = const AsyncData(true);
    } catch (error, stack) {
      state = AsyncError(monitoringError(error), stack);
    }
  }
}

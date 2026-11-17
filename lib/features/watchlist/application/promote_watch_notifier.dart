import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/project_model.dart';
import '../../../models/watched_repository.dart';
import '../../../services/api_error_mapper.dart';
import '../../asset_management/application/asset_list_notifier.dart';
import '../../monitoring/application/monitoring_notifier.dart';
import 'watchlist_notifier.dart';

enum PromoteWatchStatus { idle, submitting, success, failure }

class PromoteWatchState {
  const PromoteWatchState({
    this.status = PromoteWatchStatus.idle,
    this.projectId,
    this.error,
  });

  final PromoteWatchStatus status;
  final String? projectId;
  final String? error;

  bool get isSubmitting => status == PromoteWatchStatus.submitting;
}

final promoteWatchProvider =
    NotifierProvider<PromoteWatchNotifier, PromoteWatchState>(
        PromoteWatchNotifier.new);

class PromoteWatchNotifier extends Notifier<PromoteWatchState> {
  @override
  PromoteWatchState build() => const PromoteWatchState();

  void reset() => state = const PromoteWatchState();

  Future<bool> promote({
    required WatchedRepository item,
    required Project project,
  }) async {
    if (state.isSubmitting) return false;
    state = PromoteWatchState(
        status: PromoteWatchStatus.submitting, projectId: project.id);
    try {
      await ref
          .read(assetRepositoryProvider)
          .addAsset(project.id, item.repositoryUrl);
    } on DioException catch (error) {
      state = PromoteWatchState(
          status: PromoteWatchStatus.failure,
          projectId: project.id,
          error: mapApiErrorToMessage(error));
      return false;
    } catch (_) {
      state = PromoteWatchState(
          status: PromoteWatchStatus.failure,
          projectId: project.id,
          error: 'Aset gagal ditambahkan. Silakan coba lagi.');
      return false;
    }
    try {
      await ref.read(watchlistProvider.notifier).remove(item.id);
    } catch (_) {
      state = PromoteWatchState(
          status: PromoteWatchStatus.failure,
          projectId: project.id,
          error: 'Aset ditambahkan, tetapi Radar gagal diperbarui.');
      return false;
    }
    ref.invalidate(assetListProvider(project.id));
    ref.invalidate(dashboardProvider(project.id));
    state = PromoteWatchState(
        status: PromoteWatchStatus.success, projectId: project.id);
    return true;
  }
}

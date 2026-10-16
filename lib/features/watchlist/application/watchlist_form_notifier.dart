import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/watched_repository.dart';
import '../../../services/repository_url.dart';
import '../../../services/watchlist_repository.dart';
import 'watchlist_notifier.dart';

enum WatchlistFormStatus { idle, submitting, success, failure }

class WatchlistFormState {
  const WatchlistFormState({
    this.status = WatchlistFormStatus.idle,
    this.editingId,
    this.urlError,
    this.submitError,
    this.isUrlValid = false,
  });

  final WatchlistFormStatus status;
  final String? editingId;
  final String? urlError;
  final String? submitError;
  final bool isUrlValid;

  bool get isEditing => editingId != null;

  bool get canSubmit => isUrlValid && status != WatchlistFormStatus.submitting;
}

final watchlistFormProvider =
    NotifierProvider<WatchlistFormNotifier, WatchlistFormState>(
        WatchlistFormNotifier.new);

class WatchlistFormNotifier extends Notifier<WatchlistFormState> {
  @override
  WatchlistFormState build() => const WatchlistFormState();

  void startAdd() => state = const WatchlistFormState();

  void startEdit(WatchedRepository item) =>
      state = WatchlistFormState(editingId: item.id, isUrlValid: true);

  void reset() => state = const WatchlistFormState();

  void validateUrl(String value) {
    final error = repositoryUrlError(value);
    state = WatchlistFormState(
      status: state.status,
      editingId: state.editingId,
      urlError: error,
      submitError: state.submitError,
      isUrlValid: error == null,
    );
  }

  Future<void> submit({
    required String repositoryUrl,
    required String note,
    required WatchPriority priority,
  }) async {
    final repository = ref.read(watchlistRepositoryProvider);
    final editingId = state.editingId;
    if (editingId == null) {
      validateUrl(repositoryUrl);
      if (state.urlError != null) return;
    }
    if (state.status == WatchlistFormStatus.submitting) return;
    state = WatchlistFormState(
      status: WatchlistFormStatus.submitting,
      editingId: editingId,
      isUrlValid: true,
    );
    try {
      if (editingId == null) {
        await repository.add(
          repositoryUrl: repositoryUrl,
          note: note,
          priority: priority,
        );
      } else {
        await repository.update(
          id: editingId,
          note: note,
          priority: priority,
        );
      }
      await ref.read(watchlistProvider.notifier).refresh();
      state = WatchlistFormState(
          status: WatchlistFormStatus.success, editingId: editingId);
    } on WatchlistException catch (error) {
      state = WatchlistFormState(
        status: WatchlistFormStatus.failure,
        editingId: editingId,
        submitError: error.message,
        isUrlValid: true,
      );
    }
  }
}

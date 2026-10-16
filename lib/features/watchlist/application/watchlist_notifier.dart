import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/watched_repository.dart';
import '../../../services/watchlist_repository.dart';

final watchlistRepositoryProvider = Provider<WatchlistRepository>(
  (ref) => throw UnimplementedError(
      'watchlistRepositoryProvider harus di-override di main.dart.'),
);

final watchlistProvider =
    AsyncNotifierProvider<WatchlistNotifier, List<WatchedRepository>>(
        WatchlistNotifier.new);

class WatchlistNotifier extends AsyncNotifier<List<WatchedRepository>> {
  @override
  Future<List<WatchedRepository>> build() =>
      ref.read(watchlistRepositoryProvider).getWatched();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(watchlistRepositoryProvider).getWatched());
  }

  Future<void> remove(String id) async {
    await ref.read(watchlistRepositoryProvider).remove(id);
    await refresh();
  }
}

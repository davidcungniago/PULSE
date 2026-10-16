import '../models/watched_repository.dart';
import 'repository_url.dart';

class WatchlistException implements Exception {
  const WatchlistException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class WatchlistRepository {
  Future<List<WatchedRepository>> getWatched();

  Future<WatchedRepository> add({
    required String repositoryUrl,
    required String note,
    required WatchPriority priority,
  });

  Future<WatchedRepository> update({
    required String id,
    required String note,
    required WatchPriority priority,
  });

  Future<void> remove(String id);
}

class InMemoryWatchlistRepository implements WatchlistRepository {
  InMemoryWatchlistRepository({List<WatchedRepository>? seed})
      : _items = [...?seed];

  final List<WatchedRepository> _items;
  int _counter = 0;

  @override
  Future<List<WatchedRepository>> getWatched() async =>
      List.unmodifiable(_items);

  @override
  Future<WatchedRepository> add({
    required String repositoryUrl,
    required String note,
    required WatchPriority priority,
  }) async {
    final parsed = parseRepositoryUrl(repositoryUrl);
    final now = DateTime.now().toUtc();
    final created = WatchedRepository(
      id: 'local-${_counter++}',
      repositoryUrl: repositoryUrl.trim(),
      owner: parsed?.owner ?? '',
      repositoryName: parsed?.repositoryName ?? '',
      note: note.trim(),
      priority: priority,
      createdAt: now,
      updatedAt: now,
    );
    _items.add(created);
    return created;
  }

  @override
  Future<WatchedRepository> update({
    required String id,
    required String note,
    required WatchPriority priority,
  }) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw const WatchlistException('Repositori tidak ditemukan.');
    }
    final updated = _items[index].copyWith(
      note: note.trim(),
      priority: priority,
      updatedAt: DateTime.now().toUtc(),
    );
    _items[index] = updated;
    return updated;
  }

  @override
  Future<void> remove(String id) async {
    _items.removeWhere((item) => item.id == id);
  }
}

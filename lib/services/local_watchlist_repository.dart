import '../models/watched_repository.dart';
import 'local_storage_service.dart';
import 'repository_url.dart';
import 'watchlist_repository.dart';

class LocalWatchlistRepository implements WatchlistRepository {
  LocalWatchlistRepository(
    this._storage, {
    required String? userId,
    DateTime Function()? clock,
    String Function()? idGenerator,
  })  : _userId = userId,
        _clock = clock ?? _defaultClock,
        _idGenerator = idGenerator ?? _defaultIdGenerator;

  final LocalStorageService _storage;
  final String? _userId;
  final DateTime Function() _clock;
  final String Function() _idGenerator;

  static DateTime _defaultClock() => DateTime.now().toUtc();

  static String _defaultIdGenerator() =>
      'watch-${DateTime.now().microsecondsSinceEpoch}';

  static const List<Map<String, dynamic>> _seed = [
    {
      'Id': 'seed-express',
      'RepositoryUrl': 'https://github.com/expressjs/express',
      'Owner': 'expressjs',
      'RepositoryName': 'express',
      'Note': 'Framework utama layanan API.',
      'Priority': 'high',
      'CreatedAt': '2026-10-01T00:00:00.000Z',
      'UpdatedAt': '2026-10-01T00:00:00.000Z',
    },
    {
      'Id': 'seed-lodash',
      'RepositoryUrl': 'https://github.com/lodash/lodash',
      'Owner': 'lodash',
      'RepositoryName': 'lodash',
      'Note': 'Pustaka utilitas; pantau CVE prototype pollution.',
      'Priority': 'medium',
      'CreatedAt': '2026-10-02T00:00:00.000Z',
      'UpdatedAt': '2026-10-02T00:00:00.000Z',
    },
  ];

  @override
  Future<List<WatchedRepository>> getWatched() async {
    final userId = _userId;
    if (userId == null) return [];
    final key = _keyFor(userId);
    await _ensureSeed(key);
    return _readItems(key).map(WatchedRepository.fromJson).toList();
  }

  @override
  Future<WatchedRepository> add({
    required String repositoryUrl,
    required String note,
    required WatchPriority priority,
  }) async {
    final key = _requireKey();
    await _ensureSeed(key);
    final normalized = repositoryUrl.trim();
    final error = repositoryUrlError(normalized);
    if (error != null) throw WatchlistException(error);
    final parsed = parseRepositoryUrl(normalized)!;

    final items = _readItems(key);
    final isDuplicate = items.any(
      (item) =>
          (item['RepositoryUrl'] as String).toLowerCase() ==
          normalized.toLowerCase(),
    );
    if (isDuplicate) {
      throw const WatchlistException('Repositori ini sudah ada di Radar.');
    }

    final now = _clock();
    final watched = WatchedRepository(
      id: _idGenerator(),
      repositoryUrl: normalized,
      owner: parsed.owner,
      repositoryName: parsed.repositoryName,
      note: note.trim(),
      priority: priority,
      createdAt: now,
      updatedAt: now,
    );
    await _writeItems(key, [...items, watched.toJson()]);
    return watched;
  }

  @override
  Future<WatchedRepository> update({
    required String id,
    required String note,
    required WatchPriority priority,
  }) async {
    final key = _requireKey();
    final items = _readItems(key);
    final index = items.indexWhere((item) => item['Id'] == id);
    if (index == -1) {
      throw const WatchlistException('Repositori tidak ditemukan.');
    }
    final updated = WatchedRepository.fromJson(items[index]).copyWith(
      note: note.trim(),
      priority: priority,
      updatedAt: _clock(),
    );
    final next = [...items];
    next[index] = updated.toJson();
    await _writeItems(key, next);
    return updated;
  }

  @override
  Future<void> remove(String id) async {
    final key = _requireKey();
    final next = _readItems(key).where((item) => item['Id'] != id).toList();
    await _writeItems(key, next);
  }

  String _requireKey() {
    final userId = _userId;
    if (userId == null) {
      throw const WatchlistException('Masuk untuk mengakses Radar.');
    }
    return _keyFor(userId);
  }

  String _keyFor(String userId) =>
      '${LocalStorageService.watchedRepositoriesKey}:$userId';

  List<Map<String, dynamic>> _readItems(String key) =>
      _storage.readCollection(key);

  Future<void> _writeItems(String key, List<Map<String, dynamic>> items) =>
      _storage.writeCollection(key, items);

  Future<void> _ensureSeed(String key) async {
    if (_storage.hasCollection(key)) return;
    await _writeItems(key, [..._seed]);
  }
}

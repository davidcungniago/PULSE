import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/models/watched_repository.dart';
import 'package:pulse/services/local_storage_service.dart';
import 'package:pulse/services/local_watchlist_repository.dart';
import 'package:pulse/services/watchlist_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('mengisi seed saat collection belum pernah ada', () async {
    final (repository, _) = await _fresh();
    final items = await repository.getWatched();
    expect(items.map((item) => item.repositoryName), ['express', 'lodash']);
  });

  test('menambah repositori dan membacanya kembali setelah dibuat ulang',
      () async {
    final (repository, preferences) = await _fresh();
    await repository.add(
      repositoryUrl: 'https://github.com/axios/axios',
      note: 'HTTP client.',
      priority: WatchPriority.high,
    );

    final reopened = LocalWatchlistRepository(LocalStorageService(preferences));
    final items = await reopened.getWatched();
    final axios = items.firstWhere((item) => item.repositoryName == 'axios');
    expect(axios.owner, 'axios');
    expect(axios.note, 'HTTP client.');
    expect(axios.priority, WatchPriority.high);
  });

  test('mengabaikan akhiran .git dan garis miring di akhir', () async {
    final (repository, _) = await _fresh();
    final added = await repository.add(
      repositoryUrl: 'https://github.com/foo/bar.git/',
      note: '',
      priority: WatchPriority.medium,
    );
    expect(added.owner, 'foo');
    expect(added.repositoryName, 'bar');
  });

  test('mengubah catatan dan prioritas', () async {
    final (repository, _) = await _fresh();
    final target = (await repository.getWatched()).first;

    final updated = await repository.update(
      id: target.id,
      note: 'Catatan baru.',
      priority: WatchPriority.low,
    );

    expect(updated.note, 'Catatan baru.');
    expect(updated.priority, WatchPriority.low);
    final reloaded = await repository.getWatched();
    final stored = reloaded.firstWhere((item) => item.id == target.id);
    expect(stored.note, 'Catatan baru.');
    expect(stored.priority, WatchPriority.low);
  });

  test('menghapus repositori', () async {
    final (repository, _) = await _fresh();
    final target = (await repository.getWatched()).first;

    await repository.remove(target.id);

    final remaining = await repository.getWatched();
    expect(remaining.any((item) => item.id == target.id), isFalse);
  });

  test('menolak URL kosong', () async {
    final (repository, _) = await _fresh();
    await expectLater(
      repository.add(
          repositoryUrl: '   ', note: '', priority: WatchPriority.low),
      throwsA(isA<WatchlistException>().having(
          (error) => error.message, 'message', 'URL repositori wajib diisi.')),
    );
  });

  test('menolak URL yang bukan GitHub/GitLab', () async {
    final (repository, _) = await _fresh();
    await expectLater(
      repository.add(
          repositoryUrl: 'https://evilgithub.com/a/b',
          note: '',
          priority: WatchPriority.low),
      throwsA(isA<WatchlistException>().having((error) => error.message,
          'message', 'Gunakan URL GitHub atau GitLab yang valid.')),
    );
  });

  test('menolak repositori duplikat', () async {
    final (repository, _) = await _fresh();
    await expectLater(
      repository.add(
          repositoryUrl: 'https://github.com/expressjs/express',
          note: '',
          priority: WatchPriority.low),
      throwsA(isA<WatchlistException>().having((error) => error.message,
          'message', 'Repositori ini sudah ada di daftar pantau.')),
    );
  });

  test('tidak mengisi ulang seed setelah semua record dihapus', () async {
    final (repository, _) = await _fresh();
    for (final item in await repository.getWatched()) {
      await repository.remove(item.id);
    }

    expect(await repository.getWatched(), isEmpty);
  });
}

Future<(LocalWatchlistRepository, SharedPreferences)> _fresh() async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  var counter = 0;
  final repository = LocalWatchlistRepository(
    LocalStorageService(preferences),
    clock: () => DateTime.utc(2026, 10, 15, 8),
    idGenerator: () => 'test-${counter++}',
  );
  return (repository, preferences);
}

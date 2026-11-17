import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/watchlist/application/watchlist_form_notifier.dart';
import 'package:pulse/features/watchlist/application/watchlist_notifier.dart';
import 'package:pulse/models/user_model.dart';
import 'package:pulse/models/watched_repository.dart';
import 'package:pulse/services/local_storage_service.dart';
import 'package:pulse/services/local_watchlist_repository.dart';
import 'package:pulse/services/session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('pergantian akun memuat ulang daftar dan mereset form Radar', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final session = SessionStore(const FlutterSecureStorage())
      ..user = const User(id: 'user-a', email: 'a@example.com')
      ..restoring = false;
    final container = ProviderContainer(overrides: [
      sessionStoreProvider.overrideWith((ref) => session),
      watchlistRepositoryProvider.overrideWith((ref) {
        final userId = ref.watch(
          sessionStoreProvider.select((store) => store.user?.id),
        );
        return LocalWatchlistRepository(
          LocalStorageService(preferences),
          userId: userId,
        );
      }),
    ]);
    addTearDown(container.dispose);

    await container.read(watchlistProvider.future);
    await container.read(watchlistRepositoryProvider).add(
          repositoryUrl: 'https://github.com/dart-lang/sdk',
          note: 'Catatan akun pertama',
          priority: WatchPriority.high,
        );
    container.invalidate(watchlistProvider);
    expect(
      (await container.read(watchlistProvider.future))
          .any((item) => item.note == 'Catatan akun pertama'),
      isTrue,
    );
    container.read(watchlistFormProvider.notifier).validateUrl('invalid');
    expect(container.read(watchlistFormProvider).urlError, isNotNull);

    session.user = const User(id: 'user-b', email: 'b@example.com');
    session.notifyListeners();

    expect(
      (await container.read(watchlistProvider.future))
          .any((item) => item.note == 'Catatan akun pertama'),
      isFalse,
    );
    expect(container.read(watchlistFormProvider).urlError, isNull);

    session.user = const User(id: 'user-a', email: 'a@example.com');
    session.notifyListeners();
    expect(
      (await container.read(watchlistProvider.future))
          .any((item) => item.note == 'Catatan akun pertama'),
      isTrue,
    );
  });
}

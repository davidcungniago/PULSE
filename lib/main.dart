import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'features/watchlist/application/watchlist_notifier.dart';
import 'services/local_storage_service.dart';
import 'services/local_watchlist_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        watchlistRepositoryProvider.overrideWithValue(
          LocalWatchlistRepository(LocalStorageService(preferences)),
        ),
      ],
      child: const PulseApp(),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/watchlist/application/watchlist_notifier.dart';
import 'package:pulse/features/watchlist/presentation/watchlist_screen.dart';
import 'package:pulse/models/watched_repository.dart';
import 'package:pulse/services/watchlist_repository.dart';

void main() {
  testWidgets('menampilkan daftar repositori yang dipantau', (tester) async {
    await _pump(tester, InMemoryWatchlistRepository(seed: [_item()]));
    expect(find.text('express'), findsOneWidget);
  });

  testWidgets('menampilkan empty state saat daftar kosong', (tester) async {
    await _pump(tester, InMemoryWatchlistRepository());
    expect(find.text('Belum ada repositori yang dipantau.'), findsOneWidget);
  });

  testWidgets('menambah repositori lewat form', (tester) async {
    await _pump(tester, InMemoryWatchlistRepository());

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextFormField).first, 'https://github.com/axios/axios');
    await tester.pump();
    await tester.tap(find.text('Tambah ke Daftar'));
    await tester.pumpAndSettle();

    expect(find.text('axios'), findsOneWidget);
  });

  testWidgets('mengubah catatan repositori', (tester) async {
    await _pump(tester, InMemoryWatchlistRepository(seed: [_item()]));

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextFormField).first, 'Catatan diperbarui.');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Catatan diperbarui.'), findsOneWidget);
  });

  testWidgets('menghapus repositori setelah konfirmasi', (tester) async {
    await _pump(tester, InMemoryWatchlistRepository(seed: [_item()]));

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();

    expect(find.text('express'), findsNothing);
    expect(find.text('Belum ada repositori yang dipantau.'), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester,
  WatchlistRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [watchlistRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: WatchlistScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

WatchedRepository _item() => WatchedRepository(
      id: 'watched-1',
      repositoryUrl: 'https://github.com/expressjs/express',
      owner: 'expressjs',
      repositoryName: 'express',
      note: 'Framework utama layanan API.',
      priority: WatchPriority.high,
      createdAt: DateTime.utc(2026, 10, 1),
      updatedAt: DateTime.utc(2026, 10, 1),
    );

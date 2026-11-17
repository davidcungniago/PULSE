import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/asset_management/application/asset_list_notifier.dart';
import 'package:pulse/features/asset_management/data/asset_repository.dart';
import 'package:pulse/features/project_management/application/project_list_notifier.dart';
import 'package:pulse/features/project_management/data/project_repository.dart';
import 'package:pulse/features/watchlist/application/watchlist_notifier.dart';
import 'package:pulse/features/watchlist/presentation/watchlist_screen.dart';
import 'package:pulse/models/asset_model.dart';
import 'package:pulse/models/project_model.dart';
import 'package:pulse/models/watched_repository.dart';
import 'package:pulse/services/api_client.dart';
import 'package:pulse/services/asset_service.dart';
import 'package:pulse/services/project_service.dart';
import 'package:pulse/services/watchlist_repository.dart';

void main() {
  testWidgets('menampilkan daftar repositori yang dipantau', (tester) async {
    await _pump(tester, InMemoryWatchlistRepository(seed: [_item()]));
    expect(find.text('express'), findsOneWidget);
  });

  testWidgets('menampilkan empty state saat daftar kosong', (tester) async {
    await _pump(tester, InMemoryWatchlistRepository());
    expect(find.text('Belum ada repositori di Radar.'), findsOneWidget);
  });

  testWidgets('menambah repositori lewat form', (tester) async {
    await _pump(tester, InMemoryWatchlistRepository());

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextFormField).first, 'https://github.com/axios/axios');
    await tester.pump();
    await tester.tap(find.text('Tambah'));
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
    expect(find.text('Belum ada repositori di Radar.'), findsOneWidget);
  });

  testWidgets('menjadikan repositori sebagai aset lalu menghapusnya dari Radar',
      (tester) async {
    final assets = _FakeAssetRepository();
    await _pump(
      tester,
      InMemoryWatchlistRepository(seed: [_item()]),
      projects: [_project()],
      assets: assets,
    );

    await tester.tap(find.text('Jadikan aset'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih proyek untuk express.'), findsOneWidget);

    await tester.tap(find.text('Platform pembayaran'));
    await tester.pumpAndSettle();

    expect(assets.added, ['project-1|https://github.com/expressjs/express']);
    expect(find.text('express'), findsNothing);
    expect(
        find.text('Aset ditambahkan ke Platform pembayaran.'), findsOneWidget);
  });

  testWidgets('kegagalan promosi mempertahankan item dan menampilkan pesan',
      (tester) async {
    final assets = _FakeAssetRepository()
      ..error = DioException(
        requestOptions: RequestOptions(path: '/api/projects/project-1/assets'),
        response: Response<Map<String, dynamic>>(
          requestOptions:
              RequestOptions(path: '/api/projects/project-1/assets'),
          statusCode: 409,
          data: {'Message': 'URL repositori ini sudah ada di proyek ini.'},
        ),
      );
    await _pump(
      tester,
      InMemoryWatchlistRepository(seed: [_item()]),
      projects: [_project()],
      assets: assets,
    );

    await tester.tap(find.text('Jadikan aset'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Platform pembayaran'));
    await tester.pumpAndSettle();

    expect(find.text('URL repositori ini sudah ada di proyek ini.'),
        findsOneWidget);
    expect(find.text('express'), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester,
  WatchlistRepository repository, {
  List<Project> projects = const [],
  _FakeAssetRepository? assets,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        watchlistRepositoryProvider.overrideWithValue(repository),
        projectRepositoryProvider
            .overrideWithValue(_FakeProjectRepository(projects)),
        assetRepositoryProvider
            .overrideWithValue(assets ?? _FakeAssetRepository()),
      ],
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

Project _project() => Project(
      id: 'project-1',
      name: 'Platform pembayaran',
      description: 'Layanan backend utama.',
      createdAt: DateTime.utc(2026, 10, 1),
    );

class _FakeProjectRepository extends ProjectRepository {
  _FakeProjectRepository(this.projects)
      : super(projectService: ProjectService(client: ApiClient()));

  final List<Project> projects;

  @override
  Future<List<Project>> getProjects() async => projects;
}

class _FakeAssetRepository extends AssetRepository {
  _FakeAssetRepository()
      : super(assetService: AssetService(client: ApiClient()));

  final List<String> added = [];
  Object? error;

  @override
  Future<List<Asset>> getAssets(String projectId) async => [];

  @override
  Future<Asset> addAsset(String projectId, String repositoryUrl) async {
    if (error != null) throw error!;
    added.add('$projectId|$repositoryUrl');
    return Asset(
      id: 'asset-1',
      projectId: projectId,
      name: 'express',
      repositoryUrl: repositoryUrl,
      owner: 'expressjs',
      repositoryName: 'express',
      isActive: true,
    );
  }
}

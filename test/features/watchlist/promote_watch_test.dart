import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/asset_management/application/asset_list_notifier.dart';
import 'package:pulse/features/asset_management/data/asset_repository.dart';
import 'package:pulse/features/watchlist/application/promote_watch_notifier.dart';
import 'package:pulse/features/watchlist/application/watchlist_notifier.dart';
import 'package:pulse/models/asset_model.dart';
import 'package:pulse/models/project_model.dart';
import 'package:pulse/models/watched_repository.dart';
import 'package:pulse/services/api_client.dart';
import 'package:pulse/services/asset_service.dart';
import 'package:pulse/services/watchlist_repository.dart';

void main() {
  test('promosi membuat aset lalu menghapus item dari Radar', () async {
    final assets = _FakeAssetRepository();
    final watchlist = InMemoryWatchlistRepository(seed: [_item()]);
    final container = _container(assets, watchlist);
    addTearDown(container.dispose);
    container.listen(promoteWatchProvider, (_, __) {});

    final promoted = await container
        .read(promoteWatchProvider.notifier)
        .promote(item: _item(), project: _project());

    expect(promoted, isTrue);
    expect(assets.added, ['project-1|https://github.com/expressjs/express']);
    expect(await watchlist.getWatched(), isEmpty);
    expect(container.read(promoteWatchProvider).status,
        PromoteWatchStatus.success);
  });

  test('kegagalan membuat aset mempertahankan item dan memakai pesan API',
      () async {
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
    final watchlist = InMemoryWatchlistRepository(seed: [_item()]);
    final container = _container(assets, watchlist);
    addTearDown(container.dispose);
    container.listen(promoteWatchProvider, (_, __) {});

    final promoted = await container
        .read(promoteWatchProvider.notifier)
        .promote(item: _item(), project: _project());

    expect(promoted, isFalse);
    expect(await watchlist.getWatched(), isNotEmpty);
    final state = container.read(promoteWatchProvider);
    expect(state.status, PromoteWatchStatus.failure);
    expect(state.error, 'URL repositori ini sudah ada di proyek ini.');
  });
}

ProviderContainer _container(
        _FakeAssetRepository assets, WatchlistRepository watchlist) =>
    ProviderContainer(overrides: [
      assetRepositoryProvider.overrideWithValue(assets),
      watchlistRepositoryProvider.overrideWithValue(watchlist),
    ]);

WatchedRepository _item() => WatchedRepository(
      id: 'watched-1',
      repositoryUrl: 'https://github.com/expressjs/express',
      owner: 'expressjs',
      repositoryName: 'express',
      note: '',
      priority: WatchPriority.medium,
      createdAt: DateTime.utc(2026, 10, 1),
      updatedAt: DateTime.utc(2026, 10, 1),
    );

Project _project() => Project(
      id: 'project-1',
      name: 'Platform pembayaran',
      description: '',
      createdAt: DateTime.utc(2026, 10, 1),
    );

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

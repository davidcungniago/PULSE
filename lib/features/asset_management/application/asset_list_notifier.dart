import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/asset_model.dart';
import '../data/asset_repository.dart';

final assetRepositoryProvider = Provider<AssetRepository>((ref) => AssetRepository());

final assetListProvider = AsyncNotifierProvider.family<AssetListNotifier, List<Asset>, String>(AssetListNotifier.new);

class AssetListNotifier extends FamilyAsyncNotifier<List<Asset>, String> {
  @override
  Future<List<Asset>> build(String projectId) => ref.read(assetRepositoryProvider).getAssets(projectId);

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(assetRepositoryProvider).getAssets(arg));
  }

  void showDemoLoading() => state = const AsyncLoading();

  void showDemoEmpty() => state = const AsyncData([]);

  void showDemoError() => state = AsyncError(StateError('Mode demo'), StackTrace.current);
}

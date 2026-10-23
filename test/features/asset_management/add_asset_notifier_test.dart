import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/asset_management/application/add_asset_notifier.dart';
import 'package:pulse/features/asset_management/application/asset_list_notifier.dart';
import 'package:pulse/models/asset_model.dart';
import 'asset_list_screen_test.dart' show FakeAssetRepository;

class CountingRepository extends FakeAssetRepository {
  int calls = 0;
  final completion = Completer<Asset>();
  @override
  Future<Asset> addAsset(String projectId, String url) {
    calls++;
    return completion.future;
  }
}

void main() {
  test('submit ganda dan edit URL saat mengirim tidak mengulang request',
      () async {
    final repository = CountingRepository();
    final container = ProviderContainer(
        overrides: [assetRepositoryProvider.overrideWithValue(repository)]);
    addTearDown(container.dispose);
    final notifier = container.read(addAssetProvider('p').notifier);
    final first = notifier.submit('https://github.com/pulse/api');
    notifier.validateRepositoryUrl('invalid');
    await notifier.submit('https://github.com/pulse/api');
    expect(repository.calls, 1);
    expect(container.read(addAssetProvider('p')).status,
        AddAssetStatus.submitting);
    repository.completion.completeError(StateError('offline'));
    await first;
    expect(
        container.read(addAssetProvider('p')).status, AddAssetStatus.failure);
    expect(container.read(addAssetProvider('p')).submitError, isNotNull);
  });
}

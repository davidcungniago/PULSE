import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/monitoring/application/monitoring_notifier.dart';
import 'package:pulse/services/dashboard_service.dart';
import 'package:pulse/widgets/status_badge.dart';
import '../support/monitoring_fixture.dart';

void main() {
  test('pindai semua tetap melanjutkan aset berikutnya setelah gagal',
      () async {
    final repository = FakeMonitoringRepository()..failAsset = 'a';
    final container = ProviderContainer(overrides: [
      monitoringRepositoryProvider.overrideWithValue(repository)
    ]);
    addTearDown(container.dispose);
    final notifier = container.read(scanActionProvider('p').notifier);
    final future = notifier.scanAll(const [
      AssetRiskSummary(assetId: 'a', name: 'A', status: RiskStatus.notScanned),
      AssetRiskSummary(assetId: 'b', name: 'B', status: RiskStatus.notScanned),
    ]);
    expect(container.read(scanActionProvider('p')).isLoading, isTrue);
    final report = await future;
    expect(repository.scanned, ['a', 'b']);
    expect(report, isNotNull);
    expect(report!.succeeded, 1);
    expect(report.failed, 1);
    expect(report.attempts.first.error, isNotNull);
    expect(container.read(scanActionProvider('p')).value?.hasFailures, isTrue);
  });
}

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/monitoring_models.dart';
import '../../../services/api_client.dart';
import '../../../services/api_error_mapper.dart';
import '../../../services/dashboard_service.dart';
import '../../asset_management/application/asset_list_notifier.dart';
import '../data/monitoring_repository.dart';

final monitoringRepositoryProvider =
    Provider((ref) => MonitoringRepository(ref.read(apiClientProvider)));
final dashboardProvider = FutureProvider.autoDispose
    .family<DashboardData, String>(
        (ref, id) => ref.read(monitoringRepositoryProvider).dashboard(id));
final scanDetailProvider = FutureProvider.autoDispose
    .family<ScanDetail?, String>(
        (ref, id) => ref.read(monitoringRepositoryProvider).latest(id));
final alertsProvider = FutureProvider.autoDispose
    .family<List<AlertEntry>, String>(
        (ref, id) => ref.read(monitoringRepositoryProvider).alerts(id));
final scanActionProvider =
    NotifierProvider.family<ScanActionNotifier, AsyncValue<String?>, String>(
        ScanActionNotifier.new);

String monitoringError(Object error) => error is DioException
    ? mapApiErrorToMessage(error)
    : 'Data tidak dapat dimuat. Coba lagi.';

class ScanActionNotifier extends FamilyNotifier<AsyncValue<String?>, String> {
  @override
  AsyncValue<String?> build(String id) => const AsyncData(null);

  Future<void> scanOne(String assetId) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    try {
      await ref.read(monitoringRepositoryProvider).scan(assetId);
      ref.invalidate(scanDetailProvider(assetId));
      ref.invalidate(dashboardProvider);
      ref.invalidate(assetListProvider);
      ref.invalidate(alertsProvider);
      state = const AsyncData('Pemindaian selesai.');
    } catch (error, stack) {
      state = AsyncError(monitoringError(error), stack);
    }
  }

  Future<void> scanAll(List<AssetRiskSummary> assets) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final failures = <String>[];
    for (final asset in assets) {
      try {
        await ref.read(monitoringRepositoryProvider).scan(asset.assetId);
        ref.invalidate(scanDetailProvider(asset.assetId));
      } catch (error) {
        failures.add('${asset.name}: ${monitoringError(error)}');
      }
    }
    ref.invalidate(dashboardProvider(arg));
    ref.invalidate(assetListProvider(arg));
    ref.invalidate(alertsProvider(arg));
    state = AsyncData(failures.isEmpty
        ? 'Pemindaian selesai.'
        : '${assets.length - failures.length}/${assets.length} aset selesai.\n${failures.join('\n')}');
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/monitoring/application/monitoring_notifier.dart';
import '../widgets/constrained_page.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/primary_button.dart';
import '../widgets/severity_badge.dart';
import '../theme/pulse_typography.dart';

class ScanResultDetailScreen extends ConsumerWidget {
  const ScanResultDetailScreen({super.key, required this.assetId});
  final String assetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(scanDetailProvider(assetId));
    final action = ref.watch(scanActionProvider(assetId));
    return Scaffold(
      appBar: AppBar(title: const Text('Hasil pemindaian')),
      body: ConstrainedPage(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                PrimaryButton(
                  label: action.hasError ? 'Coba Lagi' : 'Pindai sekarang',
                  isLoading: action.isLoading,
                  onPressed: () => ref
                      .read(scanActionProvider(assetId).notifier)
                      .scanOne(assetId),
                ),
                if (action.hasError)
                  Text('${action.error}',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                if (action.valueOrNull != null) Text(action.valueOrNull!),
              ]),
            ),
            Expanded(
              child: detail.when(
                loading: () => const LoadingIndicator(),
                error: (error, _) => ErrorState(
                    message: monitoringError(error),
                    onRetry: () => ref.invalidate(scanDetailProvider(assetId))),
                data: (data) {
                  if (data == null) {
                    return const EmptyState(
                        message: 'Belum pernah dipindai. Pindai untuk mulai.');
                  }
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text('Komponen',
                          style: Theme.of(context).textTheme.titleLarge),
                      if (data.components.isEmpty)
                        const EmptyState(
                            message:
                                'Tidak ada komponen dengan versi yang didukung.'),
                      ...data.components.map((component) => Card(
                            child: ListTile(
                              title: Text(
                                  '${component.name}@${component.version}',
                                  style: PulseTypography.mono),
                              subtitle: Text(
                                  'Lisensi: ${component.license}\n${component.cveIds.join(", ")}'),
                              trailing:
                                  SeverityBadge(severity: component.severity),
                            ),
                          )),
                      const SizedBox(height: 24),
                      Text('Perubahan dependensi',
                          style: Theme.of(context).textTheme.titleLarge),
                      if (data.drift.isEmpty)
                        const Text('Tidak ada perubahan dependensi.'),
                      ...data.drift.map((event) => Card(
                              child: ListTile(
                            title: Text('${event.label}: ${event.name}'),
                            subtitle: Text(event.details),
                          ))),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

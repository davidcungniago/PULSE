import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/monitoring/application/monitoring_notifier.dart';
import '../widgets/constrained_page.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_indicator.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key, required this.projectId});
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: const Text('Riwayat peringatan')),
        body: ConstrainedPage(
          child: ref.watch(alertsProvider(projectId)).when(
                loading: () => const LoadingIndicator(),
                error: (error, _) => ErrorState(
                    message: monitoringError(error),
                    onRetry: () => ref.invalidate(alertsProvider(projectId))),
                data: (alerts) => alerts.isEmpty
                    ? const EmptyState(
                        message:
                            'Belum ada peringatan. Pindai aset untuk memeriksa risiko.')
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: alerts.length,
                        itemBuilder: (context, index) {
                          final alert = alerts[index];
                          return Card(
                              child: ListTile(
                            title: Text(alert.type),
                            subtitle: Text(
                                '${alert.message}\n${alert.deliveryLabel}\n${alert.sentAt.toLocal()}'),
                          ));
                        },
                      ),
              ),
        ),
      );
}

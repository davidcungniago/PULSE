import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/monitoring/application/monitoring_notifier.dart';
import '../widgets/error_state.dart';
import '../widgets/empty_state.dart';
import '../widgets/constrained_page.dart';
import 'package:go_router/go_router.dart';

import '../widgets/loading_indicator.dart';
import '../widgets/primary_button.dart';
import '../widgets/pulse_banner.dart';
import '../widgets/vital_tile.dart';
import '../widgets/asset_card.dart';
import '../services/stable_hash.dart';

class ProjectDashboardScreen extends ConsumerStatefulWidget {
  const ProjectDashboardScreen({super.key, required this.projectId});
  final String projectId;

  @override
  ConsumerState<ProjectDashboardScreen> createState() =>
      _ProjectDashboardScreenState();
}

class _ProjectDashboardScreenState
    extends ConsumerState<ProjectDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(dashboardProvider(widget.projectId));
    final scan = ref.watch(scanActionProvider(widget.projectId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ringkasan Proyek'),
        actions: [
          IconButton(
              onPressed: () =>
                  context.push('/projects/${widget.projectId}/alerts'),
              icon: const Icon(Icons.notifications_outlined))
        ],
      ),
      body: ConstrainedPage(
          child: dashboard.when(
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorState(
            message: monitoringError(error),
            onRetry: () => ref.invalidate(dashboardProvider(widget.projectId))),
        data: (data) {
          if (data.assets.isEmpty) {
            return EmptyState(
                message:
                    'Belum ada aset. Tambahkan repository untuk mulai memantau.',
                actionLabel: 'Tambah aset',
                onAction: () =>
                    context.push('/projects/${widget.projectId}/assets'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              PulseBanner(
                status: data.status,
                seed: stableHash(widget.projectId),
                sub: data.statusLine,
                hasDrift: data.assetsWithDrift > 0,
                scanning: scan.isLoading,
                animate: true,
              ),
              const SizedBox(height: 16),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                    child: VitalTile(
                        value: '${data.totalComponents}', label: 'Komponen')),
                const SizedBox(width: 8),
                Expanded(
                    child: VitalTile(
                        value: '${data.criticalVulnerabilities}',
                        label: 'CVE kritis')),
                const SizedBox(width: 8),
                Expanded(
                    child: VitalTile(
                        value: '${data.assetsWithDrift}', label: 'Drift')),
              ]),
              const SizedBox(height: 16),
              PrimaryButton(
                  label: 'Pindai Semua Aset',
                  onPressed: () => ref
                      .read(scanActionProvider(widget.projectId).notifier)
                      .scanAll(data.assets),
                  isLoading: scan.isLoading,
                  icon: Icons.radar),
              const SizedBox(height: 24),
              if (scan.hasValue && scan.value != null) Text(scan.value!),
              if (scan.hasError) Text('${scan.error}'),
              Text('Aset', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ...data.assets.map(
                (asset) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AssetCard(
                    name: asset.name,
                    status: asset.status,
                    timeLabel: asset.lastScannedAt == null
                        ? 'Belum pernah dipindai'
                        : 'Dipindai ${asset.lastScannedAt!.hour.toString().padLeft(2, '0')}:${asset.lastScannedAt!.minute.toString().padLeft(2, '0')}',
                    onTap: () => context.push(
                        '/projects/${widget.projectId}/scan-results/${asset.assetId}'),
                  ),
                ),
              ),
              TextButton.icon(
                  onPressed: () =>
                      context.push('/projects/${widget.projectId}/assets'),
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('Kelola aset')),
            ],
          );
        },
      )),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/monitoring/application/monitoring_notifier.dart';
import '../models/date_time_utils.dart';
import '../models/triage.dart';
import '../services/dashboard_service.dart';
import '../services/stable_hash.dart';
import '../theme/pulse_colors.dart';
import '../widgets/asset_card.dart';
import '../widgets/constrained_page.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/primary_button.dart';
import '../widgets/pulse_banner.dart';
import '../widgets/scan_report_sheet.dart';
import '../widgets/status_badge.dart';
import '../widgets/triage_card.dart';
import '../widgets/vital_line.dart';

class ProjectDashboardScreen extends ConsumerStatefulWidget {
  const ProjectDashboardScreen({super.key, required this.projectId});
  final String projectId;

  @override
  ConsumerState<ProjectDashboardScreen> createState() =>
      _ProjectDashboardScreenState();
}

class _ProjectDashboardScreenState
    extends ConsumerState<ProjectDashboardScreen> {
  bool _showAllTriage = false;

  Future<void> _scan(List<AssetRiskSummary> assets) async {
    if (ref.read(scanActionProvider(widget.projectId)).isLoading) return;
    final report = await ref
        .read(scanActionProvider(widget.projectId).notifier)
        .scanAll(assets);
    if (!mounted || report == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ScanReportSheet(report: report),
    );
  }

  DateTime? _latestScan(List<AssetRiskSummary> assets) {
    DateTime? latest;
    for (final asset in assets) {
      final time = asset.lastScannedAt;
      if (time != null && (latest == null || time.isAfter(latest))) {
        latest = time;
      }
    }
    return latest;
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(dashboardProvider(widget.projectId));
    final scan = ref.watch(scanActionProvider(widget.projectId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ringkasan proyek'),
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
                    'Belum ada aset. Tambahkan repositori untuk mulai memantau.',
                actionLabel: 'Tambah aset',
                onAction: () =>
                    context.push('/projects/${widget.projectId}/assets'));
          }
          final triage = buildTriageQueue(data.assets);
          final visible = _showAllTriage ? triage : triage.take(3).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              PulseBanner(
                status: data.status,
                seed: stableHash(widget.projectId),
                sub: data.statusLine,
                hasDrift: data.assets.any((asset) => asset.hasDrift),
                scanning: scan.isLoading,
                animate: true,
              ),
              const SizedBox(height: 12),
              VitalLine(items: [
                VitalLineItem('${data.totalAssets}', 'aset'),
                VitalLineItem('${data.totalComponents}', 'komponen'),
                VitalLineItem('${data.criticalVulnerabilities}', 'kritis',
                    highlight: data.criticalVulnerabilities > 0),
                VitalLineItem('${data.assetsWithDrift}', 'drift'),
              ]),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: Text('Perlu tindakan',
                      style: Theme.of(context).textTheme.titleSmall),
                ),
                if (triage.length > 3)
                  TextButton(
                      onPressed: () =>
                          setState(() => _showAllTriage = !_showAllTriage),
                      child: Text(_showAllTriage
                          ? 'Ringkas'
                          : 'Lihat semua (${triage.length})')),
              ]),
              const SizedBox(height: 8),
              if (triage.isEmpty)
                _CalmCard(lastScannedAt: _latestScan(data.assets))
              else
                ...visible.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TriageCard(
                        entry: entry,
                        onAction: () {
                          if (entry.scans) {
                            _scan([entry.asset]);
                          } else {
                            context.push(
                                '/projects/${widget.projectId}/scan-results/${entry.asset.assetId}');
                          }
                        },
                      ),
                    )),
              const SizedBox(height: 16),
              PrimaryButton(
                  label: 'Pindai semua aset',
                  onPressed: () => _scan(data.assets),
                  isLoading: scan.isLoading,
                  icon: Icons.radar),
              if (scan.hasError) ...[
                const SizedBox(height: 8),
                Text('${scan.error}',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 24),
              Text('Aset (${data.totalAssets})',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ...data.assets.map(
                (asset) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AssetCard(
                    name: asset.name,
                    status: asset.status,
                    timeLabel: asset.lastScannedAt == null
                        ? 'Belum pernah dipindai'
                        : 'Dipindai ${relativeTimeLabel(asset.lastScannedAt!)}',
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

class _CalmCard extends StatelessWidget {
  const _CalmCard({this.lastScannedAt});
  final DateTime? lastScannedAt;

  @override
  Widget build(BuildContext context) {
    final colors = PulseColors.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.check_circle_outline,
              size: 20, color: colors.riskText(RiskStatus.healthy)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tidak ada tindakan. Denyut stabil.',
                    style: Theme.of(context).textTheme.labelLarge),
                if (lastScannedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                      'Terakhir dipindai ${relativeTimeLabel(lastScannedAt!)}.',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

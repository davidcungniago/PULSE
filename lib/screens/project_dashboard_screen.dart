import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/dashboard_service.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/primary_button.dart';
import '../widgets/risk_summary_card.dart';
import '../widgets/status_badge.dart';

class ProjectDashboardScreen extends StatefulWidget {
  const ProjectDashboardScreen({super.key, required this.projectId});
  final String projectId;

  @override
  State<ProjectDashboardScreen> createState() => _ProjectDashboardScreenState();
}

class _ProjectDashboardScreenState extends State<ProjectDashboardScreen> {
  bool _isScanning = false;

  Future<void> _scanAllAssets() async {
    if (_isScanning) return;
    setState(() => _isScanning = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _isScanning = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pemindaian selesai (mode simulasi).')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ringkasan Proyek'),
        actions: [IconButton(onPressed: () => context.push('/projects/${widget.projectId}/alerts'), icon: const Icon(Icons.notifications_outlined))],
      ),
      body: FutureBuilder(
        future: DashboardService().getDashboard(widget.projectId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LoadingIndicator();
          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  RiskSummaryCard(value: '${data.totalAssets}', label: 'Total aset', icon: Icons.inventory_2_outlined),
                  RiskSummaryCard(value: '${data.totalComponents}', label: 'Total komponen', icon: Icons.widgets_outlined),
                  RiskSummaryCard(value: '${data.criticalVulnerabilities}', label: 'CVE kritis', icon: Icons.warning_amber_rounded),
                  RiskSummaryCard(value: '${data.assetsWithDrift}', label: 'Aset dengan drift', icon: Icons.compare_arrows_outlined),
                ],
              ),
              const SizedBox(height: 16),
              PrimaryButton(label: 'Pindai Semua Aset', onPressed: _scanAllAssets, isLoading: _isScanning, icon: Icons.radar),
              const SizedBox(height: 24),
              Text('Aset', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ...data.assets.map(
                (asset) => Card(
                  child: ListTile(
                    onTap: () => context.push('/projects/${widget.projectId}/scan-results/${asset.assetId}'),
                    title: Text(asset.name),
                    subtitle: Text(asset.lastScannedAt == null ? 'Belum pernah dipindai' : 'Dipindai ${asset.lastScannedAt!.hour.toString().padLeft(2, '0')}:${asset.lastScannedAt!.minute.toString().padLeft(2, '0')}'),
                    trailing: StatusBadge(status: asset.status),
                  ),
                ),
              ),
              TextButton.icon(onPressed: () => context.push('/projects/${widget.projectId}/assets'), icon: const Icon(Icons.inventory_2_outlined), label: const Text('Kelola aset')),
            ],
          );
        },
      ),
    );
  }
}

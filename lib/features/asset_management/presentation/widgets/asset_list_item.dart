import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../monitoring/application/monitoring_notifier.dart';
import '../../../management/presentation/edit_form.dart';

import '../../../../models/asset_model.dart';
import '../../../../widgets/status_badge.dart';
import '../../../../widgets/asset_card.dart';

class AssetListItem extends ConsumerWidget {
  const AssetListItem({super.key, required this.asset});
  final Asset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scan = ref.watch(scanActionProvider(asset.id));
    ref.listen(scanActionProvider(asset.id), (previous, next) {
      if (next.hasError || next.valueOrNull != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(next.hasError ? '${next.error}' : next.valueOrNull!)));
      }
    });
    final scanned = asset.lastScannedAt;
    final lastSynced = scanned == null
        ? 'Belum pernah disinkronkan'
        : 'Terakhir disinkronkan ${scanned.day.toString().padLeft(2, '0')}/${scanned.month.toString().padLeft(2, '0')}/${scanned.year} ${scanned.hour.toString().padLeft(2, '0')}:${scanned.minute.toString().padLeft(2, '0')}';
    return AssetCard(
      name: asset.name,
      description: '${asset.owner}/${asset.repositoryName}',
      timeLabel: lastSynced,
      status: asset.isActive ? RiskStatus.active : RiskStatus.inactive,
      scanning: scan.isLoading,
      onScan: !asset.isActive
          ? null
          : () =>
              ref.read(scanActionProvider(asset.id).notifier).scanOne(asset.id),
      onEdit: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => EditForm(
              id: asset.id,
              name: asset.name,
              detail: asset.repositoryUrl,
              isAsset: true,
              active: asset.isActive)),
      onTap: () =>
          context.push('/projects/${asset.projectId}/scan-results/${asset.id}'),
    );
  }
}

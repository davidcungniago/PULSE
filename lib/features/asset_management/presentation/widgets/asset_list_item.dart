import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../monitoring/application/monitoring_notifier.dart';
import '../../../management/presentation/edit_form.dart';

import '../../../../models/asset_model.dart';
import '../../../../models/date_time_utils.dart';
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
            content: Text(
                next.hasError ? '${next.error}' : next.valueOrNull!.summary)));
      }
    });
    final scanned = asset.lastScannedAt;
    final lastScan = scanned == null
        ? 'Belum pernah dipindai'
        : 'Dipindai ${relativeTimeLabel(scanned)}';
    return AssetCard(
      name: asset.name,
      description: '${asset.owner}/${asset.repositoryName}',
      timeLabel: lastScan,
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

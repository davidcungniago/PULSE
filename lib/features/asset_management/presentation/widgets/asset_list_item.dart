import 'package:flutter/material.dart';

import '../../../../models/asset_model.dart';
import '../../../../widgets/status_badge.dart';

class AssetListItem extends StatelessWidget {
  const AssetListItem({super.key, required this.asset});
  final Asset asset;

  @override
  Widget build(BuildContext context) {
    final scanned = asset.lastScannedAt;
    final lastSynced = scanned == null
        ? 'Belum pernah disinkronkan'
        : 'Terakhir disinkronkan ${scanned.day.toString().padLeft(2, '0')}/${scanned.month.toString().padLeft(2, '0')}/${scanned.year} ${scanned.hour.toString().padLeft(2, '0')}:${scanned.minute.toString().padLeft(2, '0')}';
    return Card(child: ListTile(leading: const Icon(Icons.code), title: Text(asset.name), subtitle: Text('${asset.owner}/${asset.repositoryName}\n$lastSynced'), isThreeLine: true, trailing: StatusBadge(status: asset.isActive ? RiskStatus.active : RiskStatus.inactive)));
  }
}

import 'package:flutter/material.dart';
import 'primary_button.dart';
import 'status_badge.dart';

class AssetCard extends StatelessWidget {
  const AssetCard(
      {super.key,
      required this.name,
      required this.status,
      required this.timeLabel,
      this.description = '',
      this.onTap,
      this.onScan,
      this.onEdit,
      this.scanning = false});
  final String name;
  final RiskStatus status;
  final String timeLabel;
  final String description;
  final VoidCallback? onTap;
  final VoidCallback? onScan;
  final VoidCallback? onEdit;
  final bool scanning;

  @override
  Widget build(BuildContext context) => Card(
          child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                    [if (description.isNotEmpty) description, timeLabel]
                        .join('\n'),
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                StatusBadge(status: status),
                if (onEdit != null)
                  TextButton(onPressed: onEdit, child: const Text('Ubah aset')),
                if (onScan != null) ...[
                  const SizedBox(height: 16),
                  PrimaryButton(
                      label: 'Pindai Sekarang',
                      onPressed: onScan,
                      isLoading: scanning,
                      icon: Icons.radar),
                ],
              ],
            )),
      ));
}

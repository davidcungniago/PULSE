import 'package:flutter/material.dart';
import '../theme/contrast.dart';
import '../theme/pulse_colors.dart';

enum RiskStatus {
  healthy('Sehat'),
  warning('Peringatan'),
  critical('Perlu tindakan'),
  notScanned('Belum dipindai'),
  active('Aktif'),
  inactive('Tidak aktif');

  const RiskStatus(this.label);
  final String label;
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});
  final RiskStatus status;
  @override
  Widget build(BuildContext context) {
    final colors = PulseColors.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: badgeBackground(colors.riskFill(status), colors.surface),
          borderRadius: BorderRadius.circular(12)),
      child: Text(status.label,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: colors.riskText(status))),
    );
  }
}

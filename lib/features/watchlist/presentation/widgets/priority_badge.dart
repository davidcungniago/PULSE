import 'package:flutter/material.dart';

import '../../../../models/watched_repository.dart';
import '../../../../theme/contrast.dart';
import '../../../../theme/pulse_colors.dart';
import '../../../../widgets/status_badge.dart';

class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority});

  final WatchPriority priority;

  @override
  Widget build(BuildContext context) {
    final colors = PulseColors.of(context);
    final status = switch (priority) {
      WatchPriority.high => RiskStatus.critical,
      WatchPriority.medium => RiskStatus.warning,
      WatchPriority.low => RiskStatus.healthy,
    };
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: badgeBackground(colors.riskFill(status), colors.surface),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        priority.label,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: colors.riskText(status)),
      ),
    );
  }
}

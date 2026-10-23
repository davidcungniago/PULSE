import 'package:flutter/material.dart';
import '../models/severity.dart';
import '../theme/contrast.dart';
import '../theme/pulse_colors.dart';

class SeverityBadge extends StatelessWidget {
  const SeverityBadge({super.key, required this.severity});
  final Severity severity;

  @override
  Widget build(BuildContext context) {
    final colors = PulseColors.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: badgeBackground(colors.severityFill(severity), colors.surface),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(severity.label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colors.severityText(severity),
              )),
    );
  }
}

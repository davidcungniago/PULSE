import 'package:flutter/material.dart';
import '../theme/pulse_colors.dart';
import '../theme/pulse_dimensions.dart';
import '../theme/pulse_typography.dart';

class VitalTile extends StatelessWidget {
  const VitalTile({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = PulseColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.line),
          borderRadius: BorderRadius.circular(PulseDimensions.tileRadius)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: PulseTypography.number.copyWith(color: colors.text)),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/pulse_colors.dart';
import '../theme/pulse_dimensions.dart';
import '../theme/pulse_typography.dart';
import 'status_badge.dart';

class VitalLineItem {
  const VitalLineItem(this.value, this.label, {this.highlight = false});
  final String value;
  final String label;
  final bool highlight;
}

class VitalLine extends StatelessWidget {
  const VitalLine({super.key, required this.items});
  final List<VitalLineItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = PulseColors.of(context);
    final labelStyle =
        PulseTypography.mono.copyWith(fontSize: 13, color: colors.textMuted);
    final numberStyle = PulseTypography.mono.copyWith(
        fontSize: 13, fontWeight: FontWeight.w500, color: colors.text);
    final alertStyle =
        numberStyle.copyWith(color: colors.riskText(RiskStatus.critical));
    final spans = <InlineSpan>[
      for (var index = 0; index < items.length; index++) ...[
        if (index > 0) TextSpan(text: ' · ', style: labelStyle),
        TextSpan(
            text: items[index].value,
            style: items[index].highlight ? alertStyle : numberStyle),
        TextSpan(text: ' ${items[index].label}', style: labelStyle),
      ],
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.line),
          borderRadius: BorderRadius.circular(PulseDimensions.tileRadius)),
      child: Text.rich(TextSpan(children: spans)),
    );
  }
}

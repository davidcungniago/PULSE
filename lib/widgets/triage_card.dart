import 'package:flutter/material.dart';

import '../models/date_time_utils.dart';
import '../models/triage.dart';
import '../theme/contrast.dart';
import '../theme/pulse_colors.dart';
import '../theme/pulse_dimensions.dart';
import 'status_badge.dart';

class TriageCard extends StatelessWidget {
  const TriageCard({super.key, required this.entry, required this.onAction});
  final TriageEntry entry;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final colors = PulseColors.of(context);
    final tone = switch (entry.kind) {
      TriageKind.critical => colors.riskFill(RiskStatus.critical),
      TriageKind.drift => colors.drift,
      TriageKind.warning => colors.riskFill(RiskStatus.warning),
      TriageKind.notScanned => colors.riskFill(RiskStatus.notScanned),
    };
    final background = badgeBackground(tone, colors.surface);
    final badgeText = switch (entry.kind) {
      TriageKind.critical => colors.riskText(RiskStatus.critical),
      TriageKind.drift => colors.driftText(),
      TriageKind.warning => colors.riskText(RiskStatus.warning),
      TriageKind.notScanned => colors.riskText(RiskStatus.notScanned),
    };
    final scannedAt = entry.asset.lastScannedAt;
    final detail = scannedAt == null
        ? entry.reason
        : '${entry.reason} · dipindai ${relativeTimeLabel(scannedAt)}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: background,
                    borderRadius:
                        BorderRadius.circular(PulseDimensions.badgeRadius)),
                child: Text(entry.kind.label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: badgeText, fontWeight: FontWeight.w500))),
            const SizedBox(width: 8),
            Expanded(
                child: Text(entry.asset.name,
                    style: Theme.of(context).textTheme.titleMedium)),
          ]),
          const SizedBox(height: 8),
          Text(detail, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                  onPressed: onAction, child: Text(entry.actionLabel))),
        ]),
      ),
    );
  }
}

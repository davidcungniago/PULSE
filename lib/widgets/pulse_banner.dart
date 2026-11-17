import 'package:flutter/material.dart';
import '../theme/pulse_colors.dart';
import 'pulse_trace.dart';
import 'status_badge.dart';

class PulseBanner extends StatelessWidget {
  const PulseBanner(
      {super.key,
      required this.status,
      required this.seed,
      required this.sub,
      this.hasDrift = false,
      this.scanning = false,
      this.animate = false});
  final RiskStatus status;
  final int seed;
  final String sub;
  final bool hasDrift;
  final bool scanning;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final colors = PulseColors.of(context);
    return Card(
        child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        StatusBadge(status: status),
        const SizedBox(height: 8),
        Text(scanning ? 'Memindai…' : sub,
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        PulseTrace(
            status: status,
            seed: seed,
            sub: sub,
            hasDrift: hasDrift,
            scanning: scanning,
            animate: animate),
        if (hasDrift) ...[
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.change_history, size: 12, color: colors.drift),
            const SizedBox(width: 4),
            Expanded(
                child: Text('Segitiga menandai drift dependensi.',
                    style: Theme.of(context).textTheme.labelSmall)),
          ]),
        ],
      ]),
    ));
  }
}

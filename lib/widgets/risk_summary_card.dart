import 'package:flutter/material.dart';

class RiskSummaryCard extends StatelessWidget {
  const RiskSummaryCard({super.key, required this.value, required this.label, required this.icon});
  final String value;
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [Icon(icon, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: Theme.of(context).textTheme.headlineSmall), Text(label)]))]),
        ),
      );
}

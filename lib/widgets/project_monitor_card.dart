import 'package:flutter/material.dart';
import '../services/stable_hash.dart';
import 'pulse_trace.dart';
import 'status_badge.dart';

class ProjectMonitorCard extends StatelessWidget {
  const ProjectMonitorCard(
      {super.key,
      required this.id,
      required this.name,
      required this.status,
      this.description = '',
      this.onTap});
  final String id;
  final String name;
  final String description;
  final RiskStatus status;
  final VoidCallback? onTap;

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
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(description,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
                const SizedBox(height: 16),
                PulseTrace(
                    status: status,
                    seed: stableHash(id),
                    height: 48,
                    animate: false),
                const SizedBox(height: 8),
                StatusBadge(status: status),
              ],
            )),
      ));
}

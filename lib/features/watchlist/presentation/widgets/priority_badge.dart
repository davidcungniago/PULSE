import 'package:flutter/material.dart';

import '../../../../models/watched_repository.dart';

class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority});

  final WatchPriority priority;

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      WatchPriority.high => Colors.red,
      WatchPriority.medium => Colors.orange,
      WatchPriority.low => Colors.green,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        priority.label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

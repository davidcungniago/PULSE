import 'package:flutter/material.dart';

import '../models/scan_report.dart';
import '../theme/pulse_colors.dart';
import 'status_badge.dart';

class ScanReportSheet extends StatelessWidget {
  const ScanReportSheet({super.key, required this.report});
  final ScanReport report;

  @override
  Widget build(BuildContext context) {
    final colors = PulseColors.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(report.summary,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: report.attempts.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final attempt = report.attempts[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                        attempt.succeeded
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        size: 20,
                        color: attempt.succeeded
                            ? colors.riskText(RiskStatus.healthy)
                            : colors.riskText(RiskStatus.critical)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(attempt.name ?? attempt.assetId,
                              style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 4),
                          Text(attempt.succeeded ? 'Selesai' : attempt.error!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: attempt.succeeded
                                        ? null
                                        : Theme.of(context).colorScheme.error,
                                  )),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

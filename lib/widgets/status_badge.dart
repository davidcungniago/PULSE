import 'package:flutter/material.dart';

enum RiskStatus { healthy, warning, critical, notScanned, active, inactive }

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});
  final RiskStatus status;
  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      RiskStatus.healthy => (Colors.green, 'Sehat'),
      RiskStatus.warning => (Colors.orange, 'Peringatan'),
      RiskStatus.critical => (Colors.red, 'Kritis'),
      RiskStatus.notScanned => (Colors.grey, 'Belum dipindai'),
      RiskStatus.active => (Colors.green, 'Aktif'),
      RiskStatus.inactive => (Colors.grey, 'Tidak aktif'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(.14), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

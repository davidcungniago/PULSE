import 'package:flutter/material.dart';

import '../models/drift_event_model.dart';
import '../services/scan_service.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/status_badge.dart';

class ScanResultDetailScreen extends StatelessWidget {
  const ScanResultDetailScreen({super.key, required this.assetId});

  final String assetId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Pemindaian')),
      body: FutureBuilder(
        future: Future.wait([ScanService().getComponents(assetId), ScanService().getDriftEvents(assetId)]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LoadingIndicator();
          final components = snapshot.data![0] as List;
          final driftEvents = snapshot.data![1] as List;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Komponen', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ...components.map(
                (component) => Card(
                  child: ListTile(
                    title: Text('${component.name} ${component.version}'),
                    subtitle: Text('Lisensi: ${component.license}'),
                    trailing: StatusBadge(status: _statusForSeverity(_severityForComponent(component.name))),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Perubahan dependensi', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ...driftEvents.map(
                (event) => Card(
                  child: ListTile(
                    leading: Icon(_driftIcon(event.type)),
                    title: Text(event.componentName),
                    subtitle: Text(event.details),
                    trailing: Text(_driftLabel(event.type)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _severityForComponent(String componentName) => switch (componentName) {
        'lodash' => 'critical',
        'axios' => 'warning',
        _ => 'healthy',
      };

  RiskStatus _statusForSeverity(String severity) => switch (severity) {
        'critical' => RiskStatus.critical,
        'warning' => RiskStatus.warning,
        'notScanned' => RiskStatus.notScanned,
        _ => RiskStatus.healthy,
      };

  IconData _driftIcon(DriftEventType type) => switch (type) {
        DriftEventType.added => Icons.add_circle_outline,
        DriftEventType.removed => Icons.remove_circle_outline,
        DriftEventType.changed => Icons.sync_alt,
      };

  String _driftLabel(DriftEventType type) => switch (type) {
        DriftEventType.added => 'Ditambahkan',
        DriftEventType.removed => 'Dihapus',
        DriftEventType.changed => 'Diubah',
      };
}

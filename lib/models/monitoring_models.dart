import 'severity.dart';
import 'date_time_utils.dart';

class ComponentEntry {
  ComponentEntry.fromJson(Map<String, dynamic> json)
      : name = json['Name'] as String,
        version = json['Version'] as String,
        license = json['License'] as String,
        severity = switch (json['HighestSeverity']) {
          'CRITICAL' => Severity.critical,
          'HIGH' => Severity.high,
          'MEDIUM' => Severity.medium,
          'LOW' => Severity.low,
          null => Severity.safe,
          _ => Severity.unknown,
        },
        cveIds = (json['Vulnerabilities'] as List)
            .map((v) => v['CveId'] as String)
            .toList();
  final String name, version, license;
  final Severity severity;
  final List<String> cveIds;
}

class DriftEntry {
  DriftEntry.fromJson(Map<String, dynamic> json)
      : name = json['ComponentName'] as String,
        details = json['Details'] as String,
        label = switch (json['Type']) {
          'added' => 'Ditambahkan',
          'removed' => 'Dihapus',
          _ => 'Diubah',
        };
  final String name, details, label;
}

class ScanDetail {
  ScanDetail.fromJson(Map<String, dynamic> json, List<dynamic> events)
      : components = (json['Components'] as List)
            .map((c) => ComponentEntry.fromJson(c as Map<String, dynamic>))
            .toList(),
        drift = events
            .map((e) => DriftEntry.fromJson(e as Map<String, dynamic>))
            .toList();
  final List<ComponentEntry> components;
  final List<DriftEntry> drift;
}

class AlertEntry {
  AlertEntry.fromJson(Map<String, dynamic> json)
      : type = json['Type'] as String,
        message = json['Message'] as String,
        sentAt = parseUtcIso8601(json['SentAt'] as String),
        deliveryLabel = switch (json['DeliveryStatus']) {
          'SENT' => 'Email terkirim',
          'PENDING' => 'Menunggu pengiriman',
          _ => 'Email gagal terkirim',
        };
  final String type, message, deliveryLabel;
  final DateTime sentAt;
}

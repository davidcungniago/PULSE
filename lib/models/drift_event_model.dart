enum DriftEventType { added, removed, changed }

class DriftEvent {
  const DriftEvent({required this.id, required this.assetId, required this.type, required this.componentName, required this.details, required this.detectedAt});
  final String id;
  final String assetId;
  final DriftEventType type;
  final String componentName;
  final String details;
  final DateTime detectedAt;
  factory DriftEvent.fromJson(Map<String, dynamic> json) => DriftEvent(id: json['id'] as String, assetId: json['assetId'] as String, type: DriftEventType.values.byName(json['type'] as String), componentName: json['componentName'] as String, details: json['details'] as String, detectedAt: DateTime.parse(json['detectedAt'] as String));
  Map<String, dynamic> toJson() => {'id': id, 'assetId': assetId, 'type': type.name, 'componentName': componentName, 'details': details, 'detectedAt': detectedAt.toIso8601String()};
}

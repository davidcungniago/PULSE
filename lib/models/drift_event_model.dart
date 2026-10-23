enum DriftEventType { added, removed, changed }

class DriftEvent {
  const DriftEvent(
      {required this.id,
      required this.assetId,
      required this.type,
      required this.componentName,
      required this.details,
      required this.detectedAt});
  final String id;
  final String assetId;
  final DriftEventType type;
  final String componentName;
  final String details;
  final DateTime detectedAt;
  factory DriftEvent.fromJson(Map<String, dynamic> json) => DriftEvent(
      id: json['Id'] as String,
      assetId: json['AssetId'] as String,
      type: DriftEventType.values.byName(json['Type'] as String),
      componentName: json['ComponentName'] as String,
      details: json['Details'] as String,
      detectedAt: DateTime.parse(json['DetectedAt'] as String));
  Map<String, dynamic> toJson() => {
        'Id': id,
        'AssetId': assetId,
        'Type': type.name,
        'ComponentName': componentName,
        'Details': details,
        'DetectedAt': detectedAt.toIso8601String()
      };
}

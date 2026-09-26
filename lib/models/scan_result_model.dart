class ScanResult {
  const ScanResult({required this.id, required this.assetId, required this.componentCount, required this.criticalVulnerabilityCount, required this.startedAt, this.finishedAt, required this.status});
  final String id;
  final String assetId;
  final int componentCount;
  final int criticalVulnerabilityCount;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final String status;
  factory ScanResult.fromJson(Map<String, dynamic> json) => ScanResult(
        id: json['id'] as String, assetId: json['assetId'] as String, componentCount: json['componentCount'] as int,
        criticalVulnerabilityCount: json['criticalVulnerabilityCount'] as int, startedAt: DateTime.parse(json['startedAt'] as String),
        finishedAt: json['finishedAt'] == null ? null : DateTime.parse(json['finishedAt'] as String), status: json['status'] as String,
      );
  Map<String, dynamic> toJson() => {'id': id, 'assetId': assetId, 'componentCount': componentCount, 'criticalVulnerabilityCount': criticalVulnerabilityCount, 'startedAt': startedAt.toIso8601String(), 'finishedAt': finishedAt?.toIso8601String(), 'status': status};
}

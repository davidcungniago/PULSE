class ScanResult {
  const ScanResult(
      {required this.id,
      required this.assetId,
      required this.componentCount,
      required this.criticalVulnerabilityCount,
      required this.startedAt,
      this.finishedAt,
      required this.status});
  final String id;
  final String assetId;
  final int componentCount;
  final int criticalVulnerabilityCount;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final String status;
  factory ScanResult.fromJson(Map<String, dynamic> json) => ScanResult(
        id: json['Id'] as String,
        assetId: json['AssetId'] as String,
        componentCount: json['ComponentCount'] as int,
        criticalVulnerabilityCount: json['CriticalVulnerabilityCount'] as int,
        startedAt: DateTime.parse(json['StartedAt'] as String),
        finishedAt: json['FinishedAt'] == null
            ? null
            : DateTime.parse(json['FinishedAt'] as String),
        status: json['Status'] as String,
      );
  Map<String, dynamic> toJson() => {
        'Id': id,
        'AssetId': assetId,
        'ComponentCount': componentCount,
        'CriticalVulnerabilityCount': criticalVulnerabilityCount,
        'StartedAt': startedAt.toIso8601String(),
        'FinishedAt': finishedAt?.toIso8601String(),
        'Status': status
      };
}

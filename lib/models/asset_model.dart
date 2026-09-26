class Asset {
  const Asset({required this.id, required this.projectId, required this.name, required this.repositoryUrl, required this.owner, required this.repositoryName, required this.isActive, this.lastScannedAt});
  final String id;
  final String projectId;
  final String name;
  final String repositoryUrl;
  final String owner;
  final String repositoryName;
  final bool isActive;
  final DateTime? lastScannedAt;
  factory Asset.fromJson(Map<String, dynamic> json) => Asset(
        id: json['id'] as String, projectId: json['projectId'] as String, name: json['name'] as String,
        repositoryUrl: json['repositoryUrl'] as String, owner: json['owner'] as String,
        repositoryName: json['repositoryName'] as String, isActive: json['isActive'] as bool,
        lastScannedAt: json['lastScannedAt'] == null ? null : DateTime.parse(json['lastScannedAt'] as String),
      );
  Map<String, dynamic> toJson() => {'id': id, 'projectId': projectId, 'name': name, 'repositoryUrl': repositoryUrl, 'owner': owner, 'repositoryName': repositoryName, 'isActive': isActive, 'lastScannedAt': lastScannedAt?.toIso8601String()};
}

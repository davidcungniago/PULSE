import 'date_time_utils.dart';

class Asset {
  const Asset({
    required this.id,
    required this.projectId,
    required this.name,
    required this.repositoryUrl,
    required this.owner,
    required this.repositoryName,
    required this.isActive,
    this.lastScannedAt,
  });

  final String id;
  final String projectId;
  final String name;
  final String repositoryUrl;
  final String owner;
  final String repositoryName;
  final bool isActive;
  final DateTime? lastScannedAt;

  factory Asset.fromJson(Map<String, dynamic> json) => Asset(
        id: json['Id'] as String,
        projectId: json['ProjectId'] as String,
        name: json['Name'] as String,
        repositoryUrl: json['RepositoryUrl'] as String,
        owner: json['Owner'] as String,
        repositoryName: json['RepositoryName'] as String,
        isActive: json['IsActive'] as bool,
        lastScannedAt: json['LastScannedAt'] == null
            ? null
            : parseUtcIso8601(json['LastScannedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'Id': id,
        'ProjectId': projectId,
        'Name': name,
        'RepositoryUrl': repositoryUrl,
        'Owner': owner,
        'RepositoryName': repositoryName,
        'IsActive': isActive,
        'LastScannedAt': lastScannedAt?.toUtc().toIso8601String(),
      };
}

import 'date_time_utils.dart';

enum WatchPriority { low, medium, high }

extension WatchPriorityLabel on WatchPriority {
  String get label => switch (this) {
        WatchPriority.low => 'Rendah',
        WatchPriority.medium => 'Sedang',
        WatchPriority.high => 'Tinggi',
      };
}

class WatchedRepository {
  const WatchedRepository({
    required this.id,
    required this.repositoryUrl,
    required this.owner,
    required this.repositoryName,
    required this.note,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String repositoryUrl;
  final String owner;
  final String repositoryName;
  final String note;
  final WatchPriority priority;
  final DateTime createdAt;
  final DateTime updatedAt;

  WatchedRepository copyWith({
    String? note,
    WatchPriority? priority,
    DateTime? updatedAt,
  }) =>
      WatchedRepository(
        id: id,
        repositoryUrl: repositoryUrl,
        owner: owner,
        repositoryName: repositoryName,
        note: note ?? this.note,
        priority: priority ?? this.priority,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  factory WatchedRepository.fromJson(Map<String, dynamic> json) =>
      WatchedRepository(
        id: json['Id'] as String,
        repositoryUrl: json['RepositoryUrl'] as String,
        owner: json['Owner'] as String,
        repositoryName: json['RepositoryName'] as String,
        note: json['Note'] as String? ?? '',
        priority: _priorityFromJson(json['Priority'] as String?),
        createdAt: parseUtcIso8601(json['CreatedAt'] as String),
        updatedAt: parseUtcIso8601(json['UpdatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'Id': id,
        'RepositoryUrl': repositoryUrl,
        'Owner': owner,
        'RepositoryName': repositoryName,
        'Note': note,
        'Priority': priority.name,
        'CreatedAt': createdAt.toUtc().toIso8601String(),
        'UpdatedAt': updatedAt.toUtc().toIso8601String(),
      };
}

WatchPriority _priorityFromJson(String? value) {
  for (final priority in WatchPriority.values) {
    if (priority.name == value) return priority;
  }
  return WatchPriority.medium;
}

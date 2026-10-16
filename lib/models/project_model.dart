import 'date_time_utils.dart';

class Project {
  const Project({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final DateTime createdAt;

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['Id'] as String,
        name: json['Name'] as String,
        description: json['Description'] as String? ?? '',
        createdAt: parseUtcIso8601(json['CreatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'Id': id,
        'Name': name,
        'Description': description,
        'CreatedAt': createdAt.toUtc().toIso8601String(),
      };
}

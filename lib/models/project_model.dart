class Project {
  const Project({required this.id, required this.name, required this.description, required this.createdAt});
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'description': description, 'createdAt': createdAt.toIso8601String()};
}

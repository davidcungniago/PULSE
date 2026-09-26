class AlertLog {
  const AlertLog({required this.id, required this.projectId, required this.type, required this.message, required this.sentAt});
  final String id;
  final String projectId;
  final String type;
  final String message;
  final DateTime sentAt;
  factory AlertLog.fromJson(Map<String, dynamic> json) => AlertLog(id: json['id'] as String, projectId: json['projectId'] as String, type: json['type'] as String, message: json['message'] as String, sentAt: DateTime.parse(json['sentAt'] as String));
  Map<String, dynamic> toJson() => {'id': id, 'projectId': projectId, 'type': type, 'message': message, 'sentAt': sentAt.toIso8601String()};
}

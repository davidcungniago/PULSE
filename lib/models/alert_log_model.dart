class AlertLog {
  const AlertLog(
      {required this.id,
      required this.projectId,
      required this.type,
      required this.message,
      required this.sentAt});
  final String id;
  final String projectId;
  final String type;
  final String message;
  final DateTime sentAt;
  factory AlertLog.fromJson(Map<String, dynamic> json) => AlertLog(
      id: json['Id'] as String,
      projectId: json['ProjectId'] as String,
      type: json['Type'] as String,
      message: json['Message'] as String,
      sentAt: DateTime.parse(json['SentAt'] as String));
  Map<String, dynamic> toJson() => {
        'Id': id,
        'ProjectId': projectId,
        'Type': type,
        'Message': message,
        'SentAt': sentAt.toIso8601String()
      };
}

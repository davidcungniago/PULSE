class User {
  const User({required this.id, required this.email});
  final String id;
  final String email;
  factory User.fromJson(Map<String, dynamic> json) =>
      User(id: json['Id'] as String, email: json['Email'] as String);
  Map<String, dynamic> toJson() => {'Id': id, 'Email': email};
}

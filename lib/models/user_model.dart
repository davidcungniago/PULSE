class User {
  const User({required this.id, required this.email});
  final String id;
  final String email;
  factory User.fromJson(Map<String, dynamic> json) => User(id: json['id'] as String, email: json['email'] as String);
  Map<String, dynamic> toJson() => {'id': id, 'email': email};
}

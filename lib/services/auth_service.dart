import '../models/user_model.dart';

class AuthService {
  Future<User> login(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return User(id: 'user-1', email: email);
  }
  Future<User> register(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return User(id: 'user-1', email: email);
  }
}

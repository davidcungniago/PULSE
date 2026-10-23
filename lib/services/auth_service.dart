import 'api_client.dart';

class AuthService {
  AuthService(this.client);
  final ApiClient client;

  Future<Map<String, dynamic>> authenticate(String email, String password,
      {required bool register}) async {
    final response = await client.dio.post<Map<String, dynamic>>(
      register ? '/api/auth/register' : '/api/auth/login',
      data: {'Email': email.trim(), 'Password': password},
    );
    return response.data!;
  }
}

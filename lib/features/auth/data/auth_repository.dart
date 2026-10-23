import '../../../services/api_client.dart';
import '../../../services/session_store.dart';
import '../../../services/auth_service.dart';

class AuthRepository {
  AuthRepository(this.client, this.store);
  final ApiClient client;
  final SessionStore store;

  Future<void> authenticate(String email, String password,
      {required bool register}) async {
    final data = await AuthService(client)
        .authenticate(email, password, register: register);
    await store.save(data);
  }

  Future<void> logout() => store.clear();
}

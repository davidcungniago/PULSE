import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

class SessionStore extends ChangeNotifier {
  SessionStore(this.storage);
  final FlutterSecureStorage storage;
  String? token;
  User? user;
  bool restoring = true;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> restore() async {
    try {
      final raw = await storage.read(key: 'pulse.session');
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        token = data['AccessToken'] as String;
        user = User.fromJson(data['User'] as Map<String, dynamic>);
      }
    } catch (_) {
      token = null;
      user = null;
    } finally {
      restoring = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> save(Map<String, dynamic> data) async {
    final nextUser = User.fromJson(data['User'] as Map<String, dynamic>);
    final nextToken = data['AccessToken'] as String;
    await storage.write(key: 'pulse.session', value: jsonEncode(data));
    token = nextToken;
    user = nextUser;
    notifyListeners();
  }

  Future<void> clear() async {
    token = null;
    user = null;
    notifyListeners();
    await storage.delete(key: 'pulse.session');
  }
}

final sessionStoreProvider = ChangeNotifierProvider<SessionStore>((ref) {
  final store = SessionStore(const FlutterSecureStorage());
  store.restore();
  return store;
});

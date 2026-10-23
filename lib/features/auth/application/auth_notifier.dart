import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/api_client.dart';
import '../../../services/api_error_mapper.dart';
import '../../../services/session_store.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository(
    ref.read(apiClientProvider), ref.read(sessionStoreProvider)));
final authProvider =
    NotifierProvider<AuthNotifier, AsyncValue<void>>(AuthNotifier.new);

class AuthNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  String? validateEmail(String? value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value?.trim() ?? '')
          ? null
          : 'Masukkan email yang valid.';
  String? validatePassword(String? value) =>
      (value?.length ?? 0) >= 6 ? null : 'Kata sandi minimal 6 karakter.';

  Future<void> submit(String email, String password,
      {bool register = false}) async {
    if (state.isLoading) return;
    final error = validateEmail(email) ?? validatePassword(password);
    if (error != null) {
      state = AsyncError(error, StackTrace.current);
      return;
    }
    state = const AsyncLoading();
    try {
      await ref
          .read(authRepositoryProvider)
          .authenticate(email, password, register: register);
      state = const AsyncData(null);
    } on DioException catch (error, stack) {
      state = AsyncError(mapApiErrorToMessage(error), stack);
    } catch (error, stack) {
      state = AsyncError('Sesi tidak dapat disimpan. Coba lagi.', stack);
    }
  }

  Future<void> logout() async {
    state =
        await AsyncValue.guard(() => ref.read(authRepositoryProvider).logout());
  }
}

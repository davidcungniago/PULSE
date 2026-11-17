import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_endpoint.dart';
import 'session_store.dart';

const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: '',
);

class ApiClient {
  ApiClient({String? baseUrl})
      : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ??
                resolveApiEndpoint(
                  configuredUrl: apiBaseUrl,
                  isWeb: kIsWeb,
                  pageUri: Uri.base,
                ),
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            sendTimeout: const Duration(seconds: 10),
          ),
        );

  final Dio dio;
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final store = ref.read(sessionStoreProvider);
  final client = ApiClient();
  client.dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      if (store.token != null) {
        options.headers['Authorization'] = 'Bearer ${store.token}';
      }
      handler.next(options);
    },
    onError: (error, handler) {
      if (error.response?.statusCode == 401 &&
          error.requestOptions.headers['Authorization'] ==
              'Bearer ${store.token}' &&
          !error.requestOptions.path.startsWith('/api/auth/')) {
        store.clear().catchError((Object _) {});
      }
      handler.next(error);
    },
  ));
  ref.onDispose(() => client.dio.close());
  return client;
});

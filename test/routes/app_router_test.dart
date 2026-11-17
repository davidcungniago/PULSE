import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/routes/app_router.dart';
import 'package:pulse/screens/login_screen.dart';
import 'package:pulse/screens/register_screen.dart';
import 'package:pulse/services/session_store.dart';

void main() {
  testWidgets('push memperbarui URL browser untuk rute aplikasi',
      (tester) async {
    final session = SessionStore(const FlutterSecureStorage())
      ..restoring = false;

    await tester.pumpWidget(ProviderScope(
      overrides: [sessionStoreProvider.overrideWith((ref) => session)],
      child: Consumer(builder: (context, ref, _) {
        return MaterialApp.router(routerConfig: ref.watch(appRouterProvider));
      }),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    final router =
        ProviderScope.containerOf(tester.element(find.byType(LoginScreen)))
            .read(appRouterProvider);
    router.push('/register');
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/register');
  });
}

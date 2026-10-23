import 'package:flutter/material.dart';
import '../widgets/constrained_page.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/application/auth_notifier.dart';
import '../widgets/pulse_trace.dart';
import '../widgets/status_badge.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authProvider.notifier)
        .submit(_email.text, _password.text, register: false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      body: ConstrainedPage(
          child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PulseTrace(
                        status: RiskStatus.healthy,
                        seed: 1,
                        animate: false,
                        sub: 'Tidak ada temuan'),
                    const SizedBox(height: 24),
                    Text('Pulse',
                        style: Theme.of(context).textTheme.displaySmall),
                    const SizedBox(height: 8),
                    const Text(
                        'Pantau risiko rantai pasok perangkat lunak Anda.'),
                    const SizedBox(height: 32),
                    AppTextField(
                      label: 'Email',
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      validator: ref.read(authProvider.notifier).validateEmail,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Kata sandi',
                      controller: _password,
                      obscureText: true,
                      validator:
                          ref.read(authProvider.notifier).validatePassword,
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Masuk',
                      onPressed: _submit,
                      isLoading: auth.isLoading,
                    ),
                    if (auth.hasError)
                      Text('${auth.error}',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                    TextButton(
                      onPressed: () => context.go('/register'),
                      child: const Text('Belum punya akun? Daftar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      )),
    );
  }
}

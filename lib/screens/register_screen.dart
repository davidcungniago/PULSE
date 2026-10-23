import 'package:flutter/material.dart';
import '../widgets/constrained_page.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/application/auth_notifier.dart';
import '../widgets/pulse_trace.dart';
import '../widgets/status_badge.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
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
        .submit(_email.text, _password.text, register: true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(),
      body: ConstrainedPage(
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
                  Text('Buat Akun',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  const Text('Mulai memantau risiko proyek Anda.'),
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
                    validator: ref.read(authProvider.notifier).validatePassword,
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Daftar',
                    onPressed: _submit,
                    isLoading: auth.isLoading,
                  ),
                  TextButton(
                    key: const ValueKey('login-link'),
                    onPressed: () => context.go('/login'),
                    child: const Text('Sudah punya akun? Masuk'),
                  ),
                  if (auth.hasError)
                    Text('${auth.error}',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                ],
              ),
            ),
          ),
        ),
      )),
    );
  }
}

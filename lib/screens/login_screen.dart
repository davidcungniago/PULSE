import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await AuthService().login(_email.text, _password.text);
    if (mounted) context.go('/projects');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Pulse', style: Theme.of(context).textTheme.displaySmall),
                    const SizedBox(height: 8),
                    const Text('Pantau risiko rantai pasok perangkat lunak Anda.'),
                    const SizedBox(height: 32),
                    AppTextField(
                      label: 'Email',
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => value == null || !value.contains('@')
                          ? 'Masukkan email yang valid.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Kata sandi',
                      controller: _password,
                      obscureText: true,
                      validator: (value) => value == null || value.length < 6
                          ? 'Kata sandi minimal 6 karakter.'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Masuk',
                      onPressed: _submit,
                      isLoading: _loading,
                    ),
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
      ),
    );
  }
}

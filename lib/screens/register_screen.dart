import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
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
    await AuthService().register(_email.text, _password.text);
    if (mounted) context.go('/projects');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Buat Akun', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  const Text('Mulai memantau risiko proyek Anda.'),
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
                    label: 'Daftar',
                    onPressed: _submit,
                    isLoading: _loading,
                  ),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Sudah punya akun? Masuk'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

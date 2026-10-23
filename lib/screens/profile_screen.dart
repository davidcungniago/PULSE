import 'package:flutter/material.dart';
import '../widgets/constrained_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/session_store.dart';
import '../features/auth/application/auth_notifier.dart';
import '../widgets/primary_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ConstrainedPage(
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CircleAvatar(
                        radius: 36, child: Icon(Icons.person, size: 36)),
                    const SizedBox(height: 16),
                    Text('Akun Anda',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                        ref.watch(sessionStoreProvider).user?.email ??
                            'Belum masuk',
                        textAlign: TextAlign.center),
                    const Spacer(),
                    PrimaryButton(
                        label: 'Keluar',
                        onPressed: () =>
                            ref.read(authProvider.notifier).logout(),
                        icon: Icons.logout)
                  ]))));
}

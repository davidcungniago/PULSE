import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/primary_button.dart';

class ProfileScreen extends StatelessWidget { const ProfileScreen({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Profil')), body: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [const CircleAvatar(radius: 36, child: Icon(Icons.person, size: 36)), const SizedBox(height: 16), Text('Akun Anda', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 8), const Text('developer@pulse.local', textAlign: TextAlign.center), const Spacer(), PrimaryButton(label: 'Keluar', onPressed: () => context.go('/login'), icon: Icons.logout)]))); }

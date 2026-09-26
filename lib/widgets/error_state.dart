import 'package:flutter/material.dart';

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error_outline, size: 56), const SizedBox(height: 16), Text(message), const SizedBox(height: 16), FilledButton(onPressed: onRetry, child: const Text('Coba Lagi'))]));
}

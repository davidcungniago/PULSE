import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.isLoading = false, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => FilledButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(icon),
        label: Text(label),
      );
}

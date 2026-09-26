import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({super.key, required this.label, required this.controller, this.validator, this.errorText, this.obscureText = false, this.keyboardType, this.onChanged});
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller, validator: validator, obscureText: obscureText, keyboardType: keyboardType, onChanged: onChanged,
        decoration: InputDecoration(labelText: label, errorText: errorText, border: const OutlineInputBorder()),
      );
}

import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? prefixIcon;
  final TextInputType keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? errorText;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.onTap,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hint,
        errorText: errorText,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: Theme.of(context).colorScheme.primary)
            : null,
      ),
    );
  }
}

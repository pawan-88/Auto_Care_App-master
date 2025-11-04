import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final bool isNumber;
  final bool obscureText; // Added for password fields
  final int? maxLength; // Added for OTP (6 digits)
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final Widget? suffixIcon; // Added for icons like visibility toggle

  const CustomTextField({
    Key? key,
    required this.controller,
    this.label = '',
    this.hintText = '',
    this.isNumber = false,
    this.obscureText = false,
    this.maxLength,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
    this.suffixIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLength: maxLength,
      inputFormatters: inputFormatters ??
          (isNumber ? [FilteringTextInputFormatter.digitsOnly] : null),
      validator: validator,
      decoration: InputDecoration(
        labelText: label.isNotEmpty ? label : null,
        hintText: hintText,
        border: const OutlineInputBorder(),
        suffixIcon: suffixIcon,
        counterText: maxLength != null ? '' : null, // Hide "0/6" counter text
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AppInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isObscure;
  final TextInputType? keyboardType;
  final String? labelText;
  final String? suffixText;
  final Color? iconColor;

  const AppInputField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.isObscure = false,
    this.keyboardType,
    this.labelText,
    this.suffixText,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        keyboardType: keyboardType,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          labelText: labelText,
          labelStyle: TextStyle(
            color: Colors.grey[500],
            fontWeight: FontWeight.bold,
          ),
          suffixText: suffixText,
          suffixStyle: TextStyle(
            color: Colors.grey[400],
            fontWeight: FontWeight.bold,
          ),
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontWeight: FontWeight.bold,
          ),
          prefixIcon: Icon(icon, color: iconColor ?? const Color(0xFF0061A6)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}

class AppRoundedInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isObscure;

  const AppRoundedInputField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.isObscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon, color: const Color(0xFF0061A6), size: 28),
        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF0061A6), width: 2),
        ),
      ),
    );
  }
}

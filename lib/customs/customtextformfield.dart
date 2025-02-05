import 'package:flutter/material.dart';

class CustomTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Color borderColor;
  final int? maxLines;
  final Color hintTextColor;
  final Color floatingLabelColor; // Yeni parametre eklendi

  const CustomTextFormField({
    Key? key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.borderColor = Colors.black,
    this.maxLines,
    this.hintTextColor = Colors.grey,
    this.floatingLabelColor = const Color(0xFF8A0C27),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: borderColor),
        floatingLabelStyle: TextStyle(color: floatingLabelColor),
        hintText: hintText,
        hintStyle: TextStyle(color: hintTextColor),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: floatingLabelColor),
        ),
      ),
      validator: validator,
    );
  }
}

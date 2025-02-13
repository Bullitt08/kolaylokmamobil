import 'package:flutter/material.dart';

class CustomTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon; // Yeni eklendi
  final TextInputType? keyboardType;
  final bool obscureText; // Şifre gizleme desteği
  final String? Function(String?)? validator;
  final Color borderColor;

  const CustomTextFormField({
    Key? key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon, // Yeni eklendi
    this.keyboardType,
    this.obscureText = false, // Varsayılan olarak false
    this.validator,
    this.borderColor = Colors.black,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText, // Şifre gizleme işlemi
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon, // Yeni eklendi
        floatingLabelStyle: const TextStyle(color: Color(0xFF8A0C27)),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16.0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16.0)),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16.0)),
          borderSide: BorderSide(color: Color(0xFF8A0C27), width: 2.5), // Kalınlık artırıldı
        ),
      ),
      validator: validator,
    );
  }
}

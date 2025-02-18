import 'package:flutter/material.dart';
import 'package:kolaylokma/customs/custombutton.dart';
import 'package:kolaylokma/customs/customicon.dart';
import 'package:kolaylokma/customs/customtextformfield.dart';
import '../services/auth_service.dart';
import 'verify_token_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendResetEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await AuthService().sendPasswordResetEmail(_emailController.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Doğrulama kodu e-posta adresinize gönderildi'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16),
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VerifyTokenPage(
                email: _emailController.text,
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Color(0xFF8A0C27),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEFE8),
      appBar: AppBar(
        backgroundColor: Color(0xFFEDEFE8),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Image.asset(
          'web/icons/logo.png',
          height: 40,
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  const Icon(
                    Icons.lock_reset,
                    size: 100,
                    color: Color(0xFF8A0C27),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Şifremi Unuttum',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8A0C27),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Şifrenizi sıfırlamak için e-posta adresinizi girin',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF8A0C27),
                    ),
                  ),
                  const SizedBox(height: 32),
                  CustomTextFormField(
                    controller: _emailController,
                    labelText: 'E-posta',
                    prefixIcon: const CustomIcon(
                      iconData: Icons.email,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen e-posta adresinizi girin';
                      }
                      if (!value.contains('@')) {
                        return 'Geçerli bir e-posta adresi girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Şifre Sıfırlama Kodu Gönder',
                    onPressed: _isLoading ? null : _sendResetEmail,
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF8A0C27),
              ),
            ),
        ],
      ),
    );
  }
}

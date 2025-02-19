import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kolaylokma/customs/custombutton.dart';
import 'package:kolaylokma/customs/customicon.dart';
import 'package:kolaylokma/customs/customtextformfield.dart';
import '../services/auth_service.dart';
import 'reset_password_page.dart';

class VerifyTokenPage extends StatefulWidget {
  final String email;

  const VerifyTokenPage({super.key, required this.email});

  @override
  State<VerifyTokenPage> createState() => _VerifyTokenPageState();
}

class _VerifyTokenPageState extends State<VerifyTokenPage> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifyToken() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final isValid = await AuthService().verifyResetToken(
          widget.email,
          _tokenController.text,
        );

        if (mounted) {
          if (isValid) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ResetPasswordPage(),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Geçersiz doğrulama kodu'),
                backgroundColor: Color(0xFF8A0C27),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.all(16),
              ),
            );
          }
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
                  Image.asset(
                    'web/icons/verification.png',
                    height: 150,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Doğrulama Kodu',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8A0C27),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'E-posta adresinize (${widget.email}) gönderilen 6 haneli doğrulama kodunu girin',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF8A0C27),
                    ),
                  ),
                  const SizedBox(height: 32),
                  CustomTextFormField(
                    controller: _tokenController,
                    labelText: 'Doğrulama Kodu',
                    prefixIcon: const CustomIcon(
                      iconData: Icons.lock_clock,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(6),
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen doğrulama kodunu girin';
                      }
                      if (value.length != 6) {
                        return 'Doğrulama kodu 6 haneli olmalıdır';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Doğrula',
                    onPressed: _isLoading ? null : _verifyToken,
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

import 'package:flutter/material.dart';
import 'package:kolaylokma/customs/custombutton.dart';
import 'package:kolaylokma/customs/customicon.dart';
import 'package:kolaylokma/customs/customtextformfield.dart';
import 'package:kolaylokma/services/auth_service.dart';
import 'login_page.dart';
import '../main.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await AuthService().register(
          _nameController.text,
          _surnameController.text,
          _emailController.text,
          _passwordController.text,
        );

        if (mounted) {
          // Successful registration redirects to the main page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = 'Bilinmeyen bir hata oluştu';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
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
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          ),
        ),
        title: Image.asset(
          'web/icons/logo.png',
          height: 40,
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Main widget structure for registration
          SingleChildScrollView(
            padding: const EdgeInsets.all(12.0), // padding azaltıldı
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),

                  Image.asset(
                    'web/icons/register.png',
                    height: 150, // görsel boyutu küçültüldü
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Kayıt Ol',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8A0C27),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Name field
                  CustomTextFormField(
                    controller: _nameController,
                    labelText: 'Ad',
                    prefixIcon: const CustomIcon(
                      iconData: Icons.person,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen adınızı girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Surname field
                  CustomTextFormField(
                    controller: _surnameController,
                    labelText: 'Soyad',
                    prefixIcon: const CustomIcon(
                      iconData: Icons.person_outline,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen soyadınızı girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Email field
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
                  const SizedBox(height: 12),

                  // Password field
                  CustomTextFormField(
                    controller: _passwordController,
                    labelText: 'Şifre',
                    prefixIcon: const CustomIcon(
                      iconData: Icons.lock,
                    ),
                    suffixIcon: IconButton(
                      icon: CustomIcon(
                        iconData: _obscureText ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                    obscureText: _obscureText,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen şifrenizi girin';
                      }
                      if (value.length < 6) {
                        return 'Şifre en az 6 karakter olmalıdır';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),
                  // Confirm Password field
                  CustomTextFormField(
                    controller: _confirmPasswordController,
                    labelText: 'Şifre Tekrarı',
                    prefixIcon: const CustomIcon(
                      iconData: Icons.lock,
                    ),
                    obscureText: _obscureText,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen şifrenizi tekrar girin';
                      }
                      if (value != _passwordController.text) {
                        return 'Şifreler eşleşmiyor';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Register button
                  CustomButton(
                    text: 'Kayıt Ol',
                    onPressed: _isLoading ? null : () => _register(),
                  ),
                  const SizedBox(height: 12),
                  // Login button
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: 'Hesabın var mı? ',
                        style: const TextStyle(
                          color: Color(0xFF8A0C27),
                          fontWeight: FontWeight.normal,
                          fontSize: 14,
                        ),
                        children: [
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginPage(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size(0, 0),
                              ),
                              child: const Text(
                                'Giriş Yap',
                                style: TextStyle(
                                  color: Color(0xFF8A0C27),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading indicator in the center
          if (_isLoading)
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: MediaQuery.of(context).size.width / 2 - 25,
              child: const CircularProgressIndicator(
                strokeWidth: 1,
                color: Color(0xFF8A0C27),
                backgroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

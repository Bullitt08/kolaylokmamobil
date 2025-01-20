import 'package:flutter/material.dart';
import 'package:kolaylokma/customs/customicon.dart';
import 'package:kolaylokma/customs/custombutton.dart';
import 'package:kolaylokma/customs/customtextformfield.dart';
import '../services/auth_service.dart';
import 'register_page.dart';
import '../main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Giriş işlemleri
        await AuthService().login(
          _emailController.text,
          _passwordController.text,
        );

        if (mounted) {
          // Başarılı girişten sonra ana sayfaya yönlendir
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MainScreen(),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = 'Bilinmeyen bir hata oluştu';

          if (e.toString().contains('user-not-found')) {
            errorMessage =
            'Bu e-posta adresi ile kayıtlı bir kullanıcı bulunamadı';
          } else if (e.toString().contains('wrong-password')) {
            errorMessage = 'Hatalı şifre girdiniz';
          } else if (e.toString().contains('invalid-email')) {
            errorMessage = 'Geçersiz e-posta adresi';
          } else if (e.toString().contains('network-request-failed')) {
            errorMessage = 'İnternet bağlantınızı kontrol edin';
          }

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
            MaterialPageRoute(builder: (context) => const MainScreen()),
          ),
        ),
        title: Image.asset(
          'web/icons/logo.png',
          height: 40,
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Diğer widget'lar (form, butonlar, vb.)
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),

                  Image.asset(
                    'web/icons/login.png',
                    height: 200,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Giriş Yap',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8A0C27),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // E-posta alanı
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
                  const SizedBox(height: 16),
                  // Şifre alanı
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
                    keyboardType: TextInputType.visiblePassword,
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
                    borderColor: Colors.black,
                  ),

                  const SizedBox(height: 24),

                  // Giriş yap butonu
                  CustomButton(
                    text: 'Giriş Yap',
                    onPressed: _isLoading ? null : () => _login(),
                  ),
                  const SizedBox(height: 16),

                  // Kayıt ol butonu
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: 'Hesabın yok mu? ',
                        style: const TextStyle(
                          color: Color(0xFF8A0C27),
                          fontWeight: FontWeight.normal,
                          fontSize: 16,
                        ),
                        children: [
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RegisterPage(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size(0, 0),
                              ),
                              child: const Text(
                                'Kayıt Ol',
                                style: TextStyle(
                                  color: Color(0xFF8A0C27),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
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

          // Yükleme çubuğu ekranın ortasında yer alacak
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

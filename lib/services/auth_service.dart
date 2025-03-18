import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _supabase = Supabase.instance.client;

  // Mevcut kullanıcıyı getir
  User? get currentUser => _supabase.auth.currentUser;

  // Auth state değişikliklerini dinle
  Stream<bool> get authStateChanges =>
      _supabase.auth.onAuthStateChange.map((event) => event.session != null);

  // Kullanıcının giriş durumunu kontrol et
  Future<bool> isLoggedIn() async {
    return _supabase.auth.currentUser != null;
  }

  // Normal kullanıcı kaydı
  Future<void> registerNormalUser(
      String name, String surname, String email, String password) async {
    await _registerUser(name, surname, email, password, UserType.normal);
  }

  // Restoran hesabı kaydı
  Future<void> registerRestaurant(
      String name, String surname, String email, String password) async {
    await _registerUser(name, surname, email, password, UserType.restaurant);
  }

  // Admin hesabı kaydı (sadece diğer adminler tarafından yapılabilir)
  Future<void> registerAdmin(
      String name, String surname, String email, String password) async {
    final currentUserType = await getCurrentUserType();
    if (currentUserType != UserType.admin) {
      throw 'Sadece admin kullanıcılar yeni admin hesabı oluşturabilir';
    }
    await _registerUser(name, surname, email, password, UserType.admin);
  }

  // Temel kayıt işlemi
  Future<void> _registerUser(String name, String surname, String email,
      String password, UserType userType) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'surname': surname},
      );

      if (response.user != null) {
        // Kullanıcı profil bilgilerini kaydet
        await _supabase.from('users').insert({
          'id': response.user!.id,
          'email': email,
          'name': name,
          'surname': surname,
          'user_type': userType.toString().split('.').last,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      throw handleAuthError(e);
    }
  }

  // Kullanıcı tipini kontrol et
  Future<UserType> getCurrentUserType() async {
    try {
      if (_supabase.auth.currentUser != null) {
        final response = await _supabase
            .from('users')
            .select('user_type')
            .eq('id', _supabase.auth.currentUser!.id)
            .single();

        return UserType.values.firstWhere(
          (e) =>
              e.toString().split('.').last ==
              (response['user_type'] ?? 'normal'),
          orElse: () => UserType.normal,
        );
      }
      throw 'Kullanıcı girişi yapılmamış';
    } catch (e) {
      throw handleAuthError(e);
    }
  }

  // Yetki kontrolü
  Future<bool> hasPermission(UserType requiredType) async {
    try {
      final currentType = await getCurrentUserType();
      if (currentType == UserType.admin) return true;
      return currentType == requiredType;
    } catch (e) {
      return false;
    }
  }

  // Giriş yap
  Future<void> login(String email, String password) async {
    try {
      print('Login attempt for email: $email'); // Debug log
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null && response.user!.emailConfirmedAt == null) {
        throw AuthException('email-not-confirmed');
      }
    } on AuthException catch (e) {
      print('AuthException during login: ${e.message} (${e.statusCode})');
      throw e;
    } catch (e) {
      print('Unknown error during login: $e');
      throw AuthException('Invalid login credentials');
    }
  }

  // Çıkış yap
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw handleAuthError(e);
    }
  }

  // Kullanıcı bilgilerini getir
  Future<UserModel?> getCurrentUserData() async {
    try {
      if (_supabase.auth.currentUser != null) {
        print('Mevcut kullanıcı ID: ${_supabase.auth.currentUser!.id}');

        final response = await _supabase
            .from('users')
            .select()
            .eq('id', _supabase.auth.currentUser!.id)
            .single();

        print('Veritabanından gelen yanıt: $response');
        print('UserModel oluşturmadan önce veri: $response');
        final userModel = UserModel.fromMap(response);
        print('Oluşturulan UserModel: $userModel');

        return userModel;
      }
      print('Mevcut kullanıcı bulunamadı');
      return null;
    } catch (e) {
      print('Kullanıcı bilgileri alınırken hata: $e');
      print('Hata detayı: ${e.toString()}');
      return null;
    }
  }

  // Kayıt ol
  Future<void> register(
      String name, String surname, String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'surname': surname},
      );

      if (response.user != null) {
        // Kullanıcı profil bilgilerini kaydet
        await _supabase.from('users').insert({
          'id': response.user!.id,
          'email': email,
          'name': name,
          'surname': surname,
          'user_type': 'normal',
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      throw handleAuthError(e);
    }
  }

  // Şifre sıfırlama e-postası gönder
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo:
            null, // Artık redirectTo kullanmıyoruz çünkü token kullanacağız
      );
    } catch (e) {
      throw handleAuthError(e);
    }
  }

  // Şifre sıfırlama tokenini doğrula
  Future<bool> verifyResetToken(String email, String token) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.recovery,
      );
      return response.session != null;
    } catch (e) {
      throw handleAuthError(e);
    }
  }

  // Şifre güncelleme
  Future<void> updatePassword(String newPassword) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user == null) {
        throw 'Şifre güncellenemedi';
      }
    } catch (e) {
      throw handleAuthError(e);
    }
  }

  // Supabase Auth hatalarını Türkçe'ye çevir
  String handleAuthError(dynamic error) {
    // '_' karakterini kaldırarak public yaptık
    print('Raw error in handleAuthError: $error');
    print('Error type: ${error.runtimeType}');

    if (error is AuthException) {
      print(
          'Auth error details - Message: ${error.message}, Status: ${error.statusCode}');

      switch (error.message) {
        case 'email-not-confirmed':
          return 'Lütfen e-posta adresinizi onaylayın';
        case 'Invalid login credentials':
        case 'Invalid email or password':
          return 'Hatalı şifre girdiniz';
        case 'Invalid user credentials':
          return 'Hatalı şifre girdiniz';
        case 'User not found':
          return 'Kullanıcı bulunamadı';
        case 'Invalid email':
          return 'Geçersiz e-posta adresi';
        default:
          if (error.message.toLowerCase().contains('password') ||
              error.message.toLowerCase().contains('credentials') ||
              error.statusCode == 400) {
            return 'Hatalı şifre girdiniz';
          }
          return 'Hatalı şifre girdiniz';
      }
    }

    print('Unhandled error type: ${error.runtimeType}');
    return 'Hatalı şifre girdiniz';
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return null;

      final userData = await _supabase
          .from('users')
          .select()
          .eq('id', currentUser.id)
          .single();

      return UserModel.fromMap(userData);
    } catch (e) {
      debugPrint('getCurrentUser error: $e');
      return null;
    }
  }
}

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'login_page.dart';
import '../main.dart';
import 'admin_panel.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Widget _buildProfileImage(UserModel userData) {
    return CircleAvatar(
      radius: 50,
      backgroundColor: Colors.blue,
      backgroundImage: userData.profileImageUrl != null
          ? NetworkImage(userData.profileImageUrl!)
          : null,
      child: userData.profileImageUrl == null
          ? const Icon(
              Icons.person,
              size: 50,
              color: Colors.white,
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hesabım'),
      ),
      body: StreamBuilder<bool>(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final bool isLoggedIn = snapshot.data ?? false;

          if (!isLoggedIn) {
            return _buildLoginPrompt(context);
          }

          return _buildProfileContent(context);
        },
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_circle,
            size: 100,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Giriş yapmanız gerekiyor',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Profil bilgilerinizi görüntülemek için\nlütfen giriş yapın',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
            ),
            child: const Text(
              'Giriş Yap',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context) {
    final authService = AuthService();

    return FutureBuilder<UserModel?>(
      future: authService.getCurrentUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = snapshot.data;
        final user = authService.currentUser;

        if (userData == null || user == null) {
          return const Center(child: Text('Kullanıcı bilgileri alınamadı'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profil fotoğrafı
            Center(child: _buildProfileImage(userData)),
            const SizedBox(height: 24),
            // Kullanıcı bilgileri
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Ad Soyad'),
              subtitle: Text(userData.fullName),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('E-posta'),
              subtitle: Text(userData.email),
            ),
            const Divider(),
            // Ayarlar
            const ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Bildirimler'),
              trailing: Icon(Icons.chevron_right),
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.help),
              title: Text('Yardım'),
              trailing: Icon(Icons.chevron_right),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Hesabımı Düzenle'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfilePage(user: userData),
                  ),
                );
                if (result == true) {
                  setState(() {});
                }
              },
            ),
            const Divider(),
            if (userData.isAdmin || userData.isRestaurant)
              Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings),
                    title: const Text('Restoran Yönetimi'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminPanel(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                ],
              ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await authService.logout();
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainScreen(),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.exit_to_app),
                label: const Text('Çıkış Yap'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

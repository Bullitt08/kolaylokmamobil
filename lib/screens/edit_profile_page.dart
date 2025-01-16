import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class EditProfilePage extends StatefulWidget {
  final UserModel user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _surnameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _surnameController = TextEditingController(text: widget.user.surname);
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
    _addressController = TextEditingController(text: widget.user.address);
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() {
        _isLoading = true;
      });

      await DatabaseService().uploadProfileImage(widget.user.id, image.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil fotoğrafı güncellendi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteProfileImage() async {
    if (widget.user.profileImageUrl == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      await DatabaseService()
          .deleteProfileImage(widget.user.id, widget.user.profileImageUrl!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil fotoğrafı kaldırıldı')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Profil bilgilerini güncelle
      final updatedUser = UserModel(
        id: widget.user.id,
        email: widget.user.email,
        name: _nameController.text.trim(),
        surname: _surnameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        userType: widget.user.userType,
        restaurantId: widget.user.restaurantId,
      );

      await DatabaseService().updateUserProfile(updatedUser);

      // Şifre değişikliği varsa güncelle
      if (_currentPasswordController.text.isNotEmpty &&
          _newPasswordController.text.isNotEmpty) {
        await DatabaseService().updatePassword(
          _currentPasswordController.text,
          _newPasswordController.text,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil başarıyla güncellendi')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata oluştu: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildProfileImage() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.blue,
          backgroundImage: widget.user.profileImageUrl != null
              ? NetworkImage(widget.user.profileImageUrl!)
              : null,
          child: widget.user.profileImageUrl == null
              ? const Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.white,
                )
              : null,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: CircleAvatar(
            backgroundColor: Colors.white,
            radius: 18,
            child: IconButton(
              icon: Icon(
                widget.user.profileImageUrl != null
                    ? Icons.edit
                    : Icons.add_a_photo,
                size: 18,
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.photo_library),
                        title: const Text('Yeni Fotoğraf Seç'),
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage();
                        },
                      ),
                      if (widget.user.profileImageUrl != null)
                        ListTile(
                          leading: const Icon(Icons.delete),
                          title: const Text('Fotoğrafı Kaldır'),
                          onTap: () {
                            Navigator.pop(context);
                            _deleteProfileImage();
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildProfileImage(),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Ad',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen adınızı girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _surnameController,
                      decoration: const InputDecoration(
                        labelText: 'Soyad',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen soyadınızı girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Telefon Numarası',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Adres',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const Text(
                      'Şifre Değiştir',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _currentPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Mevcut Şifre',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureCurrentPassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _obscureCurrentPassword =
                                  !_obscureCurrentPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureCurrentPassword,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (_newPasswordController.text.isEmpty) {
                            return 'Yeni şifre de girilmeli';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Yeni Şifre',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureNewPassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _obscureNewPassword = !_obscureNewPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureNewPassword,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (value.length < 6) {
                            return 'Şifre en az 6 karakter olmalıdır';
                          }
                          if (_currentPasswordController.text.isEmpty) {
                            return 'Mevcut şifre de girilmeli';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Yeni Şifre (Tekrar)',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureConfirmPassword,
                      validator: (value) {
                        if (_newPasswordController.text.isNotEmpty) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen yeni şifrenizi tekrar girin';
                          }
                          if (value != _newPasswordController.text) {
                            return 'Şifreler eşleşmiyor';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Değişiklikleri Kaydet'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:kolaylokma/customs/custombutton.dart';
import 'package:kolaylokma/customs/customicon.dart';
import 'package:kolaylokma/customs/customtextformfield.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../models/restaurant_model.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import 'package:geolocator/geolocator.dart';
import './menu_management_screen.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final DatabaseService _databaseService = DatabaseService();
  List<RestaurantModel> restaurants = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    try {
      final List<RestaurantModel> loadedRestaurants =
          await _databaseService.getAllRestaurants();
      setState(() {
        restaurants = loadedRestaurants;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Restoranlar yüklenirken bir hata oluştu')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEDEFE8),
      appBar: AppBar(
        title: const Text(
          'Restoran Yönetimi',
          style: TextStyle(
            color: Color(0xFF8A0C27),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFFEDEFE8),
        actions: [
          IconButton(
            icon: const CustomIcon(
                iconData: Icons.add,
            ),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RestaurantEditScreen(),
                ),
              );
              if (result == true && mounted) {
                _loadRestaurants();
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: restaurants.length,
        itemBuilder: (context, index) {
          final restaurant = restaurants[index];
          return Column(
            children: [
              ListTile(
                leading: const CustomIcon(iconData: Icons.restaurant),
                title: Text(restaurant.name),
                subtitle: Text(restaurant.address),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const CustomIcon(iconData: Icons.menu_book),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MenuManagementScreen(
                              restaurant: restaurant,
                            ),
                          ),
                        );
                      },
                      tooltip: 'Menü Yönetimi',
                    ),
                    IconButton(
                      icon: const CustomIcon(iconData: Icons.edit),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RestaurantEditScreen(
                              restaurant: restaurant,
                            ),
                          ),
                        );
                        if (result == true && mounted) {
                          _loadRestaurants();
                        }
                      },
                      tooltip: 'Düzenle',
                    ),
                    IconButton(
                      icon: const CustomIcon(iconData: Icons.delete),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(color: Color(0xFF8A0C27), width: 2.0),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            backgroundColor: Color(0xFFEDEFE8),
                            title: const Text(
                              'Restoranı Sil',
                              style: TextStyle(
                                color: Color(0xFF8A0C27),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: const Text(
                              'Bu restoranı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz!',
                              style: TextStyle(
                                color: Colors.black,
                              ),
                            ),
                            actions: [
                              CustomButton(
                                text: 'İptal',
                                backgroundColor: Colors.transparent,
                                textColor: const Color(0xFF8A0C27),
                                onPressed: () =>
                                    Navigator.pop(context, false),
                              ),
                              CustomButton(
                                text: 'Sil',
                                onPressed: () =>
                                    Navigator.pop(context, true),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true && mounted) {
                          try {
                            await _databaseService
                                .deleteRestaurant(restaurant.id);
                            _loadRestaurants();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Restoran başarıyla silindi'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Silme işlemi başarısız: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      tooltip: 'Sil',
                    ),
                  ],
                ),
              ),
              const Divider(),
            ],
          );
        },
      ),
    );
  }
}

class RestaurantEditScreen extends StatefulWidget {
  final RestaurantModel? restaurant;

  const RestaurantEditScreen({super.key, this.restaurant});

  @override
  State<RestaurantEditScreen> createState() => _RestaurantEditScreenState();
}

class _RestaurantEditScreenState extends State<RestaurantEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  LatLng? _selectedLocation;
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  final MapController _mapController = MapController();
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    if (!mounted) return;
    setState(() => _isLoadingLocation = true);
    try {
      final position = await _getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _selectedLocation = widget.restaurant != null
            ? LatLng(widget.restaurant!.latitude, widget.restaurant!.longitude)
            : LatLng(position.latitude, position.longitude);
      });
      _mapController.move(_selectedLocation!, 15);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konum alınamadı')),
        );
      }
    } finally {
      if (!mounted) return;
      setState(() => _isLoadingLocation = false);
    }

    if (!mounted) return;
    if (widget.restaurant != null) {
      _nameController.text = widget.restaurant!.name;
      _addressController.text = widget.restaurant!.address;
      _descriptionController.text = widget.restaurant!.description;
      _phoneController.text = widget.restaurant!.phone_number;
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Konum servisleri devre dışı');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Konum izni reddedildi');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Konum izni kalıcı olarak reddedildi');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _goToUserLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final position = await _getCurrentLocation();
      final userLocation = LatLng(position.latitude, position.longitude);
      _mapController.move(userLocation, 15);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konum alınamadı')),
        );
      }
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurant == null
            ? 'Yeni Restoran Ekle'
            : 'Restoran Düzenle',
          style: const TextStyle(
            color: Color(0xFF8A0C27),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFEDEFE8),
      ),
      body:Container(
        decoration: BoxDecoration(
          color: Color(0xFFEDEFE8),
        ),
        child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            CustomTextFormField(
              controller: _nameController,
              labelText: 'Restoran Adı',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lütfen restoran adını giriniz';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),
            CustomTextFormField(
              controller: _descriptionController,
              labelText: 'Açıklama',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lütfen açıklama giriniz';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextFormField(
              controller: _addressController,
              labelText: 'Adres',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lütfen adresi giriniz';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextFormField(
              controller: _phoneController,
              labelText: 'Telefon',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lütfen telefon numarası giriniz';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Stack(
              children: [
                SizedBox(
                  height: 300,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter:
                      _selectedLocation ?? const LatLng(41.0082, 28.9784),
                      initialZoom: 13,
                      onTap: (tapPosition, point) {
                        setState(() {
                          _selectedLocation = point;
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.kolaylokma.app',
                      ),
                      if (_selectedLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _selectedLocation!,
                              width: 40,
                              height: 40,
                              child: const CustomIcon(
                                iconData:  Icons.location_on,
                                iconColor: Color(0xFF8A0C27),
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Positioned(
                  right: 10,
                  bottom: 100,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        backgroundColor: Color(0xFF8A0C27),
                        heroTag: 'zoomIn',
                        mini: true,
                        onPressed: () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(
                            _mapController.camera.center,
                            currentZoom + 1,
                          );
                        },
                        child: const CustomIcon(iconData: Icons.add,
                          iconColor: Color(0xFFEDEFE8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        backgroundColor: Color(0xFF8A0C27),
                        heroTag: 'zoomOut',
                        mini: true,
                        onPressed: () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(
                            _mapController.camera.center,
                            currentZoom - 1,
                          );
                        },
                        child: const CustomIcon(iconData: Icons.remove,
                          iconColor: Color(0xFFEDEFE8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        backgroundColor: Color(0xFF8A0C27),
                        heroTag: 'location',
                        mini: true,
                        onPressed:
                        _isLoadingLocation ? null : _goToUserLocation,
                        child: _isLoadingLocation
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                            : const CustomIcon(iconData: Icons.my_location,
                          iconColor: Color(0xFFEDEFE8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomButton(
              onPressed: () async {
                if (_formKey.currentState!.validate() &&
                    _selectedLocation != null) {
                  try {
                    final currentUser = await _authService.getCurrentUserData();
                    if (currentUser == null) {
                      throw Exception('Kullanıcı bilgileri alınamadı');
                    }

                    final restaurant = RestaurantModel(
                      id: widget.restaurant?.id ?? const Uuid().v4(),
                      name: _nameController.text,
                      description: _descriptionController.text,
                      address: _addressController.text,
                      phone_number: _phoneController.text,
                      latitude: _selectedLocation!.latitude,
                      longitude: _selectedLocation!.longitude,
                      ownerId: currentUser.id,
                      rating: widget.restaurant?.rating ?? 0,
                      isOpen: widget.restaurant?.isOpen ?? true,
                      imageUrl: widget.restaurant?.imageUrl ?? '',
                      ratingCount: widget.restaurant?.ratingCount ?? 0,
                      workingHours: widget.restaurant?.workingHours ?? {},
                      createdAt: widget.restaurant?.createdAt,
                    );

                    if (widget.restaurant == null) {
                      await _databaseService.addRestaurant(restaurant);
                      if (!currentUser.isRestaurant) {
                        await _databaseService.updateUser(currentUser.id, {
                          'user_type': 'restaurant',
                          'restaurant_id': restaurant.id,
                        });
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Restoran başarıyla eklendi'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pop(context, true);
                      }
                    } else {
                      await _databaseService.updateRestaurantData(restaurant);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Restoran başarıyla güncellendi'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pop(context, true);
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Bir hata oluştu: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } else if (_selectedLocation == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lütfen haritadan konum seçiniz'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              text: widget.restaurant == null ? 'Restoran Ekle' : 'Güncelle',
            ),
          ],
        ),
      ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}

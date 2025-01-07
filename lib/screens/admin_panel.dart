import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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
      appBar: AppBar(
        title: const Text('Restoran Yönetimi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
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
                return ListTile(
                  leading: const Icon(Icons.restaurant),
                  title: Text(restaurant.name),
                  subtitle: Text(restaurant.address),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu_book),
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
                        icon: const Icon(Icons.edit),
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
                    ],
                  ),
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
            : 'Restoran Düzenle'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Restoran Adı',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lütfen restoran adını giriniz';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Açıklama',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lütfen açıklama giriniz';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Adres',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lütfen adresi giriniz';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefon',
              ),
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
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
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
                        heroTag: 'zoomIn',
                        mini: true,
                        onPressed: () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(
                            _mapController.camera.center,
                            currentZoom + 1,
                          );
                        },
                        child: const Icon(Icons.add),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        heroTag: 'zoomOut',
                        mini: true,
                        onPressed: () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(
                            _mapController.camera.center,
                            currentZoom - 1,
                          );
                        },
                        child: const Icon(Icons.remove),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
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
                            : const Icon(Icons.my_location),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
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
              child: Text(
                widget.restaurant == null ? 'Restoran Ekle' : 'Güncelle',
              ),
            ),
          ],
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

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:kolaylokma/customs/custombutton.dart';
import 'package:kolaylokma/customs/customicon.dart';
import 'package:kolaylokma/customs/customtextformfield.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../models/restaurant_model.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import 'package:geolocator/geolocator.dart';
import './menu_management_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
                                    side: const BorderSide(
                                        color: Color(0xFF8A0C27), width: 2.0),
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
                                        content:
                                            Text('Restoran başarıyla silindi'),
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

class _RestaurantEditScreenState extends State<RestaurantEditScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  LatLng? _selectedLocation;
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  final MapController _mapController = MapController();
  List<String> restaurantPhotos = [];
  bool _isLoadingPhotos = false;
  bool _isLoadingLocation = false;
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    if (widget.restaurant != null) {
      _nameController.text = widget.restaurant!.name;
      _addressController.text = widget.restaurant!.address;
      _descriptionController.text = widget.restaurant!.description;
      _phoneController.text = widget.restaurant!.phone_number;
      _selectedLocation =
          LatLng(widget.restaurant!.latitude, widget.restaurant!.longitude);
      _loadRestaurantPhotos();
    }
  }

  Future<void> _loadRestaurantPhotos() async {
    if (widget.restaurant == null) return;

    setState(() => _isLoadingPhotos = true);
    try {
      final photos =
          await _databaseService.getRestaurantPhotos(widget.restaurant!.id);
      setState(() {
        restaurantPhotos = photos.take(4).toList(); // Limit to 4 photos
        _isLoadingPhotos = false;
      });
    } catch (e) {
      print('Error loading restaurant photos: $e');
      setState(() => _isLoadingPhotos = false);
    }
  }

  Future<void> _addPhoto() async {
    if (restaurantPhotos.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En fazla 4 fotoğraf ekleyebilirsiniz')),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() => _isLoadingPhotos = true);
    try {
      final fileName =
          'restaurant_${widget.restaurant?.id ?? 'new'}_${DateTime.now().millisecondsSinceEpoch}.${image.path.split('.').last}';
      final imageUrl = await _databaseService.uploadRestaurantPhoto(
        widget.restaurant?.id ?? 'new',
        image.path,
        fileName,
      );

      setState(() {
        restaurantPhotos.add(imageUrl);
        _isLoadingPhotos = false;
      });
    } catch (e) {
      print('Error uploading photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fotoğraf yüklenirken hata oluştu: $e')),
      );
      setState(() => _isLoadingPhotos = false);
    }
  }

  Future<void> _removePhoto(String photoUrl) async {
    setState(() => _isLoadingPhotos = true);
    try {
      await _databaseService.deleteRestaurantPhoto(
          widget.restaurant?.id ?? '', photoUrl);
      setState(() {
        restaurantPhotos.remove(photoUrl);
        _isLoadingPhotos = false;
      });
    } catch (e) {
      print('Error deleting photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fotoğraf silinirken hata oluştu: $e')),
      );
      setState(() => _isLoadingPhotos = false);
    }
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Restoran Fotoğrafları',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: _isLoadingPhotos
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ...restaurantPhotos.map((photo) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  photo,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                right: 4,
                                top: 4,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.red, size: 20),
                                    onPressed: () => _removePhoto(photo),
                                    constraints: const BoxConstraints(
                                      minWidth: 24,
                                      minHeight: 24,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                    if (restaurantPhotos.length < 4)
                      InkWell(
                        onTap: _addPhoto,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF8A0C27)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate,
                                  color: Color(0xFF8A0C27)),
                              SizedBox(height: 4),
                              Text('Fotoğraf Ekle',
                                  style: TextStyle(color: Color(0xFF8A0C27))),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.restaurant == null ? 'Yeni Restoran Ekle' : 'Restoran Düzenle',
          style: const TextStyle(
            color: Color(0xFF8A0C27),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFEDEFE8),
      ),
      body: Container(
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
              Stack(
                children: [
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
                  if (_isLoadingAddress)
                    const Positioned(
                      right: 8,
                      top: 8,
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                ],
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
                          animatedMapMove(point, _mapController.camera.zoom);
                          _getAddressFromLatLng(point);
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
                                  iconData: Icons.location_on,
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
                            animatedMapMove(
                              _mapController.camera.center,
                              currentZoom + 1,
                            );
                          },
                          child: const CustomIcon(
                            iconData: Icons.add,
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
                            animatedMapMove(
                              _mapController.camera.center,
                              currentZoom - 1,
                            );
                          },
                          child: const CustomIcon(
                            iconData: Icons.remove,
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
                              : const CustomIcon(
                                  iconData: Icons.my_location,
                                  iconColor: Color(0xFFEDEFE8),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Restoran Fotoğrafları',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8A0C27),
                ),
              ),
              const SizedBox(height: 8),
              _buildPhotoSection(),
              const SizedBox(height: 16),
              CustomButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate() &&
                      _selectedLocation != null) {
                    try {
                      final currentUser =
                          await _authService.getCurrentUserData();
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

  Future<void> _getAddressFromLatLng(LatLng location) async {
    setState(() => _isLoadingAddress = true);
    try {
      final response = await http.get(Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${location.latitude}&lon=${location.longitude}&addressdetails=1'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['display_name'] != null) {
          final address = data['display_name'];
          setState(() {
            _addressController.text = address;
          });
        }
      }
    } catch (e) {
      debugPrint('Adres alınırken hata oluştu: $e');
    } finally {
      setState(() => _isLoadingAddress = false);
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

  void animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(
        begin: _mapController.camera.center.latitude,
        end: destLocation.latitude);
    final lngTween = Tween<double>(
        begin: _mapController.camera.center.longitude,
        end: destLocation.longitude);
    final zoomTween =
        Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    final controller = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);

    final Animation<double> animation =
        CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      } else if (status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  Future<void> _goToUserLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final position = await _getCurrentLocation();
      final userLocation = LatLng(position.latitude, position.longitude);
      animatedMapMove(userLocation, 15);
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
}

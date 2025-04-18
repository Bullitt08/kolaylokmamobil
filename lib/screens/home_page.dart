import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:kolaylokma/customs/customicon.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../services/database_service.dart';
import '../models/restaurant_model.dart';
import '../models/review_model.dart';
import 'restaurant_reviews_page.dart';

class HomePage extends StatefulWidget {
  final Function? onLocationReady;

  const HomePage({super.key, this.onLocationReady});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final mapController = MapController();
  final _databaseService = DatabaseService();
  LatLng? currentPosition;
  List<RestaurantModel> restaurants = [];
  StreamSubscription<Position>? _positionStreamSubscription;
  Map<String, PageController> _photoPageControllers =
      {}; // Her restoran için ayrı controller
  Map<String, int> _currentPhotoIndices = {}; // Her restoran için ayrı index
  bool _isLoadingLocation = true;
  String? _locationError;
  Timer? _locationTimeout;
  @override
  void initState() {
    super.initState();
    debugPrint('HomePage initState çağrıldı');
    _initializeLocationWithTimeout();
    _loadRestaurants();
  }

  @override
  void dispose() {
    _locationTimeout?.cancel();
    _photoPageControllers.values.forEach((controller) => controller.dispose());
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  String _getWeekdayName(String day) {
    switch (day.toLowerCase()) {
      case 'monday':
        return 'Pazartesi';
      case 'tuesday':
        return 'Salı';
      case 'wednesday':
        return 'Çarşamba';
      case 'thursday':
        return 'Perşembe';
      case 'friday':
        return 'Cuma';
      case 'saturday':
        return 'Cumartesi';
      case 'sunday':
        return 'Pazar';
      default:
        return day;
    }
  }

  Future<void> _initializeLocationWithTimeout() async {
    _locationTimeout = Timer(const Duration(seconds: 15), () {
      if (_isLoadingLocation && mounted) {
        setState(() {
          _locationError =
              'Konum alınamadı. Lütfen konum servislerini kontrol edin ve tekrar deneyin.';
          _isLoadingLocation = false;
        });
      }
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Lütfen konum servislerini açın';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Konum izni reddedildi';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Konum izni kalıcı olarak reddedildi. Lütfen ayarlardan konum iznini verin.';
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () =>
            throw 'Konum alınamadı. Lütfen internet bağlantınızı kontrol edin.',
      );

      if (mounted) {
        setState(() {
          currentPosition = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
          _locationError = null;
        });

        _startLocationUpdates();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = e.toString();
          _isLoadingLocation = false;
        });
      }
      debugPrint('Konum alma hatası: $e');
    } finally {
      _locationTimeout?.cancel();
    }
  }

  void _startLocationUpdates() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      (Position position) {
        if (mounted) {
          setState(() {
            currentPosition = LatLng(position.latitude, position.longitude);
          });
        }
      },
      onError: (e) {
        debugPrint('Konum güncellemesi alınamadı: $e');
      },
    );
  }

  Future<void> _loadRestaurants() async {
    try {
      debugPrint('Restoranlar yükleniyor...');
      final loadedRestaurants = await _databaseService.getAllRestaurants();
      debugPrint('Yüklenen restoran sayısı: ${loadedRestaurants.length}');
      if (mounted) {
        setState(() {
          restaurants = loadedRestaurants;
        });
      }
    } catch (e) {
      debugPrint('Restoranlar yüklenirken hata: $e');
    }
  }

  Future<List<RestaurantModel>?> applyFiltersAndShowResults(
      Map<String, dynamic> filters) async {
    List<RestaurantModel> tempFilteredRestaurants = List.from(restaurants);

    // Menü içeriği araması varsa
    if (filters['menuSearch'] != null && filters['menuSearch'].isNotEmpty) {
      final menuSearch = filters['menuSearch'].toLowerCase();
      final List<RestaurantModel> menuFilteredRestaurants = [];

      for (var restaurant in tempFilteredRestaurants) {
        try {
          final menus =
              await _databaseService.getRestaurantMenus(restaurant.id);
          bool hasMatchingMenuItem = menus.any((menu) {
            final name = (menu['name'] ?? '').toString().toLowerCase();
            final description =
                (menu['description'] ?? '').toString().toLowerCase();
            return name.contains(menuSearch) ||
                description.contains(menuSearch);
          });

          if (hasMatchingMenuItem) {
            menuFilteredRestaurants.add(restaurant);
          }
        } catch (e) {
          debugPrint('Menü filtreleme hatası: $e');
        }
      }

      tempFilteredRestaurants = menuFilteredRestaurants;
    }

    // Diğer filtreleri uygula
    tempFilteredRestaurants = await Future.wait(
        tempFilteredRestaurants.map((restaurant) async {
      // Mesafe filtresi
      if (currentPosition != null && filters['maxDistance'] != null) {
        final distance = Geolocator.distanceBetween(
          currentPosition!.latitude,
          currentPosition!.longitude,
          restaurant.latitude,
          restaurant.longitude,
        );
        if (distance > filters['maxDistance'] * 1000) {
          return null;
        }
      }

      // Minimum değerlendirme filtresi
      if (filters['minRating'] != null) {
        if (restaurant.rating < filters['minRating']) {
          return null;
        }
      }

      // Sadece açık restoranlar filtresi
      if (filters['onlyOpen'] == true) {
        if (!restaurant.isOpen) {
          return null;
        }
      }

      // Kategori filtresi
      if (filters['categories'] != null &&
          (filters['categories'] as List).isNotEmpty) {
        // Menü kategorilerine göre filtreleme yapılacak
        final menus = await _databaseService.getRestaurantMenus(restaurant.id);
        final menuCategories =
            menus.map((m) => m['category'].toString()).toSet();
        if (!menuCategories
            .any((c) => (filters['categories'] as List).contains(c))) {
          return null;
        }
      }

      return restaurant;
    })).then((restaurants) =>
        restaurants.where((r) => r != null).cast<RestaurantModel>().toList());

    return tempFilteredRestaurants;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoadingLocation) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8A0C27)),
            ),
            SizedBox(height: 16),
            Text('Konum alınıyor...'),
          ],
        ),
      );
    }

    if (_locationError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_off,
              size: 64,
              color: Color(0xFF8A0C27),
            ),
            const SizedBox(height: 16),
            Text(
              _locationError!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializeLocationWithTimeout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8A0C27),
                foregroundColor: Colors.white,
              ),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: currentPosition!,
            initialZoom: 15,
            maxZoom: 18,
            minZoom: 3,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.kolaylokma.app',
            ),
            MarkerLayer(
              markers: [
                // Kullanıcının konumu
                Marker(
                  point: currentPosition!,
                  width: 50,
                  height: 50,
                  child: Stack(
                    children: [
                      Center(
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.blue[600],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Restoranların konumları
                ...restaurants.map((restaurant) {
                  debugPrint(
                      'Restoran marker oluşturuluyor: ${restaurant.name} - (${restaurant.latitude}, ${restaurant.longitude})');
                  return Marker(
                    point: LatLng(restaurant.latitude, restaurant.longitude),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () async {
                        try {
                          final menus = await _databaseService
                              .getRestaurantMenus(restaurant.id);
                          if (mounted) {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20)),
                              ),
                              builder: (context) => DraggableScrollableSheet(
                                initialChildSize: 0.6,
                                minChildSize: 0.3,
                                maxChildSize: 0.9,
                                expand: false,
                                builder: (context, scrollController) =>
                                    DefaultTabController(
                                  length: 3,
                                  child: Column(
                                    children: [
                                      // Photo Gallery Section
                                      StatefulBuilder(
                                        builder: (context, setState) {
                                          return FutureBuilder<List<String>>(
                                            future: Future.wait([
                                              _databaseService
                                                  .getRestaurantPhotos(
                                                      restaurant.id),
                                              _databaseService
                                                  .getRestaurantReviews(
                                                      restaurant.id)
                                            ]).then((List<dynamic> results) {
                                              final List<String>
                                                  restaurantPhotos =
                                                  List<String>.from(results[0]);
                                              final List<ReviewModel> reviews =
                                                  List<ReviewModel>.from(
                                                      results[1]);
                                              final List<String> reviewPhotos =
                                                  reviews
                                                      .expand((review) =>
                                                          List<String>.from(
                                                              review.photos))
                                                      .toList();
                                              return [
                                                ...restaurantPhotos,
                                                ...reviewPhotos
                                              ];
                                            }),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData) {
                                                final allPhotos =
                                                    snapshot.data!;
                                                final sliderPhotos =
                                                    allPhotos.take(10).toList();

                                                if (sliderPhotos.isEmpty) {
                                                  return Container(
                                                    height: 200,
                                                    color: Colors.grey[200],
                                                    child: const Icon(
                                                        Icons.restaurant,
                                                        size: 50,
                                                        color: Colors.grey),
                                                  );
                                                }

                                                // Her restoran için bir controller oluştur
                                                if (!_photoPageControllers
                                                    .containsKey(
                                                        restaurant.id)) {
                                                  _photoPageControllers[
                                                          restaurant.id] =
                                                      PageController();
                                                  _currentPhotoIndices[
                                                      restaurant.id] = 0;
                                                }
                                                return RestaurantPhotoGallery(
                                                  sliderPhotos: sliderPhotos,
                                                  allPhotos: allPhotos,
                                                  controller:
                                                      _photoPageControllers[
                                                          restaurant.id]!,
                                                  currentIndex:
                                                      _currentPhotoIndices[
                                                          restaurant.id]!,
                                                  onPageChanged: (index) {
                                                    setState(() {
                                                      _currentPhotoIndices[
                                                              restaurant.id] =
                                                          index;
                                                    });
                                                  },
                                                );
                                              }
                                              return Container(
                                                height: 200,
                                                color: Colors.grey[200],
                                                child: const Icon(
                                                    Icons.restaurant,
                                                    size: 50,
                                                    color: Colors.grey),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.3),
                                              spreadRadius: 1,
                                              blurRadius: 5,
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              restaurant.name,
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(Icons.star,
                                                    color: Colors.amber,
                                                    size: 20),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${restaurant.rating.toStringAsFixed(1)} (${restaurant.ratingCount})',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            ElevatedButton.icon(
                                              onPressed: () async {
                                                final Uri url = Uri.parse(
                                                    'https://www.google.com/maps/dir/?api=1&destination=${restaurant.latitude},${restaurant.longitude}');
                                                try {
                                                  await launchUrl(url);
                                                } catch (e) {
                                                  debugPrint(
                                                      'Harita açılamadı: $e');
                                                }
                                              },
                                              icon:
                                                  const Icon(Icons.directions),
                                              label: const Text('Rota Oluştur'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFF8A0C27),
                                                foregroundColor: Colors.white,
                                                minimumSize: const Size(
                                                    double.infinity, 45),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            TabBar(
                                              tabs: const [
                                                Tab(text: 'Genel Bakış'),
                                                Tab(text: 'Menü'),
                                                Tab(text: 'Yorumlar'),
                                              ],
                                              labelColor:
                                                  const Color(0xFF8A0C27),
                                              unselectedLabelColor: Colors.grey,
                                              indicatorColor:
                                                  const Color(0xFF8A0C27),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: TabBarView(
                                          children: [
                                            // Genel Bakış Tab
                                            SingleChildScrollView(
                                              controller: scrollController,
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  if (restaurant.description
                                                      .isNotEmpty) ...[
                                                    const SizedBox(height: 16),
                                                    const Text(
                                                      'Açıklama',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                        restaurant.description),
                                                    const SizedBox(
                                                      height: 16,
                                                    ),
                                                    const Text(
                                                      'Adres',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(restaurant.address),
                                                    const SizedBox(height: 16),
                                                    const Text(
                                                      'Telefon',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(restaurant
                                                        .phone_number),
                                                    const SizedBox(height: 16),
                                                    const Text(
                                                      'Çalışma Saatleri',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        for (var entry
                                                            in restaurant
                                                                .workingHours
                                                                .entries)
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    bottom: 4),
                                                            child: Text(
                                                              '${_getWeekdayName(entry.key)}: ${entry.value['open'] ?? 'Kapalı'} - ${entry.value['close'] ?? 'Kapalı'}',
                                                              style:
                                                                  const TextStyle(
                                                                      height:
                                                                          1.5),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            // Menü Tab
                                            ListView.builder(
                                              controller: scrollController,
                                              padding: const EdgeInsets.all(16),
                                              itemCount: menus.length,
                                              itemBuilder: (context, index) {
                                                final menu = menus[index];
                                                return Card(
                                                  elevation: 2,
                                                  margin: const EdgeInsets.only(
                                                      bottom: 12),
                                                  child: ListTile(
                                                    contentPadding:
                                                        const EdgeInsets.all(
                                                            16),
                                                    title: Text(
                                                      menu['name'],
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    subtitle: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(menu[
                                                                'description'] ??
                                                            ''),
                                                        const SizedBox(
                                                            height: 8),
                                                        Text(
                                                          '${menu['price']} ₺',
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.green,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    trailing:
                                                        menu['image_url'] !=
                                                                null
                                                            ? GestureDetector(
                                                                onTap: () {
                                                                  showDialog(
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (context) =>
                                                                            Dialog(
                                                                      insetPadding:
                                                                          const EdgeInsets
                                                                              .all(
                                                                              16),
                                                                      child:
                                                                          Stack(
                                                                        children: [
                                                                          InteractiveViewer(
                                                                            panEnabled:
                                                                                true,
                                                                            boundaryMargin:
                                                                                const EdgeInsets.all(8),
                                                                            minScale:
                                                                                0.5,
                                                                            maxScale:
                                                                                4,
                                                                            child:
                                                                                Image.network(
                                                                              menu['image_url'],
                                                                              fit: BoxFit.contain,
                                                                            ),
                                                                          ),
                                                                          Positioned(
                                                                            right:
                                                                                8,
                                                                            top:
                                                                                8,
                                                                            child:
                                                                                IconButton(
                                                                              icon: const Icon(Icons.close, color: Colors.white),
                                                                              onPressed: () => Navigator.pop(context),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  );
                                                                },
                                                                child:
                                                                    ClipRRect(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8),
                                                                  child: Image
                                                                      .network(
                                                                    menu[
                                                                        'image_url'],
                                                                    width: 60,
                                                                    height: 60,
                                                                    fit: BoxFit
                                                                        .cover,
                                                                    errorBuilder:
                                                                        (context,
                                                                            error,
                                                                            stackTrace) {
                                                                      return Container(
                                                                        width:
                                                                            60,
                                                                        height:
                                                                            60,
                                                                        color: Colors
                                                                            .grey[200],
                                                                        child:
                                                                            const Icon(
                                                                          Icons
                                                                              .error_outline,
                                                                          color:
                                                                              Colors.grey,
                                                                          size:
                                                                              30,
                                                                        ),
                                                                      );
                                                                    },
                                                                    loadingBuilder:
                                                                        (context,
                                                                            child,
                                                                            loadingProgress) {
                                                                      if (loadingProgress ==
                                                                          null)
                                                                        return child;
                                                                      return Container(
                                                                        width:
                                                                            60,
                                                                        height:
                                                                            60,
                                                                        child:
                                                                            Center(
                                                                          child:
                                                                              CircularProgressIndicator(
                                                                            value: loadingProgress.expectedTotalBytes != null
                                                                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                                                : null,
                                                                          ),
                                                                        ),
                                                                      );
                                                                    },
                                                                  ),
                                                                ),
                                                              )
                                                            : null,
                                                  ),
                                                );
                                              },
                                            ),
                                            // Yorumlar Tab
                                            RestaurantReviewsPage(
                                                restaurant: restaurant),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Menüler yüklenirken bir hata oluştu'),
                              backgroundColor: Color(0xFF8A0C27),
                            ),
                          );
                        }
                      },
                      child: Stack(
                        children: [
                          Center(
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Color(0xFF8A0C27),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.restaurant,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            children: [
              FloatingActionButton(
                backgroundColor: Color(0xFFEDEFE8),
                heroTag: "zoomIn",
                onPressed: () {
                  final currentZoom = mapController.camera.zoom;
                  final center = mapController.camera.center;
                  animatedMapMove(center, currentZoom + 1);
                },
                child: const CustomIcon(
                  iconData: Icons.add,
                  iconColor: Color(0xFF8A0C27),
                ),
              ),
              const SizedBox(height: 16),
              FloatingActionButton(
                backgroundColor: Color(0xFFEDEFE8),
                heroTag: "zoomOut",
                onPressed: () {
                  final currentZoom = mapController.camera.zoom;
                  final center = mapController.camera.center;
                  animatedMapMove(center, currentZoom - 1);
                },
                child: const CustomIcon(
                  iconData: Icons.remove,
                  iconColor: Color(0xFF8A0C27),
                ),
              ),
              const SizedBox(height: 16),
              FloatingActionButton(
                backgroundColor: Color(0xFFEDEFE8),
                heroTag: "myLocation",
                onPressed: () {
                  if (currentPosition != null) {
                    animatedMapMove(currentPosition!, 15);
                  }
                },
                child: const CustomIcon(
                  iconData: Icons.my_location,
                  iconColor: Color(0xFF8A0C27),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Platform specific konum alma fonksiyonu
  Future<LatLng> getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    return LatLng(position.latitude, position.longitude);
  }

  void animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(
        begin: mapController.camera.center.latitude,
        end: destLocation.latitude);
    final lngTween = Tween<double>(
        begin: mapController.camera.center.longitude,
        end: destLocation.longitude);
    final zoomTween =
        Tween<double>(begin: mapController.camera.zoom, end: destZoom);

    final controller = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);

    final Animation<double> animation =
        CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      mapController.move(
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
}

// Full Screen Gallery Widget
class FullScreenGallery extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;

  const FullScreenGallery({
    Key? key,
    required this.photos,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<FullScreenGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.photos.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    widget.photos[index],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[900],
                        child: const Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 50,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                bottom: 16,
                left: 16,
                right: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    '${_currentIndex + 1}/${widget.photos.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Photo Gallery Widget
class RestaurantPhotoGallery extends StatefulWidget {
  final List<String> sliderPhotos;
  final List<String> allPhotos;
  final PageController controller;
  final int currentIndex;
  final Function(int) onPageChanged;

  const RestaurantPhotoGallery({
    Key? key,
    required this.sliderPhotos,
    required this.allPhotos,
    required this.controller,
    required this.currentIndex,
    required this.onPageChanged,
  }) : super(key: key);

  @override
  State<RestaurantPhotoGallery> createState() => _RestaurantPhotoGalleryState();
}

class _RestaurantPhotoGalleryState extends State<RestaurantPhotoGallery> {
  Map<int, Key> _progressKeys = {};

  void _resetProgress(int index) {
    setState(() {
      _progressKeys[index] = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PhotoGridGallery(photos: widget.allPhotos),
          ),
        );
      },
      child: Container(
        height: 200,
        child: Stack(
          children: [
            PageView.builder(
              controller: widget.controller,
              itemCount: widget.sliderPhotos.length,
              onPageChanged: widget.onPageChanged,
              itemBuilder: (context, index) {
                return Image.network(
                  widget.sliderPhotos[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.error_outline,
                        color: Colors.grey,
                        size: 40,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            if (widget.sliderPhotos.length > 1) ...[
              Positioned.fill(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: widget.currentIndex > 0
                          ? () {
                              widget.controller.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                              _resetProgress(widget.currentIndex - 1);
                            }
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios,
                          color: Colors.white),
                      onPressed:
                          widget.currentIndex < widget.sliderPhotos.length - 1
                              ? () {
                                  widget.controller.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                  _resetProgress(widget.currentIndex + 1);
                                }
                              : null,
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.sliderPhotos.length, (index) {
                    bool isCurrentPhoto = index == widget.currentIndex;
                    if (!_progressKeys.containsKey(index)) {
                      _progressKeys[index] = UniqueKey();
                    }
                    return Container(
                      width: 6,
                      height: 24,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      child: TweenAnimationBuilder<double>(
                        key: isCurrentPhoto ? _progressKeys[index] : null,
                        duration: const Duration(seconds: 5),
                        tween:
                            Tween(begin: 0.0, end: isCurrentPhoto ? 1.0 : 0.0),
                        onEnd: () {
                          if (isCurrentPhoto) {
                            if (widget.currentIndex <
                                widget.sliderPhotos.length - 1) {
                              widget.controller.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                              _resetProgress(widget.currentIndex + 1);
                            } else {
                              widget.controller.animateToPage(
                                0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                              _resetProgress(0);
                            }
                          }
                        },
                        builder: (context, value, child) {
                          return Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              if (isCurrentPhoto)
                                Positioned.fill(
                                  bottom: 24 - (24 * value),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3),
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    );
                  }),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PhotoGridGallery extends StatelessWidget {
  final List<String> photos;

  const PhotoGridGallery({
    Key? key,
    required this.photos,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tüm Fotoğraflar (${photos.length})',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(1),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 1,
          crossAxisSpacing: 1,
        ),
        itemCount: photos.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullScreenGallery(
                    photos: photos,
                    initialIndex: index,
                  ),
                ),
              );
            },
            child: Hero(
              tag: 'photo_${photos[index]}',
              child: Container(
                color: Colors.grey[900],
                child: Image.network(
                  photos[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.error_outline,
                      color: Colors.white54,
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Photo Data Model
class PhotoData {
  final List<String> allPhotos;
  final List<String> sliderPhotos;

  PhotoData({required this.allPhotos})
      : sliderPhotos = allPhotos.take(10).toList();
}

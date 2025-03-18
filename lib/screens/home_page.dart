import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:kolaylokma/customs/customicon.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../services/database_service.dart';
import '../models/restaurant_model.dart';
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

  @override
  void initState() {
    super.initState();
    debugPrint('HomePage initState çağrıldı');
    _initializeLocation();
    _loadRestaurants();
  }

  Future<void> _initializeLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      if (mounted) {
        setState(() {
          currentPosition = LatLng(position.latitude, position.longitude);
        });

        if (widget.onLocationReady != null) {
          widget.onLocationReady!();
        }
      }

      // Konum güncellemelerini dinle
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position position) {
        if (mounted) {
          setState(() {
            currentPosition = LatLng(position.latitude, position.longitude);
          });
        }
      });
    } catch (e) {
      debugPrint('Konum alınamadı: $e');
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
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
    debugPrint(
        'HomePage build çağrıldı. Restoran sayısı: ${restaurants.length}');
    return Scaffold(
      body: currentPosition == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Konum alınıyor...'),
                ],
              ),
            )
          : Stack(
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
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                            point: LatLng(
                                restaurant.latitude, restaurant.longitude),
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
                                      builder: (context) =>
                                          DraggableScrollableSheet(
                                        initialChildSize: 0.6,
                                        minChildSize: 0.3,
                                        maxChildSize: 0.9,
                                        expand: false,
                                        builder: (context, scrollController) =>
                                            DefaultTabController(
                                          length: 2,
                                          child: Column(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      const BorderRadius
                                                          .vertical(
                                                          top: Radius.circular(
                                                              20)),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.grey
                                                          .withOpacity(0.3),
                                                      spreadRadius: 1,
                                                      blurRadius: 5,
                                                    ),
                                                  ],
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Center(
                                                      child: Container(
                                                        width: 40,
                                                        height: 4,
                                                        margin: const EdgeInsets
                                                            .only(bottom: 16),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Colors.grey[300],
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(2),
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      restaurant.name,
                                                      style: const TextStyle(
                                                        fontSize: 24,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      children: [
                                                        Icon(Icons.star,
                                                            color: Colors.amber,
                                                            size: 20),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                          restaurant.rating
                                                              .toStringAsFixed(
                                                                  1),
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      children: [
                                                        Icon(Icons.location_on,
                                                            color: Color(
                                                                0xFF8A0C27),
                                                            size: 20),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                          'Uzaklık: ${Geolocator.distanceBetween(
                                                            currentPosition!
                                                                .latitude,
                                                            currentPosition!
                                                                .longitude,
                                                            restaurant.latitude,
                                                            restaurant
                                                                .longitude,
                                                          ).round()} metre',
                                                          style: TextStyle(
                                                            color: Colors
                                                                .grey[600],
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 16),
                                                    const TabBar(
                                                      tabs: [
                                                        Tab(
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Icon(Icons
                                                                  .restaurant_menu),
                                                              SizedBox(
                                                                  width: 8),
                                                              Text('Menü'),
                                                            ],
                                                          ),
                                                        ),
                                                        Tab(
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Icon(Icons
                                                                  .reviews),
                                                              SizedBox(
                                                                  width: 8),
                                                              Text('Yorumlar'),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                      labelColor:
                                                          Color(0xFF8A0C27),
                                                      unselectedLabelColor:
                                                          Colors.grey,
                                                      indicatorColor:
                                                          Color(0xFF8A0C27),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Expanded(
                                                child: TabBarView(
                                                  children: [
                                                    // Menü Tab
                                                    ListView.builder(
                                                      controller:
                                                          scrollController,
                                                      padding:
                                                          const EdgeInsets.all(
                                                              16),
                                                      itemCount: menus.length,
                                                      itemBuilder:
                                                          (context, index) {
                                                        final menu =
                                                            menus[index];
                                                        return Card(
                                                          elevation: 2,
                                                          margin:
                                                              const EdgeInsets
                                                                  .only(
                                                                  bottom: 12),
                                                          child: ListTile(
                                                            contentPadding:
                                                                const EdgeInsets
                                                                    .all(16),
                                                            title: Text(
                                                              menu['name'],
                                                              style:
                                                                  const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
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
                                                                    color: Colors
                                                                        .green,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        16,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            trailing:
                                                                menu['image_url'] !=
                                                                        null
                                                                    ? ClipRRect(
                                                                        borderRadius:
                                                                            BorderRadius.circular(8),
                                                                        child: Image
                                                                            .network(
                                                                          menu[
                                                                              'image_url'],
                                                                          width:
                                                                              60,
                                                                          height:
                                                                              60,
                                                                          fit: BoxFit
                                                                              .cover,
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
                                      content: Text(
                                          'Menüler yüklenirken bir hata oluştu'),
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
                                            color:
                                                Colors.black.withOpacity(0.3),
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
            ),
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

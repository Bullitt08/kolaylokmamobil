import 'package:flutter/material.dart';
import '../models/restaurant_model.dart';
import '../services/database_service.dart';
import '../customs/customicon.dart';
import 'restaurant_reviews_page.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/review_model.dart';
import '../widgets/restaurant_photo_gallery.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _databaseService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<RestaurantModel> _allRestaurants = [];
  Map<String, List<Map<String, dynamic>>> _menuItems = {};
  List<RestaurantModel> _filteredRestaurants = [];
  final Map<String, PageController> _photoPageControllers = {};
  final Map<String, int> _currentPhotoIndices = {};

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAllRestaurants();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _photoPageControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadAllRestaurants() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final restaurants = await _databaseService.getAllRestaurants();
      if (!mounted) return;
      setState(() {
        _allRestaurants = restaurants;
        _filteredRestaurants = restaurants;
        _isLoading = false;
      });
      for (final restaurant in restaurants) {
        final menus = await _databaseService.getRestaurantMenus(restaurant.id);
        if (!mounted) return;
        setState(() {
          _menuItems[restaurant.id] = menus;
        });
      }
    } catch (e) {
      debugPrint('Restoranlar yüklenirken hata oluştu: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _performSearch(String query) {
    final lowerQuery = query.toLowerCase();
    final directMatches = _allRestaurants.where((restaurant) {
      return restaurant.name.toLowerCase().contains(lowerQuery);
    }).toList();

    final menuMatches = <RestaurantModel>[];
    for (final restaurant in _allRestaurants) {
      final menus = _menuItems[restaurant.id] ?? [];
      final hasMatch = menus.any(
          (menu) => menu['name'].toString().toLowerCase().contains(lowerQuery));
      if (hasMatch) {
        menuMatches.add(restaurant);
      }
    }

    setState(() {
      _filteredRestaurants = {...directMatches, ...menuMatches}.toList();
    });
  }

  void _showEnlargedPhoto(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(8),
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildRestaurantBottomSheet(BuildContext context,
      RestaurantModel restaurant, ScrollController scrollController) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          StatefulBuilder(
            builder: (context, setState) {
              return FutureBuilder<List<String>>(
                future: Future.wait([
                  _databaseService.getRestaurantPhotos(restaurant.id),
                  _databaseService.getRestaurantReviews(restaurant.id)
                ]).then((List<dynamic> results) {
                  final List<String> restaurantPhotos =
                      List<String>.from(results[0]);
                  final List<ReviewModel> reviews =
                      List<ReviewModel>.from(results[1]);
                  final List<String> reviewPhotos = reviews
                      .expand((review) => List<String>.from(review.photos))
                      .toList();
                  return [...restaurantPhotos, ...reviewPhotos];
                }),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final allPhotos = snapshot.data!;
                    final sliderPhotos = allPhotos.take(10).toList();

                    if (sliderPhotos.isEmpty) {
                      return Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Icon(Icons.restaurant,
                            size: 50, color: Colors.grey),
                      );
                    }

                    if (!_photoPageControllers.containsKey(restaurant.id)) {
                      _photoPageControllers[restaurant.id] = PageController();
                      _currentPhotoIndices[restaurant.id] = 0;
                    }

                    return RestaurantPhotoGallery(
                      sliderPhotos: sliderPhotos,
                      allPhotos: allPhotos,
                      controller: _photoPageControllers[restaurant.id]!,
                      currentIndex: _currentPhotoIndices[restaurant.id]!,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPhotoIndices[restaurant.id] = index;
                        });
                      },
                    );
                  }
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Icon(Icons.restaurant,
                        size: 50, color: Colors.grey),
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
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    const Icon(Icons.star, color: Colors.amber, size: 20),
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
                      debugPrint('Harita açılamadı: $e');
                    }
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text('Rota Oluştur'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8A0C27),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 45),
                  ),
                ),
                const SizedBox(height: 16),
                const TabBar(
                  tabs: [
                    Tab(text: 'Genel Bakış'),
                    Tab(text: 'Menü'),
                    Tab(text: 'Yorumlar'),
                  ],
                  labelColor: Color(0xFF8A0C27),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Color(0xFF8A0C27),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (restaurant.description.isNotEmpty) ...[
                        const Text(
                          'Açıklama',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(restaurant.description),
                      ],
                      const SizedBox(height: 16),
                      const Text(
                        'Adres',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(restaurant.address),
                      const SizedBox(height: 16),
                      const Text(
                        'Telefon',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(restaurant.phone_number),
                      const SizedBox(height: 16),
                      const Text(
                        'Çalışma Saatleri',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var entry in restaurant.workingHours.entries)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '${_getWeekdayName(entry.key)}: ${entry.value['open'] ?? 'Kapalı'} - ${entry.value['close'] ?? 'Kapalı'}',
                                style: const TextStyle(height: 1.5),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Menü Tab
                ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _menuItems[restaurant.id]?.length ?? 0,
                  itemBuilder: (context, index) {
                    final menus = _menuItems[restaurant.id] ?? [];
                    final menu = menus[index];
                    final menuPrice = (menu['price'] ?? 0.0).toDouble();

                    final bool isHighlighted =
                        _searchController.text.isNotEmpty &&
                            (menu['name'].toString().toLowerCase().contains(
                                    _searchController.text.toLowerCase()) ||
                                menu['description']
                                    .toString()
                                    .toLowerCase()
                                    .contains(
                                        _searchController.text.toLowerCase()));

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: isHighlighted ? Colors.yellow[100] : null,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          menu['name'],
                          style: TextStyle(
                            fontWeight: isHighlighted
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(menu['description'] ?? ''),
                            const SizedBox(height: 8),
                            Text(
                              '${menuPrice.toStringAsFixed(2)} ₺',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: menu['image_url'] != null
                            ? GestureDetector(
                                onTap: () => _showEnlargedPhoto(
                                    context, menu['image_url']),
                                child: Hero(
                                  tag: 'menu_image_${menu['image_url']}',
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      menu['image_url'],
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
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
                  restaurant: restaurant,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: "Restoran veya yemek arayın...",
            border: InputBorder.none,
          ),
          style: const TextStyle(fontSize: 18),
          onChanged: _performSearch,
        ),
        backgroundColor: const Color(0xFFEDEFE8),
        iconTheme: const IconThemeData(color: Color(0xFF8A0C27)),
      ),
      body: Container(
        color: const Color(0xFFEDEFE8),
        child: Column(
          children: [
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_filteredRestaurants.isEmpty)
              const Center(
                child: Text(
                  "Aranan ürün veya restoran bulunamadı.",
                  style: TextStyle(fontSize: 18, color: Colors.red),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredRestaurants.length,
                  itemBuilder: (context, index) {
                    final restaurant = _filteredRestaurants[index];
                    return GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) => DraggableScrollableSheet(
                            initialChildSize: 0.6,
                            minChildSize: 0.3,
                            maxChildSize: 0.9,
                            expand: false,
                            builder: (context, scrollController) =>
                                _buildRestaurantBottomSheet(
                                    context, restaurant, scrollController),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.all(8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                restaurant.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                restaurant.description,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      color: Colors.amber, size: 20),
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
                              if (restaurant.imageUrl.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      restaurant.imageUrl,
                                      height: 150,
                                      width: MediaQuery.of(context).size.width -
                                          32,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

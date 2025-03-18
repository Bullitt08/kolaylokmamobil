import 'package:flutter/material.dart';
import '../models/restaurant_model.dart';
import '../services/database_service.dart';
import 'restaurant_menu_page.dart';
import '../customs/customicon.dart';
import 'restaurant_reviews_page.dart';

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

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAllRestaurants();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
      return restaurant.name.toLowerCase().startsWith(lowerQuery);
    }).toList();

    final menuMatches = <RestaurantModel>[];
    for (final restaurant in _allRestaurants) {
      final menus = _menuItems[restaurant.id] ?? [];
      final hasMatch = menus.any((menu) =>
          menu['name'].toString().toLowerCase().startsWith(lowerQuery));
      if (hasMatch) {
        menuMatches.add(restaurant);
      }
    }

    setState(() {
      _filteredRestaurants = directMatches + menuMatches;
    });
  }

  Widget _buildNetworkImage(String? imageUrl,
      {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    if (imageUrl == null) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }

    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Icon(Icons.error_outline, color: Colors.red),
        );
      },
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
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
      body: Column(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_filteredRestaurants.isEmpty)
            const Center(
              child: Text(
                "Aranan ürün bulunamadı.",
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _filteredRestaurants.length,
                itemBuilder: (context, index) {
                  final restaurant = _filteredRestaurants[index];
                  final menus = _menuItems[restaurant.id] ?? [];

                  final filteredMenus = menus.where((menu) {
                    return menu['name']
                        .toString()
                        .toLowerCase()
                        .startsWith(_searchController.text.toLowerCase());
                  }).toList();

                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ExpansionTile(
                      title: Column(
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
                              Icon(Icons.star, color: Colors.amber, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                restaurant.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (restaurant.imageUrl != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: _buildNetworkImage(
                                  restaurant.imageUrl,
                                  height: 150,
                                  width: MediaQuery.of(context).size.width - 32,
                                ),
                              ),
                            ),
                        ],
                      ),
                      children: [
                        DefaultTabController(
                          length: 2,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const TabBar(
                                tabs: [
                                  Tab(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CustomIcon(
                                            iconData: Icons.restaurant_menu),
                                        SizedBox(width: 8),
                                        Text('Menü'),
                                      ],
                                    ),
                                  ),
                                  Tab(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CustomIcon(iconData: Icons.reviews),
                                        SizedBox(width: 8),
                                        Text('Yorumlar'),
                                      ],
                                    ),
                                  ),
                                ],
                                labelColor: Color(0xFF8A0C27),
                                unselectedLabelColor: Colors.grey,
                                indicatorColor: Color(0xFF8A0C27),
                              ),
                              SizedBox(
                                height: 300,
                                child: TabBarView(
                                  children: [
                                    // Menü Tab
                                    filteredMenus.isEmpty
                                        ? const Padding(
                                            padding: EdgeInsets.all(16),
                                            child: Center(
                                              child: Text(
                                                  "Bu restoran için uygun menü bulunamadı."),
                                            ),
                                          )
                                        : ListView(
                                            shrinkWrap: true,
                                            physics:
                                                const ClampingScrollPhysics(),
                                            children: filteredMenus.map((menu) {
                                              final menuPrice =
                                                  (menu['price'] ?? 0.0)
                                                      .toDouble();
                                              return Container(
                                                color: Colors.yellow[100],
                                                child: ListTile(
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                                  title: Text(
                                                    menu['name'],
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  subtitle: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                          menu['description'] ??
                                                              ''),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        '${menuPrice.toStringAsFixed(2)} ₺',
                                                        style: const TextStyle(
                                                          color: Colors.green,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  trailing: menu['image_url'] !=
                                                          null
                                                      ? ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          child:
                                                              _buildNetworkImage(
                                                            menu['image_url'],
                                                            width: 60,
                                                            height: 60,
                                                          ),
                                                        )
                                                      : null,
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                    // Yorumlar Tab
                                    SizedBox(
                                      height: 300,
                                      child: RestaurantReviewsPage(
                                        restaurant: restaurant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

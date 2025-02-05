import 'package:flutter/material.dart';
import '../models/restaurant_model.dart';
import '../services/database_service.dart';

class FilteredResultsPage extends StatefulWidget {
  final List<RestaurantModel> filteredRestaurants;
  final Map<String, dynamic> filters;

  const FilteredResultsPage({
    Key? key,
    required this.filteredRestaurants,
    required this.filters,
  }) : super(key: key);

  @override
  State<FilteredResultsPage> createState() => _FilteredResultsPageState();
}

class _FilteredResultsPageState extends State<FilteredResultsPage> {
  final _databaseService = DatabaseService();
  Map<String, List<Map<String, dynamic>>> _menuItems = {};

  @override
  void initState() {
    super.initState();
    _loadMenuItems();
  }

  Future<void> _loadMenuItems() async {
    for (var restaurant in widget.filteredRestaurants) {
      try {
        final menus = await _databaseService.getRestaurantMenus(restaurant.id);
        if (mounted) {
          setState(() {
            _menuItems[restaurant.id] = menus;
          });
        }
      } catch (e) {
        debugPrint('Menü yüklenirken hata: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Filtrelenmiş Sonuçlar',
          style: TextStyle(
          color: Color(0xFF8A0C27),
          fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFFEDEFE8),
      ),
      body: Container(
        color: Color(0xFFEDEFE8),
         child:  widget.filteredRestaurants.isEmpty
          ? const Center(
              child: Text('Filtrelere uygun restoran bulunamadı.'),
            )
          : ListView.builder(
              itemCount: widget.filteredRestaurants.length,
              itemBuilder: (context, index) {
                final restaurant = widget.filteredRestaurants[index];
                final menus = _menuItems[restaurant.id] ?? [];

                // Fiyat aralığına uyan menü öğelerini say
                final priceRange = widget.filters['priceRange'] as RangeValues;
                final filteredMenuCount = menus.where((menu) {
                  final menuPrice = (menu['price'] ?? 0.0).toDouble();
                  return menuPrice >= priceRange.start &&
                      menuPrice <= priceRange.end;
                }).length;

                // Eğer hiç uygun menü öğesi yoksa bu restoranı gösterme
                if (filteredMenuCount == 0) {
                  return const SizedBox.shrink();
                }

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ExpansionTile(
                    title: Text(
                      restaurant.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(restaurant.description),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            Text(' ${restaurant.rating.toStringAsFixed(1)}'),
                          ],
                        ),
                      ],
                    ),
                    children: [
                      if (menus.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: menus.length,
                          itemBuilder: (context, menuIndex) {
                            final menu = menus[menuIndex];
                            final menuPrice = (menu['price'] ?? 0.0).toDouble();
                            final priceRange =
                                widget.filters['priceRange'] as RangeValues;

                            // Fiyat aralığı kontrolü
                            if (menuPrice < priceRange.start ||
                                menuPrice > priceRange.end) {
                              return const SizedBox.shrink();
                            }

                            final bool isHighlighted =
                                widget.filters['menuSearch'] != null &&
                                    (menu['name']
                                            .toString()
                                            .toLowerCase()
                                            .contains(widget
                                                .filters['menuSearch']
                                                .toLowerCase()) ||
                                        menu['description']
                                            .toString()
                                            .toLowerCase()
                                            .contains(widget
                                                .filters['menuSearch']
                                                .toLowerCase()));

                            return Container(
                              color: isHighlighted ? Colors.yellow[100] : null,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
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
                                    const SizedBox(height: 4),
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
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          menu['image_url'],
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
      ),
    );
  }
}

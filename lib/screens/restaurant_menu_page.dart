import 'package:flutter/material.dart';
import '../models/restaurant_model.dart';
import '../services/database_service.dart';

class RestaurantMenuPage extends StatefulWidget {
  final RestaurantModel restaurant;

  const RestaurantMenuPage({Key? key, required this.restaurant})
      : super(key: key);

  @override
  State<RestaurantMenuPage> createState() => _RestaurantMenuPageState();
}

class _RestaurantMenuPageState extends State<RestaurantMenuPage> {
  final _databaseService = DatabaseService();
  List<Map<String, dynamic>> _menuItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMenuItems();
  }

  Future<void> _loadMenuItems() async {
    try {
      final menus =
          await _databaseService.getRestaurantMenus(widget.restaurant.id);
      setState(() {
        _menuItems = menus;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading menu items: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.restaurant.name,
          style: const TextStyle(
            color: Color(0xFF8A0C27),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFEDEFE8),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _menuItems.isEmpty
              ? const Center(child: Text('Bu restoran için menü bulunamadı.'))
              : ListView.builder(
                  itemCount: _menuItems.length,
                  itemBuilder: (context, index) {
                    final menu = _menuItems[index];
                    final menuPrice = (menu['price'] ?? 0.0).toDouble();
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Text(
                          menu['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
    );
  }
}

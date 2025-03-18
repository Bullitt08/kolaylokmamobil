import 'package:flutter/material.dart';
import '../models/restaurant_model.dart';
import '../services/database_service.dart';
import '../customs/customicon.dart';
import 'restaurant_reviews_page.dart';

class RestaurantMenuPage extends StatefulWidget {
  final RestaurantModel restaurant;

  const RestaurantMenuPage({Key? key, required this.restaurant})
      : super(key: key);

  @override
  State<RestaurantMenuPage> createState() => _RestaurantMenuPageState();
}

class _RestaurantMenuPageState extends State<RestaurantMenuPage>
    with SingleTickerProviderStateMixin {
  final _databaseService = DatabaseService();
  List<Map<String, dynamic>> _menuItems = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMenuItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMenuItems() async {
    try {
      final menus =
          await _databaseService.getRestaurantMenus(widget.restaurant.id);
      if (mounted) {
        setState(() {
          _menuItems = menus;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading menu items: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildMenuTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_menuItems.isEmpty) {
      return const Center(child: Text('Bu restoran için menü bulunamadı.'));
    }

    return ListView.builder(
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
    );
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
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const CustomIcon(iconData: Icons.menu_book),
              text: 'Menü',
            ),
            Tab(
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CustomIcon(iconData: Icons.star),
                  const SizedBox(width: 4),
                  Text(widget.restaurant.rating.toStringAsFixed(1)),
                ],
              ),
              text: 'Yorumlar',
            ),
          ],
          labelColor: const Color(0xFF8A0C27),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF8A0C27),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMenuTab(),
          RestaurantReviewsPage(restaurant: widget.restaurant),
        ],
      ),
    );
  }
}

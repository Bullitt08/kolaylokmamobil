import 'package:flutter/material.dart';
import '../models/menu_item_model.dart';
import '../models/restaurant_model.dart';
import '../services/database_service.dart';

class MenuManagementScreen extends StatefulWidget {
  final RestaurantModel restaurant;

  const MenuManagementScreen({Key? key, required this.restaurant})
      : super(key: key);

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _databaseService = DatabaseService();
  List<MenuItemModel> _menuItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMenuItems();
  }

  Future<void> _loadMenuItems() async {
    try {
      final items = await _databaseService.getMenuItems(widget.restaurant.id);
      setState(() {
        _menuItems = items;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${e.toString()}')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  List<MenuItemModel> _getItemsByCategory(MenuCategory category) {
    return _menuItems.where((item) => item.category == category).toList();
  }

  Future<void> _showAddEditItemDialog([MenuItemModel? item]) async {
    final nameController = TextEditingController(text: item?.name ?? '');
    final descriptionController =
        TextEditingController(text: item?.description ?? '');
    final priceController =
        TextEditingController(text: item?.price.toString() ?? '');
    MenuCategory selectedCategory = item?.category ?? MenuCategory.food;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? 'Yeni Ürün Ekle' : 'Ürünü Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Ürün Adı'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Açıklama'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Fiyat'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButton<MenuCategory>(
                value: selectedCategory,
                items: MenuCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(
                        category == MenuCategory.food ? 'Yiyecek' : 'İçecek'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedCategory = value;
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final price = double.parse(priceController.text);
                final menuItem = MenuItemModel(
                  id: item?.id,
                  restaurantId: widget.restaurant.id,
                  name: nameController.text,
                  description: descriptionController.text,
                  price: price,
                  category: selectedCategory,
                );

                if (item == null) {
                  await _databaseService.createMenuItem(menuItem);
                } else {
                  await _databaseService.updateMenuItem(item.id, menuItem);
                }

                if (mounted) {
                  Navigator.pop(context);
                  _loadMenuItems();
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Hata: ${e.toString()}')),
                );
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(MenuItemModel item) async {
    print('Silme işlemi başlatılıyor: ${item.id}');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ürünü Sil'),
        content: const Text('Bu ürünü silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    print('Kullanıcı onayı: $confirmed');
    if (confirmed == true) {
      try {
        print('Silme işlemi başlıyor...');
        await _databaseService.deleteMenuItem(item.id);
        print('Silme işlemi başarılı, liste yenileniyor...');

        if (mounted) {
          setState(() {
            _menuItems.removeWhere((menuItem) => menuItem.id == item.id);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ürün başarıyla silindi')),
          );
        }
      } catch (e, stackTrace) {
        print('Silme işleminde hata: $e');
        print('Hata detayı: $stackTrace');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: ${e.toString()}')),
          );
          // Hata durumunda listeyi yeniden yükle
          _loadMenuItems();
        }
      }
    }
  }

  Widget _buildMenuList(List<MenuItemModel> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text('Henüz ürün eklenmemiş'),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          title: Text(item.name),
          subtitle: Text(
              '${item.description}\nFiyat: ₺${item.price.toStringAsFixed(2)}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showAddEditItemDialog(item),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteItem(item),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.restaurant.name} - Menü Yönetimi'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Yiyecekler'),
            Tab(text: 'İçecekler'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMenuList(_getItemsByCategory(MenuCategory.food)),
                _buildMenuList(_getItemsByCategory(MenuCategory.drink)),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditItemDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

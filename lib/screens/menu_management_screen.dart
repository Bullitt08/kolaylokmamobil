import 'package:flutter/material.dart';
import 'package:kolaylokma/customs/custombutton.dart';
import 'package:kolaylokma/customs/customicon.dart';
import '../models/menu_item_model.dart';
import '../models/restaurant_model.dart';
import '../services/database_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

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

  Future<String?> _pickAndUploadPhoto(String menuItemId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image == null) return null;

    try {
      final fileName =
          'menu_${widget.restaurant.id}_${menuItemId}_${DateTime.now().millisecondsSinceEpoch}.${image.path.split('.').last}';
      final imageUrl = await _databaseService.uploadMenuItemPhoto(
        widget.restaurant.id,
        image.path,
        fileName,
      );

      return imageUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fotoğraf yüklenirken hata oluştu: $e')),
        );
      }
      return null;
    }
  }

  Future<void> _showAddEditItemDialog([MenuItemModel? item]) async {
    final nameController = TextEditingController(text: item?.name ?? '');
    final descriptionController =
        TextEditingController(text: item?.description ?? '');
    final priceController =
        TextEditingController(text: item?.price.toString() ?? '');
    MenuCategory selectedCategory = item?.category ?? MenuCategory.food;
    String? currentImageUrl = item?.imageUrl;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFF8A0C27), width: 2.0),
            borderRadius: BorderRadius.circular(8.0),
          ),
          backgroundColor: Color(0xFFEDEFE8),
          title: Text(
            item == null ? 'Yeni Ürün Ekle' : 'Ürünü Düzenle',
            style: TextStyle(
              color: Color(0xFF8A0C27),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ürün Fotoğrafı',
                        style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (currentImageUrl != null)
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  currentImageUrl ?? '',
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.error_outline,
                                          color: Colors.red),
                                    );
                                  },
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.red, size: 20),
                                    onPressed: () {
                                      setDialogState(
                                          () => currentImageUrl = null);
                                    },
                                    constraints: const BoxConstraints(
                                      minWidth: 24,
                                      minHeight: 24,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          InkWell(
                            onTap: () async {
                              final tempId = item?.id ?? const Uuid().v4();
                              final imageUrl =
                                  await _pickAndUploadPhoto(tempId);
                              if (imageUrl != null) {
                                setDialogState(
                                    () => currentImageUrl = imageUrl);
                              }
                            },
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: const Color(0xFF8A0C27)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate,
                                      color: Color(0xFF8A0C27)),
                                  SizedBox(height: 4),
                                  Text('Fotoğraf',
                                      style: TextStyle(
                                        color: Color(0xFF8A0C27),
                                        fontSize: 12,
                                      )),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                      setDialogState(() => selectedCategory = value);
                    }
                  },
                  dropdownColor: const Color(0xFFEDEFE8),
                ),
              ],
            ),
          ),
          actions: [
            CustomButton(
              text: 'İptal',
              backgroundColor: Colors.transparent,
              textColor: const Color(0xFF8A0C27),
              onPressed: () => Navigator.pop(context),
            ),
            CustomButton(
              text: 'Kaydet',
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
                    imageUrl: currentImageUrl,
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
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteItem(MenuItemModel item) async {
    print('Silme işlemi başlatılıyor: ${item.id}');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFF8A0C27), width: 2.0),
          borderRadius: BorderRadius.circular(8.0),
        ),
        backgroundColor: Color(0xFFEDEFE8),
        title: const Text(
          'Ürünü Sil',
          style: TextStyle(
            color: Color(0xFF8A0C27),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Bu ürünü silmek istediğinizden emin misiniz?',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        actions: [
          CustomButton(
            text: 'İptal',
            backgroundColor: Colors.transparent,
            textColor: const Color(0xFF8A0C27),
            onPressed: () => Navigator.pop(context, false),
          ),
          CustomButton(
            text: 'Sil',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Delete the photo first if it exists
        if (item.imageUrl != null) {
          await _databaseService.deleteMenuItemPhoto(
              widget.restaurant.id, item.imageUrl!);
        }
        // Then delete the menu item
        await _databaseService.deleteMenuItem(item.id);

        if (mounted) {
          setState(() {
            _menuItems.removeWhere((menuItem) => menuItem.id == item.id);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ürün başarıyla silindi')),
          );
        }
      } catch (e) {
        print('Silme işleminde hata: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: ${e.toString()}')),
          );
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
        return Column(
          children: [
            ListTile(
              leading: item.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.imageUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[200],
                            child: const Icon(Icons.error_outline,
                                color: Colors.red),
                          );
                        },
                      ),
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.image_not_supported,
                          color: Colors.grey),
                    ),
              title: Text(item.name),
              subtitle: Text(
                  '${item.description}\nFiyat: ₺${item.price.toStringAsFixed(2)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const CustomIcon(iconData: Icons.edit),
                    onPressed: () => _showAddEditItemDialog(item),
                  ),
                  IconButton(
                    icon: const CustomIcon(iconData: Icons.delete),
                    onPressed: () => _deleteItem(item),
                  ),
                ],
              ),
            ),
            const Divider(),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.restaurant.name} - Menü Yönetimi',
          style: TextStyle(
            color: Color(0xFF8A0C27),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFFEDEFE8),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Yiyecekler'),
            Tab(text: 'İçecekler'),
          ],
          labelColor: Color(0xFF8A0C27),
          indicatorColor: Color(0xFF8A0C27),
          unselectedLabelColor: Colors.black,
        ),
      ),
      body: _isLoading
          ? Stack(
              children: [
                Container(
                  color: const Color(0xFFEDEFE8),
                ),
                const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF8A0C27)),
                  ),
                ),
              ],
            )
          : Container(
              color: const Color(0xFFEDEFE8),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMenuList(_getItemsByCategory(MenuCategory.food)),
                  _buildMenuList(_getItemsByCategory(MenuCategory.drink)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF8A0C27),
        onPressed: () => _showAddEditItemDialog(),
        child: const CustomIcon(
          iconData: Icons.add,
          iconColor: Color(0xFFEDEFE8),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import '../models/restaurant_model.dart';
import '../services/database_service.dart';
import '../customs/customicon.dart';
import 'restaurant_reviews_page.dart';
import 'package:flutter/foundation.dart';

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
  List<String> _allPhotos = [];
  bool _isLoading = true;
  int _currentPhotoIndex = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final menus =
          await _databaseService.getRestaurantMenus(widget.restaurant.id);
      final reviews =
          await _databaseService.getRestaurantReviews(widget.restaurant.id);

      // Combine all photos
      List<String> photos = [];
      if (widget.restaurant.imageUrl.isNotEmpty) {
        photos.add(widget.restaurant.imageUrl);
      }
      for (var review in reviews) {
        photos.addAll(review.photos);
      }

      if (mounted) {
        setState(() {
          _menuItems = menus;
          _allPhotos = photos;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildPhotoGallery() {
    if (_allPhotos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Stack(
            children: [
              PageView.builder(
                itemCount: _allPhotos.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPhotoIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullScreenPhotoView(
                            imageUrl: _allPhotos[index],
                            heroTag: 'photo_gallery_${_allPhotos[index]}',
                          ),
                        ),
                      );
                    },
                    child: Hero(
                      tag: 'photo_gallery_${_allPhotos[index]}',
                      child: ImageWithError(
                        imageUrl: _allPhotos[index],
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
              if (_allPhotos.length > 1) ...[
                Positioned.fill(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios,
                            color: Colors.white),
                        onPressed: () {
                          if (_currentPhotoIndex > 0) {
                            setState(() {
                              _currentPhotoIndex--;
                            });
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios,
                            color: Colors.white),
                        onPressed: () {
                          if (_currentPhotoIndex < _allPhotos.length - 1) {
                            setState(() {
                              _currentPhotoIndex++;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _allPhotos.length,
                      (index) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPhotoIndex == index
                              ? const Color(0xFF8A0C27)
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tüm Fotoğraflar',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _allPhotos.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FullScreenPhotoView(
                                    imageUrl: _allPhotos[index],
                                    heroTag: 'photo_grid_${_allPhotos[index]}',
                                  ),
                                ),
                              );
                            },
                            child: Hero(
                              tag: 'photo_grid_${_allPhotos[index]}',
                              child: ImageWithError(
                                imageUrl: _allPhotos[index],
                                width: 100,
                                height: 100,
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
          },
          child: Text(
            'Tüm Fotoğrafları Gör (${_allPhotos.length})',
            style: const TextStyle(color: Color(0xFF8A0C27)),
          ),
        ),
      ],
    );
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
            onTap: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (menu['image_url'] != null) ...[
                        Center(
                          child: ImageWithError(
                            imageUrl: menu['image_url'],
                            width: MediaQuery.of(context).size.width * 0.8,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        menu['name'],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        menu['description'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${menuPrice.toStringAsFixed(2)} ₺',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                widget.restaurant.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              TabBar(
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
                        Text(
                            '${widget.restaurant.rating.toStringAsFixed(1)} (${widget.restaurant.ratingCount})'),
                      ],
                    ),
                    text: 'Yorumlar',
                  ),
                ],
                labelColor: const Color(0xFF8A0C27),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF8A0C27),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              _buildPhotoGallery(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMenuTab(),
                    RestaurantReviewsPage(restaurant: widget.restaurant),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class FullScreenPhotoView extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const FullScreenPhotoView({
    Key? key,
    required this.imageUrl,
    required this.heroTag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5),
      body: Stack(
        children: [
          Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Hero(
                tag: heroTag,
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: ImageWithError(
                    imageUrl: imageUrl,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

class ImageWithError extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final BoxFit fit;

  const ImageWithError({
    Key? key,
    required this.imageUrl,
    this.width = 90,
    this.height = 90,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  String _sanitizeImageUrl(String url) {
    if (url.startsWith('http://')) {
      return url.replaceFirst('http://', 'https://');
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final sanitizedUrl = _sanitizeImageUrl(imageUrl);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.hardEdge,
      child: Image.network(
        sanitizedUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Image error: $error');
          return Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: const Icon(Icons.error_outline, color: Colors.red),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: const Color(0xFF8A0C27),
              ),
            ),
          );
        },
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: frame != null
                ? child
                : Container(
                    width: width,
                    height: height,
                    color: Colors.grey[200],
                  ),
          );
        },
        cacheWidth: (width * MediaQuery.of(context).devicePixelRatio).toInt(),
        cacheHeight: (height * MediaQuery.of(context).devicePixelRatio).toInt(),
      ),
    );
  }
}

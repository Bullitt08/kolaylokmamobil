import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/review_model.dart';
import '../models/restaurant_model.dart';
import '../customs/custombutton.dart';

class UserReviewsPage extends StatefulWidget {
  final String userId;

  const UserReviewsPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<UserReviewsPage> createState() => _UserReviewsPageState();
}

class _UserReviewsPageState extends State<UserReviewsPage> {
  final _databaseService = DatabaseService();
  bool _isLoading = true;
  List<ReviewModel> _reviews = [];
  Map<String, RestaurantModel> _restaurants = {};

  String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years yıl önce';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ay önce';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final reviews = await _databaseService.getUserReviews(widget.userId);
      if (!mounted) return;

      // Load restaurant details for each review
      final restaurantsMap = <String, RestaurantModel>{};
      for (var review in reviews) {
        if (!restaurantsMap.containsKey(review.restaurantId)) {
          final restaurant =
              await _databaseService.getRestaurant(review.restaurantId);
          if (restaurant != null) {
            restaurantsMap[review.restaurantId] = restaurant;
          }
        }
      }

      setState(() {
        _reviews = reviews;
        _restaurants = restaurantsMap;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yorumlar yüklenirken hata oluştu: $e')),
      );
    }
  }

  Future<void> _deleteReview(ReviewModel review) async {
    try {
      await _databaseService.deleteReview(review.id);
      setState(() {
        _reviews.remove(review);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yorum başarıyla silindi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yorum silinirken hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _editReview(ReviewModel review) async {
    final textController = TextEditingController(text: review.comment);
    final formKey = GlobalKey<FormState>();
    int rating = review.rating;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yorumu Düzenle'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: textController,
                decoration: const InputDecoration(
                  labelText: 'Yorum',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir yorum yazın';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Color(0xFF8A0C27),
                    ),
                    onPressed: () {
                      rating = index + 1;
                      (context as Element).markNeedsBuild();
                    },
                  );
                }),
              ),
            ],
          ),
        ),
        actions: [
          CustomButton(
            text: 'İptal',
            onPressed: () => Navigator.pop(context, false),
            backgroundColor: Colors.transparent,
            textColor: Color(0xFF8A0C27),
          ),
          CustomButton(
            text: 'Kaydet',
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final updatedReview = ReviewModel(
          id: review.id,
          userId: review.userId,
          restaurantId: review.restaurantId,
          rating: rating,
          comment: textController.text,
          photos: review.photos,
          createdAt: review.createdAt,
          updatedAt: DateTime.now(),
        );

        await _databaseService.updateReview(review.id, updatedReview);

        setState(() {
          final index = _reviews.indexWhere((r) => r.id == review.id);
          if (index != -1) {
            _reviews[index] = updatedReview;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Yorum başarıyla güncellendi')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Yorum güncellenirken hata oluştu: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Değerlendirmelerim',
          style: TextStyle(
            color: Color(0xFF8A0C27),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFFEDEFE8),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reviews.isEmpty
              ? const Center(
                  child: Text('Henüz bir değerlendirme yapmamışsınız.'),
                )
              : ListView.builder(
                  itemCount: _reviews.length,
                  itemBuilder: (context, index) {
                    final review = _reviews[index];
                    final restaurant = _restaurants[review.restaurantId];

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  restaurant?.name ?? 'Bilinmeyen Restoran',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _editReview(review),
                                      color: Color(0xFF8A0C27),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _deleteReview(review),
                                      color: Colors.red,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < review.rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 20,
                                );
                              }),
                            ),
                            const SizedBox(height: 8),
                            Text(review.comment),
                            if (review.photos.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 100,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: review.photos.length,
                                  itemBuilder: (context, imageIndex) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          review.photos[imageIndex],
                                          height: 100,
                                          width: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              getRelativeTime(review.createdAt),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

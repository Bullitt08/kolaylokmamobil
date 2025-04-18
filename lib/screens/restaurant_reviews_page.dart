import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/review_model.dart';
import '../models/review_report_model.dart';
import '../models/restaurant_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../customs/custombutton.dart';
import 'package:flutter/foundation.dart';

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
      backgroundColor:
          Colors.black.withOpacity(0.5), // Arka plan rengini saydamlaştırdık
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

class RestaurantReviewsPage extends StatefulWidget {
  final RestaurantModel restaurant;

  const RestaurantReviewsPage({Key? key, required this.restaurant})
      : super(key: key);

  @override
  State<RestaurantReviewsPage> createState() => _RestaurantReviewsPageState();
}

class _RestaurantReviewsPageState extends State<RestaurantReviewsPage> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  List<ReviewModel> _reviews = [];
  UserModel? _currentUser;
  bool _isLoading = true;

  // Review form controllers
  final _commentController = TextEditingController();
  String _sortBy = 'latest'; // 'latest', 'rating_high', 'rating_low'
  double _currentRating = 5.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final reviews =
          await _databaseService.getRestaurantReviews(widget.restaurant.id);
      final user = await _authService.getCurrentUser();
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _currentUser = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yorumlar yüklenirken hata oluştu: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  List<ReviewModel> _getSortedReviews() {
    switch (_sortBy) {
      case 'rating_high':
        return List.from(_reviews)
          ..sort((a, b) => b.rating.compareTo(a.rating));
      case 'rating_low':
        return List.from(_reviews)
          ..sort((a, b) => a.rating.compareTo(b.rating));
      case 'latest':
      default:
        return List.from(_reviews)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  Widget _buildSortingOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          const Text('Sıralama:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _sortBy,
            items: [
              DropdownMenuItem(
                value: 'latest',
                child: Row(
                  children: const [
                    Icon(Icons.access_time, color: Color(0xFF8A0C27), size: 16),
                    SizedBox(width: 4),
                    Text('En Yeni'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'rating_high',
                child: Row(
                  children: const [
                    Icon(Icons.star, color: Color(0xFF8A0C27), size: 16),
                    SizedBox(width: 4),
                    Text('En Yüksek Puan'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'rating_low',
                child: Row(
                  children: const [
                    Icon(Icons.star_border, color: Color(0xFF8A0C27), size: 16),
                    SizedBox(width: 4),
                    Text('En Düşük Puan'),
                  ],
                ),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _sortBy = value);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showReviewDialog({ReviewModel? existingReview}) async {
    if (!mounted) return;

    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yorum yapmak için giriş yapmalısınız')),
      );
      return;
    }

    List<String> dialogPhotos = [];
    final imagePicker = ImagePicker();

    Future<void> addPhoto(StateSetter setDialogState) async {
      try {
        final XFile? image = await imagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );

        if (image != null && mounted) {
          final String fileName =
              '${const Uuid().v4()}.${image.path.split('.').last}';
          final imageUrl = await _databaseService.uploadReviewImage(
            widget.restaurant.id,
            _currentUser!.id,
            image.path,
            fileName,
          );

          if (mounted) {
            setDialogState(() {
              dialogPhotos.add(imageUrl);
            });
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fotoğraf yüklenirken hata oluştu: $e')),
          );
        }
      }
    }

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existingReview == null ? 'Yorum Yap' : 'Yorumu Düzenle'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Rating Stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < _currentRating
                              ? Icons.star
                              : Icons.star_border,
                          color: Color(0xFF8A0C27),
                          size: 32,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            _currentRating = index + 1.0;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  // Comment TextField
                  TextFormField(
                    controller: _commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Deneyiminizi paylaşın...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Lütfen bir yorum yazın';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Photos Section
                  if (dialogPhotos.isNotEmpty) ...[
                    SizedBox(
                      height: 100,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: dialogPhotos.map((photo) {
                            return Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: ImageWithError(
                                    imageUrl: photo,
                                    width: 90,
                                    height: 90,
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.red),
                                    onPressed: () {
                                      setDialogState(() {
                                        dialogPhotos.remove(photo);
                                      });
                                    },
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Add Photo Button
                  if (dialogPhotos.length < 3)
                    TextButton.icon(
                      onPressed: () => addPhoto(setDialogState),
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Fotoğraf Ekle'),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  try {
                    final review = ReviewModel(
                      id: existingReview?.id ?? const Uuid().v4(),
                      userId: _currentUser!.id,
                      restaurantId: widget.restaurant.id,
                      rating: _currentRating.round(),
                      comment: _commentController.text.trim(),
                      photos: dialogPhotos,
                    );

                    if (existingReview != null) {
                      await _databaseService.updateReview(
                          existingReview.id, review);
                    } else {
                      await _databaseService.createReview(review);
                    }

                    if (mounted) {
                      Navigator.pop(context);
                      _loadData(); // Refresh reviews
                      _commentController.clear();
                      setState(() => _currentRating = 5.0);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Yorum kaydedilirken hata oluştu: $e')),
                      );
                    }
                  }
                }
              },
              child: Text(existingReview == null ? 'Gönder' : 'Güncelle'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReportDialog(ReviewModel review) async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şikayet etmek için giriş yapmalısınız')),
      );
      return;
    }

    final reasonController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFF8A0C27), width: 2.0),
          borderRadius: BorderRadius.circular(8.0),
        ),
        backgroundColor: const Color(0xFFEDEFE8),
        title: const Text(
          'Yorumu Şikayet Et',
          style: TextStyle(
            color: Color(0xFF8A0C27),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Şikayet nedeninizi seçin:'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: [
                'Uygunsuz içerik',
                'Spam',
                'Yanlış bilgi',
                'Taciz/Hakaret',
                'Diğer',
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                reasonController.text = value ?? '';
              },
              hint: const Text('Şikayet nedeni seçin'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ek açıklama ekleyin (isteğe bağlı)...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          CustomButton(
            text: 'İptal',
            backgroundColor: Colors.transparent,
            textColor: const Color(0xFF8A0C27),
            onPressed: () => Navigator.pop(context, false),
          ),
          CustomButton(
            text: 'Şikayet Et',
            onPressed: () async {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lütfen şikayet nedeninizi seçin'),
                  ),
                );
                return;
              }

              try {
                final report = ReviewReportModel(
                  id: const Uuid().v4(),
                  reviewId: review.id,
                  reporterId: _currentUser!.id,
                  reason: reasonController.text,
                  status: ReportStatus.pending,
                  createdAt: DateTime.now(),
                );

                await _databaseService.createReviewReport(report);

                if (mounted) {
                  Navigator.pop(context, true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Şikayetiniz başarıyla iletildi. İncelemeye alınacaktır.'),
                      backgroundColor: Color(0xFF8A0C27),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Şikayet gönderilirken hata oluştu: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şikayetiniz başarıyla gönderildi')),
      );
    }
  }

  Future<void> _deleteReview(ReviewModel review) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFF8A0C27), width: 2.0),
          borderRadius: BorderRadius.circular(8.0),
        ),
        backgroundColor: const Color(0xFFEDEFE8),
        title: const Text(
          'Yorumu Sil',
          style: TextStyle(
            color: Color(0xFF8A0C27),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text('Bu yorumu silmek istediğinizden emin misiniz?'),
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

    if (result == true) {
      try {
        await _databaseService.deleteReview(review.id);
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Yorum silinirken hata oluştu')),
          );
        }
      }
    }
  }

  Widget _buildReviewPhotos(List<String> photos) {
    return SizedBox(
      height: 100,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: photos.map((photo) {
            final heroTag = 'photo_$photo';
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenPhotoView(
                        imageUrl: photo,
                        heroTag: heroTag,
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: heroTag,
                  child: ImageWithError(
                    imageUrl: photo,
                    width: 90,
                    height: 90,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getRelativeTime(DateTime dateTime) {
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

  String _formatUserName(UserModel? user) {
    if (user == null) return 'Anonim';
    if (user.name.isEmpty) return 'Anonim';

    // Adı tam, soyadının ilk harfini göster
    return '${user.name} ${user.surname[0]}.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.restaurant.name} - Yorumlar',
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
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber),
                              Text(
                                ' ${widget.restaurant.rating.toStringAsFixed(1)} (${widget.restaurant.ratingCount})',
                                style: const TextStyle(fontSize: 18),
                              ),
                            ],
                          ),
                        ],
                      ),
                      CustomButton(
                        text: 'Yorum Yap',
                        onPressed: () => _showReviewDialog(),
                      ),
                    ],
                  ),
                ),
                _buildSortingOptions(),
                const Divider(),
                Expanded(
                  child: _reviews.isEmpty
                      ? const Center(
                          child: Text('Henüz yorum yapılmamış'),
                        )
                      : ListView.builder(
                          itemCount: _getSortedReviews().length,
                          itemBuilder: (context, index) {
                            final review = _getSortedReviews()[index];
                            return FutureBuilder<UserModel?>(
                              future: _databaseService.getUser(review.userId),
                              builder: (context, snapshot) {
                                final reviewer = snapshot.data;
                                return Card(
                                  margin: const EdgeInsets.all(8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  backgroundColor:
                                                      const Color(0xFF8A0C27),
                                                  radius: 20,
                                                  backgroundImage: reviewer
                                                              ?.profileImageUrl !=
                                                          null
                                                      ? NetworkImage(reviewer
                                                              ?.profileImageUrl ??
                                                          '')
                                                      : null,
                                                  child: reviewer
                                                              ?.profileImageUrl ==
                                                          null
                                                      ? const Icon(Icons.person,
                                                          color: Colors.white)
                                                      : null,
                                                ),
                                                const SizedBox(width: 8),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      _formatUserName(reviewer),
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    Text(
                                                      _getRelativeTime(
                                                          review.createdAt),
                                                      style: const TextStyle(
                                                          color: Colors.grey),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: List.generate(
                                                5,
                                                (index) => Icon(
                                                  index < review.rating
                                                      ? Icons.star
                                                      : Icons.star_border,
                                                  color: Colors.amber,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(review.comment),
                                        if (review.photos.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          _buildReviewPhotos(review.photos),
                                        ],
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            if (_currentUser?.id ==
                                                    review.userId ||
                                                _currentUser?.userType ==
                                                    'admin') ...[
                                              IconButton(
                                                icon: const Icon(Icons.edit),
                                                onPressed: () {
                                                  _commentController.text =
                                                      review.comment;
                                                  _currentRating =
                                                      review.rating.toDouble();
                                                  _showReviewDialog(
                                                      existingReview: review);
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete),
                                                onPressed: () =>
                                                    _deleteReview(review),
                                              ),
                                            ],
                                            if (_currentUser?.id !=
                                                review.userId)
                                              IconButton(
                                                icon: const Icon(Icons.flag),
                                                onPressed: () =>
                                                    _showReportDialog(review),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

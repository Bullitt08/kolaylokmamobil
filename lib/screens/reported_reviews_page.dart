import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/review_report_model.dart';
import '../models/review_model.dart';
import '../models/restaurant_model.dart';
import '../customs/custombutton.dart';

class ReportedReviewsPage extends StatefulWidget {
  const ReportedReviewsPage({Key? key}) : super(key: key);

  @override
  State<ReportedReviewsPage> createState() => _ReportedReviewsPageState();
}

class _ReportedReviewsPageState extends State<ReportedReviewsPage> {
  final _databaseService = DatabaseService();
  bool _isLoading = true;
  List<ReviewReportModel> _reports = [];
  Map<String, ReviewModel> _reviews = {};
  Map<String, RestaurantModel> _restaurants = {};

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final reports = await _databaseService.getPendingReports();
      if (!mounted) return;

      // Load reviews and restaurants for each report
      final reviewsMap = <String, ReviewModel>{};
      final restaurantsMap = <String, RestaurantModel>{};

      for (var report in reports) {
        if (!reviewsMap.containsKey(report.reviewId)) {
          final review = await _databaseService.getReview(report.reviewId);
          if (review != null) {
            reviewsMap[report.reviewId] = review;

            if (!restaurantsMap.containsKey(review.restaurantId)) {
              final restaurant =
                  await _databaseService.getRestaurant(review.restaurantId);
              if (restaurant != null) {
                restaurantsMap[review.restaurantId] = restaurant;
              }
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _reports = reports;
          _reviews = reviewsMap;
          _restaurants = restaurantsMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Raporlar yüklenirken hata oluştu: $e')),
      );
    }
  }

  Future<void> _updateReportStatus(
      ReviewReportModel report, ReportStatus status) async {
    try {
      await _databaseService.updateReportStatus(report.id, status);
      setState(() {
        _reports.remove(report);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rapor durumu güncellendi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Rapor durumu güncellenirken hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _deleteReview(ReviewModel review) async {
    try {
      await _databaseService.deleteReview(review.id);
      setState(() {
        _reports.removeWhere((report) => report.reviewId == review.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yorum silindi')),
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

  String _getTimeDifference(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} yıl önce';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} ay önce';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    }
    return 'Az önce';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Şikayet Edilen Yorumlar',
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
          : _reports.isEmpty
              ? const Center(child: Text('Bekleyen şikayet bulunmuyor'))
              : ListView.builder(
                  itemCount: _reports.length,
                  itemBuilder: (context, index) {
                    final report = _reports[index];
                    final review = _reviews[report.reviewId];
                    final restaurant = review != null
                        ? _restaurants[review.restaurantId]
                        : null;

                    if (review == null) return const SizedBox.shrink();

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              restaurant?.name ?? 'Bilinmeyen Restoran',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
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
                                  itemBuilder: (context, photoIndex) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          review.photos[photoIndex],
                                          height: 100,
                                          width: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              height: 100,
                                              width: 100,
                                              color: Colors.grey[200],
                                              child: const Center(
                                                child: Icon(
                                                  Icons.error_outline,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Şikayet Sebebi:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(report.reason),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getTimeDifference(report.createdAt),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                CustomButton(
                                  text: 'Yorumu Sil',
                                  onPressed: () => _deleteReview(review),
                                  backgroundColor: Colors.red,
                                ),
                                CustomButton(
                                  text: 'Şikayeti Reddet',
                                  onPressed: () => _updateReportStatus(
                                      report, ReportStatus.rejected),
                                  backgroundColor: Colors.transparent,
                                  textColor: Color(0xFF8A0C27),
                                ),
                              ],
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

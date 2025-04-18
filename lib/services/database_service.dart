import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/user_model.dart';
import '../models/restaurant_model.dart';
import '../models/menu_item_model.dart';
import '../models/review_model.dart';
import '../models/review_report_model.dart';

class DatabaseService {
  final _supabase = Supabase.instance.client;

  // Supabase instance'ına erişim için getter
  SupabaseClient get supabase => _supabase;

  // Kullanıcı İşlemleri
  Future<void> createUser(UserModel user) async {
    await _supabase.from('users').insert(user.toMap());
  }

  Future<UserModel?> getUser(String userId) async {
    try {
      final data =
          await _supabase.from('users').select().eq('id', userId).single();
      return UserModel.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _supabase.from('users').update(data).eq('id', userId);
  }

  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _supabase.from('users').update({
        'name': user.name,
        'surname': user.surname,
        'phone_number': user.phoneNumber,
        'address': user.address,
      }).eq('id', user.id);
    } catch (e) {
      throw Exception('Kullanıcı profili güncellenirken bir hata oluştu: $e');
    }
  }

  Future<void> updatePassword(
      String currentPassword, String newPassword) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(
          password: newPassword,
        ),
      );

      if (response.user == null) {
        throw Exception('Şifre güncellenemedi');
      }
    } catch (e) {
      throw Exception('Şifre güncellenirken bir hata oluştu: $e');
    }
  }

  Future<String> uploadRestaurantPhoto(
      String restaurantId, String localFilePath, String fileName) async {
    try {
      await _supabase.storage.from('restaurant-photos').upload(
          'restaurant-photos/$restaurantId/$fileName', File(localFilePath));

      return _supabase.storage
          .from('restaurant-photos')
          .getPublicUrl('restaurant-photos/$restaurantId/$fileName');
    } catch (e) {
      throw Exception('Restoran fotoğrafı yüklenirken hata oluştu: $e');
    }
  }

  Future<String> uploadProfileImage(String userId, String filePath) async {
    try {
      final fileName = '$userId/profile.${filePath.split('.').last}';
      await _supabase.storage
          .from('profile-images')
          .upload(fileName, File(filePath));

      final imageUrl =
          _supabase.storage.from('profile-images').getPublicUrl(fileName);

      await _supabase
          .from('users')
          .update({'profile_image_url': imageUrl}).eq('id', userId);

      return imageUrl;
    } catch (e) {
      throw Exception('Profil fotoğrafı yüklenirken bir hata oluştu: $e');
    }
  }

  Future<String> uploadMenuItemPhoto(
      String restaurantId, String localFilePath, String fileName) async {
    try {
      await _supabase.storage
          .from('menu-photos')
          .upload('menu-photos/$restaurantId/$fileName', File(localFilePath));

      return _supabase.storage
          .from('menu-photos')
          .getPublicUrl('menu-photos/$restaurantId/$fileName');
    } catch (e) {
      throw Exception('Ürün fotoğrafı yüklenirken hata oluştu: $e');
    }
  }

  Future<void> deleteProfileImage(String userId, String imageUrl) async {
    try {
      final fileName =
          '$userId/profile.${imageUrl.split('.').last}'; // Dosya yolunu düzelttik
      await _supabase.storage.from('profile-images').remove([fileName]);

      // Kullanıcı profilinden fotoğrafı kaldır
      await _supabase
          .from('users')
          .update({'profile_image_url': null}).eq('id', userId);
    } catch (e) {
      throw Exception('Profil fotoğrafı silinirken bir hata oluştu: $e');
    }
  }

  // Restoran İşlemleri
  Future<void> createRestaurant(RestaurantModel restaurant) async {
    await _supabase.from('restaurants').insert(restaurant.toMap());
  }

  Future<RestaurantModel?> getRestaurant(String restaurantId) async {
    try {
      final data = await _supabase
          .from('restaurants')
          .select()
          .eq('id', restaurantId)
          .single();
      return RestaurantModel.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  Future<List<RestaurantModel>> getAllRestaurants() async {
    try {
      debugPrint('Restoranlar veritabanından yükleniyor...');
      final data = await _supabase.from('restaurants').select();
      debugPrint('Veritabanından gelen ham veri: $data');
      return (data as List)
          .map((restaurant) => RestaurantModel.fromMap(restaurant))
          .toList();
    } catch (e) {
      debugPrint('Restoranlar yüklenirken hata: $e');
      throw Exception('Restoranlar yüklenirken bir hata oluştu: $e');
    }
  }

  Future<List<RestaurantModel>> getRestaurantsByCategory(
      String category) async {
    final data = await _supabase
        .from('restaurants')
        .select()
        .contains('categories', [category]);
    return data.map((doc) => RestaurantModel.fromMap(doc)).toList();
  }

  Future<void> updateRestaurant(
      String restaurantId, Map<String, dynamic> data) async {
    await _supabase.from('restaurants').update(data).eq('id', restaurantId);
  }

  Future<void> addRestaurant(RestaurantModel restaurant) async {
    try {
      final restaurantData = restaurant.toMap();
      restaurantData.remove('owner_type');
      print('Eklenecek restoran verisi: $restaurantData');

      await _supabase.from('restaurants').insert(restaurantData);
      print('Restoran başarıyla eklendi');
    } catch (e) {
      print('Restoran eklenirken hata: $e');
      throw Exception('Restoran eklenirken bir hata oluştu: ${e.toString()}');
    }
  }

  Future<void> updateRestaurantData(RestaurantModel restaurant) async {
    try {
      final restaurantData = restaurant.toMap();
      restaurantData.remove('owner_type');

      await _supabase
          .from('restaurants')
          .update(restaurantData)
          .eq('id', restaurant.id);
    } catch (e) {
      throw Exception('Restoran güncellenirken bir hata oluştu: $e');
    }
  }

  Future<void> deleteRestaurant(String restaurantId) async {
    try {
      // Önce restoranın menü öğelerini silelim
      final menuItems = await getMenuItems(restaurantId);
      for (var item in menuItems) {
        await deleteMenuItem(item.id);
      }

      // Sonra restoranı silelim
      await _supabase.from('restaurants').delete().eq('id', restaurantId);
    } catch (e) {
      throw Exception('Restoran silinirken bir hata oluştu: $e');
    }
  }

  Future<void> deleteRestaurantPhoto(
      String restaurantId, String photoUrl) async {
    try {
      // Önce veritabanından kaydı sil
      await _supabase
          .from('restaurant_photos')
          .delete()
          .match({'restaurant_id': restaurantId, 'photo_url': photoUrl});

      // Sonra storage'dan dosyayı sil
      final filePath = photoUrl.split('restaurant-photos/').last;
      await _supabase.storage
          .from('restaurant-photos')
          .remove(['restaurant-photos/$filePath']);
    } catch (e) {
      throw Exception('Restoran fotoğrafı silinirken hata oluştu: $e');
    }
  }

  // Favoriler İşlemleri
  Future<void> toggleFavorite(String userId, String restaurantId) async {
    final data = await _supabase
        .from('users')
        .select('favorites')
        .eq('id', userId)
        .single();
    final favorites = List<String>.from(data['favorites'] ?? []);
    if (favorites.contains(restaurantId)) {
      favorites.remove(restaurantId);
    } else {
      favorites.add(restaurantId);
    }
    await _supabase
        .from('users')
        .update({'favorites': favorites}).eq('id', userId);
  }

  // Arama İşlemleri
  Future<List<RestaurantModel>> searchRestaurants(String query) async {
    final data =
        await _supabase.from('restaurants').select().ilike('name', '%$query%');
    return data.map((doc) => RestaurantModel.fromMap(doc)).toList();
  }

  // Menü Öğeleri İşlemleri
  Future<void> createMenuItem(MenuItemModel menuItem) async {
    try {
      await _supabase.from('menu_items').insert(menuItem.toJson());
    } catch (e) {
      throw Exception('Menü öğesi eklenirken bir hata oluştu: $e');
    }
  }

  Future<void> updateMenuItem(String itemId, MenuItemModel menuItem) async {
    try {
      await _supabase
          .from('menu_items')
          .update(menuItem.toJson())
          .eq('id', itemId);
    } catch (e) {
      throw Exception('Menü öğesi güncellenirken bir hata oluştu: $e');
    }
  }

  Future<void> deleteMenuItem(String itemId) async {
    try {
      print('Silinecek menü öğesi ID: $itemId');
      await _supabase.from('menu_items').delete().eq('id', itemId);
      print('Silme işlemi başarılı');
    } catch (e, stackTrace) {
      print('Menü öğesi silinirken hata: $e');
      print('Hata detayı: $stackTrace');
      throw Exception('Menü öğesi silinirken bir hata oluştu: $e');
    }
  }

  Future<void> deleteMenuItemPhoto(String restaurantId, String photoUrl) async {
    try {
      final filePath = photoUrl.split('menu-photos/').last;
      await _supabase.storage
          .from('menu-photos')
          .remove(['menu-photos/$filePath']);
    } catch (e) {
      throw Exception('Menü öğesi fotoğrafı silinirken hata oluştu: $e');
    }
  }

  Future<List<MenuItemModel>> getMenuItems(String restaurantId) async {
    try {
      final data = await _supabase
          .from('menu_items')
          .select()
          .eq('restaurant_id', restaurantId);
      return (data as List)
          .map((item) => MenuItemModel.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Menü öğeleri yüklenirken bir hata oluştu: $e');
    }
  }

  Future<List<MenuItemModel>> getMenuItemsByCategory(
      String restaurantId, MenuCategory category) async {
    try {
      final data = await _supabase
          .from('menu_items')
          .select()
          .eq('restaurant_id', restaurantId)
          .eq('category', category.toString().split('.').last);
      return (data as List)
          .map((item) => MenuItemModel.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Menü öğeleri yüklenirken bir hata oluştu: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getRestaurantMenus(
      String restaurantId) async {
    try {
      final menuItems = await getMenuItems(restaurantId);
      return menuItems
          .map((item) => {
                'id': item.id,
                'name': item.name,
                'description': item.description,
                'price': item.price,
                'category': item.category.toString().split('.').last,
                'image_url': item.imageUrl,
                'is_available': item.isAvailable,
              })
          .toList();
    } catch (e) {
      throw Exception('Restoran menüleri yüklenirken bir hata oluştu: $e');
    }
  }

  // Review İşlemleri
  Future<void> createReview(ReviewModel review) async {
    try {
      await _supabase.from('reviews').insert(review.toMap());
    } catch (e) {
      throw Exception('Yorum eklenirken bir hata oluştu: $e');
    }
  }

  Future<void> updateReview(String reviewId, ReviewModel review) async {
    try {
      await _supabase.from('reviews').update(review.toMap()).eq('id', reviewId);
    } catch (e) {
      throw Exception('Yorum güncellenirken bir hata oluştu: $e');
    }
  }

  Future<void> deleteReview(String reviewId) async {
    try {
      await _supabase.from('reviews').delete().eq('id', reviewId);
    } catch (e) {
      throw Exception('Yorum silinirken bir hata oluştu: $e');
    }
  }

  Future<ReviewModel?> getReview(String reviewId) async {
    try {
      final data =
          await _supabase.from('reviews').select().eq('id', reviewId).single();
      return ReviewModel.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  Future<List<ReviewModel>> getRestaurantReviews(String restaurantId) async {
    try {
      final data = await _supabase
          .from('reviews')
          .select()
          .eq('restaurant_id', restaurantId)
          .order('created_at', ascending: false);
      return (data as List)
          .map((review) => ReviewModel.fromMap(review))
          .toList();
    } catch (e) {
      throw Exception('Yorumlar yüklenirken bir hata oluştu: $e');
    }
  }

  Future<List<ReviewModel>> getUserReviews(String userId) async {
    try {
      final data = await _supabase
          .from('reviews')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (data as List)
          .map((review) => ReviewModel.fromMap(review))
          .toList();
    } catch (e) {
      throw Exception('Kullanıcı yorumları yüklenirken bir hata oluştu: $e');
    }
  }

  Future<String> uploadReviewImage(String restaurantId, String userId,
      String filePath, String fileName) async {
    try {
      final uploadPath = 'review-photos/$restaurantId/$userId/$fileName';
      await _supabase.storage
          .from('review-photos')
          .upload(uploadPath, File(filePath));

      return _supabase.storage.from('review-photos').getPublicUrl(uploadPath);
    } catch (e) {
      throw Exception('Fotoğraf yüklenirken bir hata oluştu: $e');
    }
  }

  // Review Report İşlemleri
  Future<void> createReviewReport(ReviewReportModel report) async {
    try {
      await _supabase.from('review_reports').insert(report.toMap());
      // Bildirim oluştur
      await _createAdminNotification('review_report', {
        'report_id': report.id,
        'review_id': report.reviewId,
        'reporter_id': report.reporterId,
        'reason': report.reason,
      });
    } catch (e) {
      throw Exception('Rapor oluşturulurken bir hata oluştu: $e');
    }
  }

  Future<void> updateReportStatus(String reportId, ReportStatus status) async {
    try {
      await _supabase.from('review_reports').update(
          {'status': status.toString().split('.').last}).eq('id', reportId);
    } catch (e) {
      throw Exception('Rapor durumu güncellenirken bir hata oluştu: $e');
    }
  }

  Future<List<ReviewReportModel>> getPendingReports() async {
    try {
      final data = await _supabase
          .from('review_reports')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      return (data as List)
          .map((report) => ReviewReportModel.fromMap(report))
          .toList();
    } catch (e) {
      throw Exception('Raporlar yüklenirken bir hata oluştu: $e');
    }
  }

  // Admin Bildirim İşlemleri
  Future<void> _createAdminNotification(
      String type, Map<String, dynamic> content) async {
    try {
      await _supabase.from('admin_notifications').insert({
        'type': type,
        'content': content,
      });
    } catch (e) {
      debugPrint('Admin bildirimi oluşturulurken hata: $e');
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _supabase
          .from('admin_notifications')
          .update({'is_read': true}).eq('id', notificationId);
    } catch (e) {
      throw Exception('Bildirim durumu güncellenirken bir hata oluştu: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAdminNotifications() async {
    try {
      final data = await _supabase
          .from('admin_notifications')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      throw Exception('Bildirimler yüklenirken bir hata oluştu: $e');
    }
  }

  Future<List<String>> getRestaurantPhotos(String restaurantId) async {
    try {
      final List<FileObject> result = await _supabase.storage
          .from('restaurant-photos')
          .list(path: 'restaurant-photos/$restaurantId');

      return Future.wait(
        result.map((file) async {
          return _supabase.storage
              .from('restaurant-photos')
              .getPublicUrl('restaurant-photos/$restaurantId/${file.name}');
        }),
      );
    } catch (e) {
      debugPrint('Restaurant photos could not be loaded: $e');
      return [];
    }
  }
}

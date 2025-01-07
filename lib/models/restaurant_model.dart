import 'package:flutter/foundation.dart';

class RestaurantModel {
  final String id;
  final String name;
  final String description;
  final String address;
  final String phone_number;
  final double latitude;
  final double longitude;
  final String ownerId;
  final double rating;
  final bool isOpen;
  final String imageUrl;
  final int ratingCount;
  final Map<String, dynamic> workingHours;
  final DateTime createdAt;

  RestaurantModel({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.phone_number,
    required this.latitude,
    required this.longitude,
    required this.ownerId,
    this.rating = 0.0,
    this.isOpen = true,
    this.imageUrl = '',
    this.ratingCount = 0,
    this.workingHours = const {},
    DateTime? createdAt,
  }) : this.createdAt = createdAt ?? DateTime.now();

  factory RestaurantModel.fromMap(Map<String, dynamic> map) {
    debugPrint('RestaurantModel.fromMap çağrıldı. Ham veri: $map');

    // Koordinatları string olarak alıp virgülü noktaya çevirip double'a dönüştür
    final locationStr =
        map['location'].toString().replaceAll('(', '').replaceAll(')', '');
    final coordinates = locationStr.split(',');
    final latitude = double.parse(coordinates[0]);
    final longitude = double.parse(coordinates[1]);

    debugPrint('Koordinatlar: lat=$latitude, lng=$longitude');

    return RestaurantModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      address: map['address'] ?? '',
      phone_number: map['phone_number'] ?? '',
      latitude: latitude,
      longitude: longitude,
      ownerId: map['owner_id'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      isOpen: map['is_open'] ?? true,
      imageUrl: map['image_url'] ?? '',
      ratingCount: (map['rating_count'] ?? 0).toInt(),
      workingHours: Map<String, dynamic>.from(map['working_hours'] ?? {}),
      createdAt:
          DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'phone_number': phone_number,
      'location': createPointString(latitude, longitude),
      'owner_id': ownerId,
      'rating': rating,
      'is_open': isOpen,
      'image_url': imageUrl,
      'rating_count': ratingCount,
      'working_hours': workingHours,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static String createPointString(double latitude, double longitude) {
    return '($latitude,$longitude)';
  }
}

import 'package:uuid/uuid.dart';

class ReviewModel {
  final String id;
  final String restaurantId;
  final String userId;
  final int rating;
  final String comment;
  final List<String> photos;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReviewModel({
    String? id,
    required this.restaurantId,
    required this.userId,
    required this.rating,
    required this.comment,
    List<String>? photos,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : this.id = id ?? const Uuid().v4(),
        this.photos = photos ?? [],
        this.createdAt = createdAt ?? DateTime.now(),
        this.updatedAt = updatedAt ?? DateTime.now();

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      id: map['id'],
      restaurantId: map['restaurant_id'],
      userId: map['user_id'],
      rating: map['rating'],
      comment: map['comment'] ?? '',
      photos: List<String>.from(map['photos'] ?? []),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'user_id': userId,
      'rating': rating,
      'comment': comment,
      'photos': photos,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ReviewModel copyWith({
    String? id,
    String? restaurantId,
    String? userId,
    int? rating,
    String? comment,
    List<String>? photos,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      userId: userId ?? this.userId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      photos: photos ?? this.photos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

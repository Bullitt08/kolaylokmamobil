enum UserType {
  normal,
  restaurant,
  admin,
}

class UserModel {
  final String id;
  final String email;
  final String name;
  final String surname;
  final String phoneNumber;
  final String address;
  final List<String> favorites;
  final List<String> orders;
  final DateTime createdAt;
  final UserType userType;
  final String? restaurantId;
  final String? profileImageUrl;

  String get fullName => '$name $surname';

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.surname,
    String? phoneNumber,
    String? address,
    List<String>? favorites,
    List<String>? orders,
    DateTime? createdAt,
    required this.userType,
    this.restaurantId,
    this.profileImageUrl,
  })  : this.phoneNumber = phoneNumber ?? '',
        this.address = address ?? '',
        this.favorites = favorites ?? [],
        this.orders = orders ?? [],
        this.createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'surname': surname,
      'phone_number': phoneNumber,
      'address': address,
      'favorites': favorites,
      'created_at': createdAt.toIso8601String(),
      'user_type': userType.toString().split('.').last,
      'restaurant_id': restaurantId,
      'profile_image_url': profileImageUrl,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id']?.toString() ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      surname: map['surname'] ?? '',
      phoneNumber: map['phone_number'],
      address: map['address'],
      favorites: List<String>.from(map['favorites'] ?? []),
      orders: List<String>.from(map['orders'] ?? []),
      createdAt:
          DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      userType: UserType.values.firstWhere(
        (e) => e.toString().split('.').last == (map['user_type'] ?? 'normal'),
        orElse: () => UserType.normal,
      ),
      restaurantId: map['restaurant_id'],
      profileImageUrl: map['profile_image_url'],
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, surname: $surname, email: $email, userType: $userType)';
  }

  bool get isAdmin => userType == UserType.admin;
  bool get isRestaurant => userType == UserType.restaurant;
  bool get isNormalUser => userType == UserType.normal;
}

class ShopModel {
  final String id;
  final String email;
  final String name;
  final String shopOwnerName;
  final String? address;
  final bool isActive;
  final String authUserId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShopModel({
    required this.id,
    required this.email,
    required this.name,
    required this.shopOwnerName,
    this.address,
    required this.isActive,
    required this.authUserId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      shopOwnerName: json['shop_owner_name'] ?? '',
      address: json['address'],
      isActive: json['is_active'] ?? false,
      authUserId: json['auth_user_id'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'shop_owner_name': shopOwnerName,
      'address': address,
      'is_active': isActive,
      'auth_user_id': authUserId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}



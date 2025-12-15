import 'shop_model.dart';

enum UserRole {
  shopOwner,
  admin,
  officeStaff,
  freelance,
  marketingManager,
}

class UserModel {
  final String id;
  final String shopId;
  final String email;
  final String name;
  final UserRole role;
  final bool isActive;
  final String authUserId;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.shopId,
    required this.email,
    required this.name,
    required this.role,
    required this.isActive,
    required this.authUserId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      shopId: json['shop_id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: roleFromString(json['role'] ?? 'staff'),
      isActive: json['is_active'] ?? false,
      authUserId: json['auth_user_id'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  static UserRole roleFromString(String role) {
    switch (role) {
      case 'shop_owner':
        return UserRole.shopOwner;
      case 'admin':
        return UserRole.admin;
      case 'office_staff':
        return UserRole.officeStaff;
      case 'freelance':
        return UserRole.freelance;
      case 'marketing_manager':
        return UserRole.marketingManager;
      default:
        return UserRole.officeStaff;
    }
  }

  String get roleString {
    switch (role) {
      case UserRole.shopOwner:
        return 'shop_owner';
      case UserRole.admin:
        return 'admin';
      case UserRole.officeStaff:
        return 'office_staff';
      case UserRole.freelance:
        return 'freelance';
      case UserRole.marketingManager:
        return 'marketing_manager';
    }
  }

  static String roleToString(UserRole role) {
    switch (role) {
      case UserRole.shopOwner:
        return 'shop_owner';
      case UserRole.admin:
        return 'admin';
      case UserRole.officeStaff:
        return 'office_staff';
      case UserRole.freelance:
        return 'freelance';
      case UserRole.marketingManager:
        return 'marketing_manager';
    }
  }

  static String roleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.shopOwner:
        return 'Shop Owner';
      case UserRole.admin:
        return 'Admin';
      case UserRole.officeStaff:
        return 'Office Staff';
      case UserRole.freelance:
        return 'Freelance';
      case UserRole.marketingManager:
        return 'Marketing Manager';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'email': email,
      'name': name,
      'role': roleString,
      'is_active': isActive,
      'auth_user_id': authUserId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class UserWithShopModel extends UserModel {
  final ShopModel? shop;

  UserWithShopModel({
    required super.id,
    required super.shopId,
    required super.email,
    required super.name,
    required super.role,
    required super.isActive,
    required super.authUserId,
    required super.createdAt,
    required super.updatedAt,
    this.shop,
  });

  factory UserWithShopModel.fromJson(Map<String, dynamic> json) {
    return UserWithShopModel(
      id: json['id'] ?? '',
      shopId: json['shop_id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: UserModel.roleFromString(json['role'] ?? 'staff'),
      isActive: json['is_active'] ?? false,
      authUserId: json['auth_user_id'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      shop: json['shops'] != null ? ShopModel.fromJson(json['shops'] as Map<String, dynamic>) : null,
    );
  }
}

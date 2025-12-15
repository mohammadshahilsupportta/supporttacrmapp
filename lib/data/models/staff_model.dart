import 'user_model.dart';
import 'category_model.dart';

class StaffModel extends UserModel {
  StaffModel({
    required super.id,
    required super.shopId,
    required super.email,
    required super.name,
    required super.role,
    required super.isActive,
    required super.authUserId,
    required super.createdAt,
    required super.updatedAt,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['id']?.toString() ?? '',
      shopId: json['shop_id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: UserModel.roleFromString(json['role']?.toString() ?? 'office_staff'),
      isActive: json['is_active'] ?? false,
      authUserId: json['auth_user_id']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
    );
  }
}

class StaffWithPermissionsModel extends StaffModel {
  final List<CategoryModel> categoryPermissions;

  StaffWithPermissionsModel({
    required super.id,
    required super.shopId,
    required super.email,
    required super.name,
    required super.role,
    required super.isActive,
    required super.authUserId,
    required super.createdAt,
    required super.updatedAt,
    this.categoryPermissions = const [],
  });

  factory StaffWithPermissionsModel.fromJson(Map<String, dynamic> json) {
    final categories = (json['staff_category_permissions'] as List<dynamic>?)
            ?.map((scp) {
              final scpMap = scp as Map<String, dynamic>?;
              if (scpMap == null) return null;
              final cat = scpMap['category'] as Map<String, dynamic>?;
              return cat != null ? CategoryModel.fromJson(cat) : null;
            })
            .whereType<CategoryModel>()
            .toList() ??
        [];

    return StaffWithPermissionsModel(
      id: json['id']?.toString() ?? '',
      shopId: json['shop_id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: UserModel.roleFromString(json['role']?.toString() ?? 'office_staff'),
      isActive: json['is_active'] ?? false,
      authUserId: json['auth_user_id']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
      categoryPermissions: categories,
    );
  }
}

class CreateStaffInput {
  final String name;
  final String email;
  final String password;
  final UserRole? role;
  final List<String>? categoryIds;
  final String? phone;

  CreateStaffInput({
    required this.name,
    required this.email,
    required this.password,
    this.role,
    this.categoryIds,
    this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'role': role != null ? UserModel.roleToString(role!) : 'office_staff',
      'phone': phone,
    };
  }
}

class UpdateStaffInput {
  final String id;
  final String? name;
  final String? email;
  final UserRole? role;
  final bool? isActive;
  final String? phone;
  final List<String>? categoryIds;

  UpdateStaffInput({
    required this.id,
    this.name,
    this.email,
    this.role,
    this.isActive,
    this.phone,
    this.categoryIds,
  });

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (role != null) 'role': UserModel.roleToString(role!),
      if (isActive != null) 'is_active': isActive,
      if (phone != null) 'phone': phone,
    };
  }
}


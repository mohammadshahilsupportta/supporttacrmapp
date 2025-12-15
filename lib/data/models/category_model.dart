class CategoryModel {
  final String id;
  final String shopId;
  final String name;
  final String? description;
  final String? color;
  final DateTime createdAt;
  final DateTime updatedAt;

  CategoryModel({
    required this.id,
    required this.shopId,
    required this.name,
    this.description,
    this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? '',
      shopId: json['shop_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      color: json['color'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'name': name,
      'description': description,
      'color': color,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class CreateCategoryInput {
  final String name;
  final String? description;
  final String? color;

  CreateCategoryInput({
    required this.name,
    this.description,
    this.color,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'color': color,
    };
  }
}

class UpdateCategoryInput {
  final String id;
  final String? name;
  final String? description;
  final String? color;

  UpdateCategoryInput({
    required this.id,
    this.name,
    this.description,
    this.color,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'color': color,
    };
  }
}



import 'category_model.dart';

enum LeadStatus { newLead, contacted, qualified, converted, lost }

enum LeadSource { website, phone, walkIn, referral, socialMedia, email, other }

class LeadModel {
  final String id;
  final String shopId;
  final String name;
  final String? email;
  final String? phone;
  final String? whatsapp;
  final String? company;
  final String? address;
  final String? occupation;
  final String? fieldOfWork;
  final LeadSource? source;
  final String? notes;
  final LeadStatus status;
  final String? assignedTo;
  final List<String>? products;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final DateTime? deletedAt;
  final int? score;
  final String? scoreCategory;
  final DateTime? scoreUpdatedAt;

  LeadModel({
    required this.id,
    required this.shopId,
    required this.name,
    this.email,
    this.phone,
    this.whatsapp,
    this.company,
    this.address,
    this.occupation,
    this.fieldOfWork,
    this.source,
    this.notes,
    required this.status,
    this.assignedTo,
    this.products,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.deletedAt,
    this.score,
    this.scoreCategory,
    this.scoreUpdatedAt,
  });

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    return LeadModel(
      id: json['id'] ?? '',
      shopId: json['shop_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      whatsapp: json['whatsapp'],
      company: json['company'],
      address: json['address'],
      occupation: json['occupation'],
      fieldOfWork: json['field_of_work'],
      source: json['source'] != null ? _sourceFromString(json['source']) : null,
      notes: json['notes'],
      status: _statusFromString(json['status'] ?? 'newLead'),
      assignedTo: json['assigned_to'],
      products: json['products'] != null
          ? List<String>.from(json['products'] as List)
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      createdBy: json['created_by'],
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'])
          : null,
      score: json['score'] != null ? json['score'] as int : null,
      scoreCategory: json['score_category'] as String?,
      scoreUpdatedAt: json['score_updated_at'] != null
          ? DateTime.parse(json['score_updated_at'])
          : null,
    );
  }

  static LeadStatus _statusFromString(String status) {
    switch (status) {
      case 'contacted':
        return LeadStatus.contacted;
      case 'qualified':
        return LeadStatus.qualified;
      case 'converted':
        return LeadStatus.converted;
      case 'lost':
        return LeadStatus.lost;
      default:
        return LeadStatus.newLead;
    }
  }

  static LeadSource _sourceFromString(String source) {
    switch (source) {
      case 'website':
        return LeadSource.website;
      case 'phone':
        return LeadSource.phone;
      case 'walk-in':
        return LeadSource.walkIn;
      case 'referral':
        return LeadSource.referral;
      case 'social-media':
        return LeadSource.socialMedia;
      case 'email':
        return LeadSource.email;
      default:
        return LeadSource.other;
    }
  }

  String get statusString {
    switch (status) {
      case LeadStatus.newLead:
        return 'new';
      case LeadStatus.contacted:
        return 'contacted';
      case LeadStatus.qualified:
        return 'qualified';
      case LeadStatus.converted:
        return 'converted';
      case LeadStatus.lost:
        return 'lost';
    }
  }

  String get sourceString {
    if (source == null) return '';
    switch (source!) {
      case LeadSource.website:
        return 'website';
      case LeadSource.phone:
        return 'phone';
      case LeadSource.walkIn:
        return 'walk-in';
      case LeadSource.referral:
        return 'referral';
      case LeadSource.socialMedia:
        return 'social-media';
      case LeadSource.email:
        return 'email';
      case LeadSource.other:
        return 'other';
    }
  }

  static String statusToString(LeadStatus status) {
    switch (status) {
      case LeadStatus.newLead:
        return 'new';
      case LeadStatus.contacted:
        return 'contacted';
      case LeadStatus.qualified:
        return 'qualified';
      case LeadStatus.converted:
        return 'converted';
      case LeadStatus.lost:
        return 'lost';
    }
  }

  static String sourceToString(LeadSource source) {
    switch (source) {
      case LeadSource.website:
        return 'website';
      case LeadSource.phone:
        return 'phone';
      case LeadSource.walkIn:
        return 'walk-in';
      case LeadSource.referral:
        return 'referral';
      case LeadSource.socialMedia:
        return 'social-media';
      case LeadSource.email:
        return 'email';
      case LeadSource.other:
        return 'other';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'name': name,
      'email': email,
      'phone': phone,
      'whatsapp': whatsapp,
      'company': company,
      'address': address,
      'occupation': occupation,
      'field_of_work': fieldOfWork,
      'source': sourceString,
      'notes': notes,
      'status': statusString,
      'assigned_to': assignedTo,
      'products': products,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
      'deleted_at': deletedAt?.toIso8601String(),
      'score': score,
      'score_category': scoreCategory,
      'score_updated_at': scoreUpdatedAt?.toIso8601String(),
    };
  }
}

class LeadWithRelationsModel extends LeadModel {
  final AssignedUser? assignedUser;
  final CreatedByUser? createdByUser;
  final List<CategoryModel> categories;

  LeadWithRelationsModel({
    required super.id,
    required super.shopId,
    required super.name,
    super.email,
    super.phone,
    super.whatsapp,
    super.company,
    super.address,
    super.occupation,
    super.fieldOfWork,
    super.source,
    super.notes,
    required super.status,
    super.assignedTo,
    super.products,
    required super.createdAt,
    required super.updatedAt,
    super.createdBy,
    super.deletedAt,
    super.score,
    super.scoreCategory,
    super.scoreUpdatedAt,
    this.assignedUser,
    this.createdByUser,
    this.categories = const [],
  });

  factory LeadWithRelationsModel.fromJson(Map<String, dynamic> json) {
    return LeadWithRelationsModel(
      id: json['id'] ?? '',
      shopId: json['shop_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      whatsapp: json['whatsapp'],
      company: json['company'],
      address: json['address'],
      occupation: json['occupation'],
      fieldOfWork: json['field_of_work'],
      source: json['source'] != null
          ? LeadModel._sourceFromString(json['source'])
          : null,
      notes: json['notes'],
      status: LeadModel._statusFromString(json['status'] ?? 'new'),
      assignedTo: json['assigned_to'],
      products: json['products'] != null
          ? List<String>.from(json['products'] as List)
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      createdBy: json['created_by'],
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'])
          : null,
      score: json['score'] != null ? json['score'] as int : null,
      scoreCategory: json['score_category'] as String?,
      scoreUpdatedAt: json['score_updated_at'] != null
          ? DateTime.parse(json['score_updated_at'])
          : null,
      assignedUser: json['assigned_user'] != null
          ? AssignedUser.fromJson(json['assigned_user'])
          : null,
      createdByUser: json['created_by_user'] != null
          ? CreatedByUser.fromJson(json['created_by_user'])
          : null,
      categories:
          (json['categories'] as List<dynamic>?)
              ?.map((cat) => CategoryModel.fromJson(cat))
              .toList() ??
          [],
    );
  }
}

class AssignedUser {
  final String id;
  final String name;
  final String email;

  AssignedUser({required this.id, required this.name, required this.email});

  factory AssignedUser.fromJson(Map<String, dynamic> json) {
    return AssignedUser(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

class CreatedByUser {
  final String id;
  final String name;

  CreatedByUser({required this.id, required this.name});

  factory CreatedByUser.fromJson(Map<String, dynamic> json) {
    return CreatedByUser(id: json['id'] ?? '', name: json['name'] ?? '');
  }
}

class CreateLeadInput {
  final String name;
  final String? email;
  final String? phone;
  final String? whatsapp;
  final String? company;
  final String? address;
  final String? occupation;
  final String? fieldOfWork;
  final LeadSource? source;
  final String? notes;
  final LeadStatus? status;
  final String? assignedTo;
  final List<String>? categoryIds;
  final List<String>? products;

  CreateLeadInput({
    required this.name,
    this.email,
    this.phone,
    this.whatsapp,
    this.company,
    this.address,
    this.occupation,
    this.fieldOfWork,
    this.source,
    this.notes,
    this.status,
    this.assignedTo,
    this.categoryIds,
    this.products,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'whatsapp': whatsapp,
      'company': company,
      'address': address,
      'occupation': occupation,
      'field_of_work': fieldOfWork,
      'source': source != null ? LeadModel.sourceToString(source!) : null,
      'notes': notes,
      'status': status != null ? LeadModel.statusToString(status!) : 'new',
      'assigned_to': assignedTo,
      'products': products,
    };
  }
}

enum LeadSortBy {
  name,
  createdAt,
  updatedAt,
  score,
  status,
}

enum LeadSortOrder {
  asc,
  desc,
}

class LeadFilters {
  final List<LeadStatus>? status;
  final List<String>? categoryIds;
  final String? assignedTo;
  final LeadSource? source;
  final String? search;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final List<String>? scoreCategories; // 'hot', 'warm', 'cold', 'unscored'
  final LeadSortBy? sortBy;
  final LeadSortOrder? sortOrder;
  final int? limit;
  final int? offset;

  LeadFilters({
    this.status,
    this.categoryIds,
    this.assignedTo,
    this.source,
    this.search,
    this.dateFrom,
    this.dateTo,
    this.scoreCategories,
    this.sortBy,
    this.sortOrder,
    this.limit,
    this.offset,
  });
}

class LeadStats {
  final int total;
  final Map<LeadStatus, int> byStatus;
  final List<CategoryCount> byCategory;
  final int recentCount;

  LeadStats({
    required this.total,
    required this.byStatus,
    required this.byCategory,
    required this.recentCount,
  });
}

class CategoryCount {
  final String categoryId;
  final String categoryName;
  final int count;

  CategoryCount({
    required this.categoryId,
    required this.categoryName,
    required this.count,
  });
}

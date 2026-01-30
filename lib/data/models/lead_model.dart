import 'category_model.dart';

/// Lead status matching website's 8 statuses
enum LeadStatus {
  willContact,
  needFollowUp,
  appointmentScheduled,
  proposalSent,
  alreadyHas,
  noNeedNow,
  closedWon,
  closedLost,
}

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
  final String? country;
  final String? state;
  final String? city;
  final String? district;
  final String? occupation;
  final String? fieldOfWork;
  final LeadSource? source;
  final String? notes;
  final LeadStatus status;
  final String? assignedTo;
  final List<String>? products;
  final double? value;
  final String? alternativePhone;
  final String? businessPhone;
  final String? companyPhone;
  final List<String>? alternativeEmails;
  final String? homeAddress;
  final String? businessAddress;
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
    this.country,
    this.state,
    this.city,
    this.district,
    this.occupation,
    this.fieldOfWork,
    this.source,
    this.notes,
    required this.status,
    this.assignedTo,
    this.products,
    this.value,
    this.alternativePhone,
    this.businessPhone,
    this.companyPhone,
    this.alternativeEmails,
    this.homeAddress,
    this.businessAddress,
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
      country: json['country'],
      state: json['state'],
      city: json['city'],
      district: json['district'],
      occupation: json['occupation'],
      fieldOfWork: json['field_of_work'],
      source: json['source'] != null ? _sourceFromString(json['source']) : null,
      notes: json['notes'],
      status: statusFromString(json['status'] ?? 'will_contact'),
      assignedTo: json['assigned_to'],
      products: json['products'] != null
          ? List<String>.from(json['products'] as List)
          : null,
      value: json['value'] != null
          ? (json['value'] is num
                ? (json['value'] as num).toDouble()
                : double.tryParse(json['value'].toString()))
          : null,
      alternativePhone: json['alternative_phone'] as String?,
      businessPhone: json['business_phone'] as String?,
      companyPhone: json['company_phone'] as String?,
      alternativeEmails: json['alternative_emails'] != null
          ? List<String>.from(json['alternative_emails'] as List)
          : null,
      homeAddress: json['home_address'] as String?,
      businessAddress: json['business_address'] as String?,
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

  static LeadStatus statusFromString(String status) {
    switch (status) {
      case 'will_contact':
        return LeadStatus.willContact;
      case 'need_follow_up':
        return LeadStatus.needFollowUp;
      case 'appointment_scheduled':
        return LeadStatus.appointmentScheduled;
      case 'proposal_sent':
        return LeadStatus.proposalSent;
      case 'already_has':
        return LeadStatus.alreadyHas;
      case 'no_need_now':
        return LeadStatus.noNeedNow;
      case 'closed_won':
        return LeadStatus.closedWon;
      case 'closed_lost':
        return LeadStatus.closedLost;
      // Legacy 5-status support (map to closest 8-status equivalent)
      case 'new':
        return LeadStatus.willContact;
      case 'contacted':
        return LeadStatus.needFollowUp;
      case 'qualified':
        return LeadStatus.appointmentScheduled;
      case 'converted':
        return LeadStatus.closedWon;
      case 'lost':
        return LeadStatus.closedLost;
      default:
        return LeadStatus.willContact;
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
      case LeadStatus.willContact:
        return 'will_contact';
      case LeadStatus.needFollowUp:
        return 'need_follow_up';
      case LeadStatus.appointmentScheduled:
        return 'appointment_scheduled';
      case LeadStatus.proposalSent:
        return 'proposal_sent';
      case LeadStatus.alreadyHas:
        return 'already_has';
      case LeadStatus.noNeedNow:
        return 'no_need_now';
      case LeadStatus.closedWon:
        return 'closed_won';
      case LeadStatus.closedLost:
        return 'closed_lost';
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
      case LeadStatus.willContact:
        return 'will_contact';
      case LeadStatus.needFollowUp:
        return 'need_follow_up';
      case LeadStatus.appointmentScheduled:
        return 'appointment_scheduled';
      case LeadStatus.proposalSent:
        return 'proposal_sent';
      case LeadStatus.alreadyHas:
        return 'already_has';
      case LeadStatus.noNeedNow:
        return 'no_need_now';
      case LeadStatus.closedWon:
        return 'closed_won';
      case LeadStatus.closedLost:
        return 'closed_lost';
    }
  }

  /// Human-readable status label for display (no underscores).
  static String statusToDisplayLabel(LeadStatus status) {
    switch (status) {
      case LeadStatus.willContact:
        return 'Will Contact';
      case LeadStatus.needFollowUp:
        return 'Need Follow-Up';
      case LeadStatus.appointmentScheduled:
        return 'Appointment Scheduled';
      case LeadStatus.proposalSent:
        return 'Proposal Sent';
      case LeadStatus.alreadyHas:
        return 'Already Has';
      case LeadStatus.noNeedNow:
        return 'No Need Now';
      case LeadStatus.closedWon:
        return 'Closed – Won';
      case LeadStatus.closedLost:
        return 'Closed – Lost';
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
      'country': country,
      'state': state,
      'city': city,
      'district': district,
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
    super.country,
    super.state,
    super.city,
    super.district,
    super.occupation,
    super.fieldOfWork,
    super.source,
    super.notes,
    required super.status,
    super.assignedTo,
    super.products,
    super.value,
    super.alternativePhone,
    super.businessPhone,
    super.companyPhone,
    super.alternativeEmails,
    super.homeAddress,
    super.businessAddress,
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
      country: json['country'],
      state: json['state'],
      city: json['city'],
      district: json['district'],
      occupation: json['occupation'],
      fieldOfWork: json['field_of_work'],
      source: json['source'] != null
          ? LeadModel._sourceFromString(json['source'])
          : null,
      notes: json['notes'],
      status: LeadModel.statusFromString(json['status'] ?? 'will_contact'),
      assignedTo: json['assigned_to'],
      products: json['products'] != null
          ? List<String>.from(json['products'] as List)
          : null,
      value: json['value'] != null
          ? (json['value'] is num
                ? (json['value'] as num).toDouble()
                : double.tryParse(json['value'].toString()))
          : null,
      alternativePhone: json['alternative_phone'] as String?,
      businessPhone: json['business_phone'] as String?,
      companyPhone: json['company_phone'] as String?,
      alternativeEmails: json['alternative_emails'] != null
          ? List<String>.from(json['alternative_emails'] as List)
          : null,
      homeAddress: json['home_address'] as String?,
      businessAddress: json['business_address'] as String?,
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
  final String? alternativePhone;
  final String? businessPhone;
  final String? companyPhone;
  final List<String>? alternativeEmails;
  final String? address;
  final String? homeAddress;
  final String? businessAddress;
  final String? country;
  final String? state;
  final String? city;
  final String? district;
  final String? occupation;
  final String? fieldOfWork;
  final LeadSource? source;
  final String? notes;
  final LeadStatus? status;
  final String? assignedTo;
  final List<String>? categoryIds;
  final List<String>? products;
  final double? value;

  CreateLeadInput({
    required this.name,
    this.email,
    this.phone,
    this.whatsapp,
    this.company,
    this.alternativePhone,
    this.businessPhone,
    this.companyPhone,
    this.alternativeEmails,
    this.address,
    this.homeAddress,
    this.businessAddress,
    this.country,
    this.state,
    this.city,
    this.district,
    this.occupation,
    this.fieldOfWork,
    this.source,
    this.notes,
    this.status,
    this.assignedTo,
    this.categoryIds,
    this.products,
    this.value,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'email': email,
      'phone': phone,
      'whatsapp': whatsapp,
      'company': company,
      'address': address,
      'country': country,
      'state': state,
      'city': city,
      'district': district,
      'occupation': occupation,
      'field_of_work': fieldOfWork,
      'source': source != null ? LeadModel.sourceToString(source!) : null,
      'notes': notes,
      'status': status != null
          ? LeadModel.statusToString(status!)
          : 'need_follow_up',
      'assigned_to': assignedTo,
      'products': products,
    };
    if (alternativePhone != null) map['alternative_phone'] = alternativePhone;
    if (businessPhone != null) map['business_phone'] = businessPhone;
    if (companyPhone != null) map['company_phone'] = companyPhone;
    if (alternativeEmails != null)
      map['alternative_emails'] = alternativeEmails;
    if (homeAddress != null) map['home_address'] = homeAddress;
    if (businessAddress != null) map['business_address'] = businessAddress;
    if (value != null) map['value'] = value;
    return map;
  }
}

/// Build notes string from requirement + additional notes (website format).
String buildLeadNotes(String? requirement, String? additionalNotes) {
  final parts = <String>[];
  if (requirement != null && requirement.trim().isNotEmpty) {
    parts.add('REQUIREMENT:\n${requirement.trim()}');
  }
  if (additionalNotes != null && additionalNotes.trim().isNotEmpty) {
    parts.add('ADDITIONAL NOTES:\n${additionalNotes.trim()}');
  }
  return parts.isEmpty ? '' : parts.join('\n\n');
}

/// Parse notes into requirement and additional notes (website format).
({String requirement, String additionalNotes}) parseLeadNotes(String? notes) {
  if (notes == null || notes.trim().isEmpty) {
    return (requirement: '', additionalNotes: '');
  }
  final requirementMatch = RegExp(
    r'REQUIREMENT:\n([\s\S]*?)(?:\n\n|$)',
  ).firstMatch(notes);
  final requirement = requirementMatch?.group(1)?.trim() ?? '';
  var additionalNotes = notes
      .replaceFirst(RegExp(r'REQUIREMENT:\n[\s\S]*?(\n\n|$)'), '')
      .replaceFirst(RegExp(r'ADDITIONAL NOTES:\n?'), '')
      .trim();
  return (requirement: requirement, additionalNotes: additionalNotes);
}

/// Get display name: company or name (website style).
String getLeadDisplayName(LeadModel lead) {
  final name = (lead.name).trim();
  final company = (lead.company ?? '').trim();
  if (company.isNotEmpty && name.isNotEmpty) return '$company - $name';
  if (company.isNotEmpty) return company;
  if (name.isNotEmpty) return name;
  return '—';
}

enum LeadSortBy { name, createdAt, updatedAt, score, status }

enum LeadSortOrder { asc, desc }

class LeadFilters {
  final List<LeadStatus>? status;
  final List<String>? categoryIds;
  final String? assignedTo;
  final String? createdBy;
  final LeadSource? source;
  final String? search;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final List<String>? scoreCategories; // 'hot', 'warm', 'cold', 'unscored'
  final String? country;
  final String? state;
  final String? city;
  final String? district;
  final LeadSortBy? sortBy;
  final LeadSortOrder? sortOrder;
  final int? limit;
  final int? offset;

  LeadFilters({
    this.status,
    this.categoryIds,
    this.assignedTo,
    this.createdBy,
    this.source,
    this.search,
    this.dateFrom,
    this.dateTo,
    this.scoreCategories,
    this.country,
    this.state,
    this.city,
    this.district,
    this.sortBy,
    this.sortOrder,
    this.limit,
    this.offset,
  });
}

class LeadStats {
  final int total;
  final Map<LeadStatus, int> byStatus;

  /// Counts by raw status string from DB. Used for dashboard Lead Status Overview
  /// to match website's 8 statuses: will_contact, need_follow_up, appointment_scheduled,
  /// proposal_sent, already_has, no_need_now, closed_won, closed_lost.
  final Map<String, int> byStatusString;
  final List<CategoryCount> byCategory;
  final int recentCount;
  final int assignedCount; // Count of leads assigned to user (for staff roles)
  /// Sum of lead value for visible leads (admin: all shop leads, staff: their leads). Like website.
  final double totalLeadValue;

  LeadStats({
    required this.total,
    required this.byStatus,
    required this.byCategory,
    required this.recentCount,
    this.assignedCount = 0, // Default to 0 if not provided
    Map<String, int>? byStatusString,
    this.totalLeadValue = 0,
  }) : byStatusString = byStatusString ?? {};
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

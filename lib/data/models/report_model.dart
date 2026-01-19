/// Report models for staff performance analytics

class StaffPerformanceStats {
  final String staffId;
  final String staffName;
  final String staffEmail;
  final String role;
  final bool isActive;
  
  // Conversion Metrics
  final int totalLeadsAssigned;
  final int totalConversions;
  final double conversionRate; // percentage (0-100)
  final int conversionsThisMonth;
  final int conversionsThisWeek;
  
  // Time Metrics
  final double? avgDaysToConvert;
  final int? fastestConversionDays;
  final int? slowestConversionDays;
  
  // Lead Status Breakdown
  final LeadsByStatus leadsByStatus;
  
  // Timeline
  final DateTime? firstConversionDate;
  final DateTime? latestConversionDate;

  StaffPerformanceStats({
    required this.staffId,
    required this.staffName,
    required this.staffEmail,
    required this.role,
    required this.isActive,
    required this.totalLeadsAssigned,
    required this.totalConversions,
    required this.conversionRate,
    required this.conversionsThisMonth,
    required this.conversionsThisWeek,
    this.avgDaysToConvert,
    this.fastestConversionDays,
    this.slowestConversionDays,
    required this.leadsByStatus,
    this.firstConversionDate,
    this.latestConversionDate,
  });

  factory StaffPerformanceStats.fromJson(Map<String, dynamic> json) {
    return StaffPerformanceStats(
      staffId: json['staff_id'] as String,
      staffName: json['staff_name'] as String,
      staffEmail: json['staff_email'] as String,
      role: json['role'] as String,
      isActive: json['is_active'] as bool? ?? true,
      totalLeadsAssigned: json['total_leads_assigned'] as int? ?? 0,
      totalConversions: json['total_conversions'] as int? ?? 0,
      conversionRate: (json['conversion_rate'] as num?)?.toDouble() ?? 0.0,
      conversionsThisMonth: json['conversions_this_month'] as int? ?? 0,
      conversionsThisWeek: json['conversions_this_week'] as int? ?? 0,
      avgDaysToConvert: json['avg_days_to_convert'] != null
          ? (json['avg_days_to_convert'] as num).toDouble()
          : null,
      fastestConversionDays: json['fastest_conversion_days'] as int?,
      slowestConversionDays: json['slowest_conversion_days'] as int?,
      leadsByStatus: LeadsByStatus.fromJson(
        json['leads_by_status'] as Map<String, dynamic>? ?? {},
      ),
      firstConversionDate: json['first_conversion_date'] != null
          ? DateTime.parse(json['first_conversion_date'] as String)
          : null,
      latestConversionDate: json['latest_conversion_date'] != null
          ? DateTime.parse(json['latest_conversion_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'staff_id': staffId,
      'staff_name': staffName,
      'staff_email': staffEmail,
      'role': role,
      'is_active': isActive,
      'total_leads_assigned': totalLeadsAssigned,
      'total_conversions': totalConversions,
      'conversion_rate': conversionRate,
      'conversions_this_month': conversionsThisMonth,
      'conversions_this_week': conversionsThisWeek,
      'avg_days_to_convert': avgDaysToConvert,
      'fastest_conversion_days': fastestConversionDays,
      'slowest_conversion_days': slowestConversionDays,
      'leads_by_status': leadsByStatus.toJson(),
      'first_conversion_date': firstConversionDate?.toIso8601String(),
      'latest_conversion_date': latestConversionDate?.toIso8601String(),
    };
  }
}

class LeadsByStatus {
  final int newLeads;
  final int contacted;
  final int qualified;
  final int converted;
  final int lost;

  LeadsByStatus({
    required this.newLeads,
    required this.contacted,
    required this.qualified,
    required this.converted,
    required this.lost,
  });

  factory LeadsByStatus.fromJson(Map<String, dynamic> json) {
    return LeadsByStatus(
      newLeads: json['new'] as int? ?? 0,
      contacted: json['contacted'] as int? ?? 0,
      qualified: json['qualified'] as int? ?? 0,
      converted: json['converted'] as int? ?? 0,
      lost: json['lost'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'new': newLeads,
      'contacted': contacted,
      'qualified': qualified,
      'converted': converted,
      'lost': lost,
    };
  }
}

class ReportSummary {
  final int totalStaff;
  final int totalConversions;
  final double avgConversionRate;
  final TopPerformer? topPerformer;

  ReportSummary({
    required this.totalStaff,
    required this.totalConversions,
    required this.avgConversionRate,
    this.topPerformer,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    return ReportSummary(
      totalStaff: json['total_staff'] as int? ?? 0,
      totalConversions: json['total_conversions'] as int? ?? 0,
      avgConversionRate: (json['avg_conversion_rate'] as num?)?.toDouble() ?? 0.0,
      topPerformer: json['top_performer'] != null
          ? TopPerformer.fromJson(json['top_performer'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_staff': totalStaff,
      'total_conversions': totalConversions,
      'avg_conversion_rate': avgConversionRate,
      'top_performer': topPerformer?.toJson(),
    };
  }
}

class TopPerformer {
  final String staffId;
  final String staffName;
  final int conversions;
  final double conversionRate;

  TopPerformer({
    required this.staffId,
    required this.staffName,
    required this.conversions,
    required this.conversionRate,
  });

  factory TopPerformer.fromJson(Map<String, dynamic> json) {
    return TopPerformer(
      staffId: json['staff_id'] as String,
      staffName: json['staff_name'] as String,
      conversions: json['conversions'] as int? ?? 0,
      conversionRate: (json['conversion_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'staff_id': staffId,
      'staff_name': staffName,
      'conversions': conversions,
      'conversion_rate': conversionRate,
    };
  }
}

class StaffPerformanceFilters {
  final String? dateFrom;
  final String? dateTo;
  final String? staffId;
  final String? role;

  StaffPerformanceFilters({
    this.dateFrom,
    this.dateTo,
    this.staffId,
    this.role,
  });

  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    if (dateFrom != null) params['date_from'] = dateFrom!;
    if (dateTo != null) params['date_to'] = dateTo!;
    if (staffId != null) params['staff_id'] = staffId!;
    if (role != null) params['role'] = role!;
    return params;
  }
}



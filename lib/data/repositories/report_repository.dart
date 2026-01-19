import '../models/report_model.dart';
import '../../core/services/supabase_service.dart';

class ReportRepository {

  /// Get staff performance statistics for a shop
  Future<List<StaffPerformanceStats>> getStaffPerformanceStats(
    String shopId, {
    StaffPerformanceFilters? filters,
  }) async {
    // Use direct query implementation
    // In production, you might want to use an Edge Function
    return _getStaffPerformanceStatsDirect(shopId, filters);
  }

  /// Direct implementation (fallback if Edge Function not available)
  Future<List<StaffPerformanceStats>> _getStaffPerformanceStatsDirect(
    String shopId,
    StaffPerformanceFilters? filters,
  ) async {
    // Get all staff members for the shop
    final staffResponse = await SupabaseService.from('staff')
        .select('id, name, email, role, is_active')
        .eq('shop_id', shopId)
        .order('name');

    if (staffResponse.isEmpty) return [];

    // Get all users (owners/admins) for the shop
    final usersResponse = await SupabaseService.from('users')
        .select('id, name, email, role, is_active')
        .eq('shop_id', shopId);

    // Combine staff and users
    final allStaff = [
      ...(staffResponse as List),
      ...(usersResponse as List),
    ];

    // Build date filters
    final dateFrom = filters?.dateFrom ?? '1970-01-01';
    final dateTo = filters?.dateTo ?? DateTime.now().toIso8601String().split('T')[0];

    // Get all conversion activities for the shop
    final conversionsResponse = await SupabaseService.from('lead_activities')
        .select('''
          id,
          lead_id,
          performed_by,
          created_at,
          metadata,
          lead:leads!lead_id(id, name, created_at)
        ''')
        .eq('shop_id', shopId)
        .eq('activity_type', 'status_change')
        .gte('created_at', '${dateFrom}T00:00:00.000Z')
        .lte('created_at', '${dateTo}T23:59:59.999Z');

    // Filter to only conversions (new_status = 'converted')
    final conversions = (conversionsResponse as List)
        .where((c) => (c['metadata'] as Map<String, dynamic>?)?['new_status'] == 'converted')
        .toList();

    // Get all leads for the shop
    final leadsResponse = await SupabaseService.from('leads')
        .select('id, name, status, assigned_to, created_at')
        .eq('shop_id', shopId)
        .isFilter('deleted_at', null);

    final allLeads = leadsResponse as List;

    // Calculate week and month boundaries
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final monthAgo = DateTime(now.year, now.month, 1);

    // Build stats for each staff member
    final stats = <StaffPerformanceStats>[];

    for (final staff in allStaff) {
      final staffId = staff['id'] as String;

      // Get leads assigned to this staff
      final assignedLeads = allLeads
          .where((l) => l['assigned_to'] == staffId)
          .toList();

      // Get conversions performed by this staff
      final staffConversions = conversions
          .where((c) => c['performed_by'] == staffId)
          .toList();

      // Calculate time-to-convert for each conversion
      final conversionTimes = <int>[];
      for (final conv in staffConversions) {
        final lead = conv['lead'] as Map<String, dynamic>?;
        if (lead != null && lead['created_at'] != null) {
          final leadCreated = DateTime.parse(lead['created_at'] as String);
          final conversionDate = DateTime.parse(conv['created_at'] as String);
          final days = conversionDate.difference(leadCreated).inDays;
          if (days >= 0) {
            conversionTimes.add(days);
          }
        }
      }

      // Calculate leads by status
      final leadsByStatus = LeadsByStatus(
        newLeads: assignedLeads.where((l) => l['status'] == 'new').length,
        contacted: assignedLeads.where((l) => l['status'] == 'contacted').length,
        qualified: assignedLeads.where((l) => l['status'] == 'qualified').length,
        converted: assignedLeads.where((l) => l['status'] == 'converted').length,
        lost: assignedLeads.where((l) => l['status'] == 'lost').length,
      );

      // Conversions this week/month
      final conversionsThisWeek = staffConversions
          .where((c) => DateTime.parse(c['created_at'] as String).isAfter(weekAgo))
          .length;
      final conversionsThisMonth = staffConversions
          .where((c) => DateTime.parse(c['created_at'] as String).isAfter(monthAgo))
          .length;

      // Get first and latest conversion dates
      final sortedConversions = List.from(staffConversions)
        ..sort((a, b) => DateTime.parse(a['created_at'] as String)
            .compareTo(DateTime.parse(b['created_at'] as String)));

      final conversionRate = assignedLeads.isNotEmpty
          ? (staffConversions.length / assignedLeads.length * 100 * 10).round() / 10
          : 0.0;

      stats.add(StaffPerformanceStats(
        staffId: staffId,
        staffName: staff['name'] as String,
        staffEmail: staff['email'] as String? ?? '',
        role: staff['role'] as String,
        isActive: staff['is_active'] as bool? ?? true,
        totalLeadsAssigned: assignedLeads.length,
        totalConversions: staffConversions.length,
        conversionRate: conversionRate,
        conversionsThisMonth: conversionsThisMonth,
        conversionsThisWeek: conversionsThisWeek,
        avgDaysToConvert: conversionTimes.isNotEmpty
            ? (conversionTimes.reduce((a, b) => a + b) / conversionTimes.length * 10).round() / 10
            : null,
        fastestConversionDays: conversionTimes.isNotEmpty ? conversionTimes.reduce((a, b) => a < b ? a : b) : null,
        slowestConversionDays: conversionTimes.isNotEmpty ? conversionTimes.reduce((a, b) => a > b ? a : b) : null,
        leadsByStatus: leadsByStatus,
        firstConversionDate: sortedConversions.isNotEmpty
            ? DateTime.parse(sortedConversions.first['created_at'] as String)
            : null,
        latestConversionDate: sortedConversions.isNotEmpty
            ? DateTime.parse(sortedConversions.last['created_at'] as String)
            : null,
      ));
    }

    // Apply filters
    var filteredStats = stats;
    if (filters?.staffId != null) {
      filteredStats = filteredStats.where((s) => s.staffId == filters!.staffId).toList();
    }
    if (filters?.role != null) {
      filteredStats = filteredStats.where((s) => s.role == filters!.role).toList();
    }

    return filteredStats;
  }

  /// Get summary statistics for reports dashboard
  Future<ReportSummary> getReportSummary(String shopId) async {
    final stats = await getStaffPerformanceStats(shopId);

    final totalConversions = stats.fold<int>(0, (sum, s) => sum + s.totalConversions);
    final totalLeads = stats.fold<int>(0, (sum, s) => sum + s.totalLeadsAssigned);
    final avgConversionRate = totalLeads > 0
        ? (totalConversions / totalLeads * 100 * 10).round() / 10
        : 0.0;

    // Find top performer by conversions
    final topPerformerStats = stats
        .where((s) => s.totalConversions > 0)
        .toList()
      ..sort((a, b) => b.totalConversions.compareTo(a.totalConversions));

    final topPerformer = topPerformerStats.isNotEmpty
        ? TopPerformer(
            staffId: topPerformerStats.first.staffId,
            staffName: topPerformerStats.first.staffName,
            conversions: topPerformerStats.first.totalConversions,
            conversionRate: topPerformerStats.first.conversionRate,
          )
        : null;

    return ReportSummary(
      totalStaff: stats.length,
      totalConversions: totalConversions,
      avgConversionRate: avgConversionRate,
      topPerformer: topPerformer,
    );
  }
}


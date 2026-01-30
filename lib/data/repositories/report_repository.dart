import '../models/report_model.dart';
import '../../core/services/supabase_service.dart';

/// Date range for leaderboard period. Matches website getDateRange().
({String dateFrom, String dateTo}) _getLeaderboardDateRange(LeaderboardPeriod period) {
  final now = DateTime.now();
  final toEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

  switch (period) {
    case LeaderboardPeriod.allTime:
      return (dateFrom: '1970-01-01', dateTo: _formatDate(toEnd));
    case LeaderboardPeriod.thisDay:
      final fromStart = DateTime(now.year, now.month, now.day, 0, 0, 0, 0);
      return (dateFrom: _formatDate(fromStart), dateTo: _formatDate(toEnd));
    case LeaderboardPeriod.thisWeek:
      final day = now.weekday; // 1 = Monday, 7 = Sunday
      final mondayOffset = 1 - day;
      final monday = DateTime(now.year, now.month, now.day + mondayOffset, 0, 0, 0, 0);
      return (dateFrom: _formatDate(monday), dateTo: _formatDate(toEnd));
    case LeaderboardPeriod.thisMonth:
      final firstDay = DateTime(now.year, now.month, 1);
      return (dateFrom: _formatDate(firstDay), dateTo: _formatDate(toEnd));
  }
}

String _formatDate(DateTime d) {
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

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

  /// Get conversion leaderboard (Closed Won count by staff). Visible to all roles.
  /// Matches website API logic: period filter and fallback computation.
  Future<List<LeaderboardEntry>> getConversionLeaderboard(
    String shopId, {
    LeaderboardPeriod period = LeaderboardPeriod.allTime,
  }) async {
    final range = _getLeaderboardDateRange(period);
    final dateFrom = range.dateFrom;
    final dateTo = range.dateTo;
    final isAllTime = dateFrom == '1970-01-01';
    final fromTs = DateTime.parse('${dateFrom}T00:00:00.000Z').millisecondsSinceEpoch;
    final toTs = DateTime.parse('${dateTo}T23:59:59.999Z').millisecondsSinceEpoch;

    // 1. Current closed_won/converted leads (not deleted). Support both website (closed_won) and app (converted).
    final leadsClosedWon = await SupabaseService.from('leads')
        .select('id, assigned_to')
        .eq('shop_id', shopId)
        .eq('status', 'closed_won')
        .isFilter('deleted_at', null);
    final leadsConverted = await SupabaseService.from('leads')
        .select('id, assigned_to')
        .eq('shop_id', shopId)
        .eq('status', 'converted')
        .isFilter('deleted_at', null);
    final leadsRaw = [
      ...(leadsClosedWon as List),
      ...(leadsConverted as List),
    ];
    // Deduplicate by id (in case both statuses exist)
    final seenIds = <String>{};
    final leads = (leadsRaw as List)
        .cast<Map<String, dynamic>>()
        .where((l) => seenIds.add(l['id'] as String))
        .toList();
    final leadIds = leads.map((l) => l['id'] as String).toList();

    if (leadIds.isEmpty) {
      // No closed_won leads; return all people with 0 count
      final staffRes = await SupabaseService.from('staff')
          .select('id, name, role')
          .eq('shop_id', shopId);
      final usersRes = await SupabaseService.from('users')
          .select('id, name, role')
          .eq('shop_id', shopId);
      final people = <Map<String, dynamic>>[
        ...(staffRes as List).cast<Map<String, dynamic>>(),
        ...(usersRes as List).cast<Map<String, dynamic>>(),
      ];
      return people.asMap().entries.map((e) {
        final p = e.value;
        return LeaderboardEntry(
          rank: e.key + 1,
          staffId: p['id'] as String,
          staffName: p['name'] as String? ?? '—',
          role: p['role'] as String? ?? 'Staff',
          conversions: 0,
        );
      }).toList();
    }

    // 2. Latest status_change to closed_won per lead (need metadata to filter new_status)
    final activitiesWithMeta = await SupabaseService.from('lead_activities')
        .select('lead_id, performed_by, created_at, metadata')
        .eq('shop_id', shopId)
        .eq('activity_type', 'status_change')
        .inFilter('lead_id', leadIds);

    final activitiesList = (activitiesWithMeta as List).cast<Map<String, dynamic>>();
    // Count both closed_won (website) and converted (app) status changes
    final closedWonActivities = activitiesList
        .where((a) {
          final newStatus = (a['metadata'] as Map<String, dynamic>?)?['new_status'] as String?;
          return newStatus == 'closed_won' || newStatus == 'converted';
        })
        .toList();

    final latestByLead = <String, ({String performedBy, String createdAt})>{};
    for (final a in closedWonActivities) {
      final leadId = a['lead_id'] as String?;
      final performedBy = a['performed_by'] as String?;
      final createdAt = a['created_at'] as String?;
      if (leadId == null || performedBy == null || createdAt == null) continue;
      final existing = latestByLead[leadId];
      if (existing == null || createdAt.compareTo(existing.createdAt) > 0) {
        latestByLead[leadId] = (performedBy: performedBy, createdAt: createdAt);
      }
    }

    final closedByCount = <String, int>{};
    for (final lead in leads) {
      final leadId = lead['id'] as String;
      final latest = latestByLead[leadId];
      final closedBy = latest?.performedBy ?? lead['assigned_to'] as String?;
      if (closedBy == null) continue;
      final closedAtStr = latest?.createdAt;
      final closedAt = closedAtStr != null ? DateTime.tryParse(closedAtStr)?.millisecondsSinceEpoch : null;
      final inRange = isAllTime
          ? (closedAt == null || (closedAt >= fromTs && closedAt <= toTs))
          : (closedAt != null && closedAt >= fromTs && closedAt <= toTs);
      if (inRange) {
        closedByCount[closedBy] = (closedByCount[closedBy] ?? 0) + 1;
      }
    }

    // 3. All people (staff + users) for shop
    final staffRes = await SupabaseService.from('staff')
        .select('id, name, role')
        .eq('shop_id', shopId);
    final usersRes = await SupabaseService.from('users')
        .select('id, name, role')
        .eq('shop_id', shopId);
    final people = <Map<String, dynamic>>[
      ...(staffRes as List).cast<Map<String, dynamic>>(),
      ...(usersRes as List).cast<Map<String, dynamic>>(),
    ];

    final withCount = people.map((p) {
      final id = p['id'] as String;
      return (
        id: id,
        name: p['name'] as String? ?? '—',
        role: p['role'] as String? ?? 'Staff',
        closedWonCount: closedByCount[id] ?? 0,
      );
    }).toList();
    withCount.sort((a, b) => b.closedWonCount.compareTo(a.closedWonCount));

    return withCount.asMap().entries.map((e) {
      return LeaderboardEntry(
        rank: e.key + 1,
        staffId: e.value.id,
        staffName: e.value.name,
        role: e.value.role,
        conversions: e.value.closedWonCount,
      );
    }).toList();
  }
}


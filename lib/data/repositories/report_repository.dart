import '../models/report_model.dart';
import '../../core/services/supabase_service.dart';

const _coordinatorRole = 'crm_coordinator';
const _goalDaily = 100;
const _goalWeekly = 600;
const _goalMonthly = 2400;
const _starPointsPerConversion = 10;

// Match website lib/leaderboard-constants.ts
const _leaderboardVisibleRoles = ['freelance', 'office_staff'];
const _pointEligibleRoles = ['freelance', 'office_staff'];
const _minClosesPerforming = 15; // Elite Closers
const _minClosesOnTrack = 12; // On Track (12–14)
const _minClosesSafetyFund = 3;
const _pointsPerClosedWon = 10;

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

    // Filter to only conversions (new_status = 'proposal_sent' - matches website)
    final conversions = (conversionsResponse as List)
        .where((c) => (c['metadata'] as Map<String, dynamic>?)?['new_status'] == 'proposal_sent')
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

      // Calculate leads by status (8 statuses - matches website)
      final leadsByStatus = LeadsByStatus(
        willContact: assignedLeads.where((l) => l['status'] == 'will_contact').length,
        needFollowUp: assignedLeads.where((l) => l['status'] == 'need_follow_up').length,
        appointmentScheduled: assignedLeads.where((l) => l['status'] == 'appointment_scheduled').length,
        proposalSent: assignedLeads.where((l) => l['status'] == 'proposal_sent').length,
        alreadyHas: assignedLeads.where((l) => l['status'] == 'already_has').length,
        noNeedNow: assignedLeads.where((l) => l['status'] == 'no_need_now').length,
        closedWon: assignedLeads.where((l) => l['status'] == 'closed_won').length,
        closedLost: assignedLeads.where((l) => l['status'] == 'closed_lost').length,
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

  /// Get conversion leaderboard (Sales Accountability). Visible to all roles.
  /// Matches website API: only freelance/office_staff, points, status, safety fund.
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
    final now = DateTime.now();
    final monthFrom = DateTime(now.year, now.month, 1);
    final monthTo = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    final monthFromTs = monthFrom.millisecondsSinceEpoch;
    final monthToTs = monthTo.millisecondsSinceEpoch;

    // 1. All people (staff + users) for shop; only visible roles (freelance, office_staff)
    final staffRes = await SupabaseService.from('staff')
        .select('id, name, role')
        .eq('shop_id', shopId);
    final usersRes = await SupabaseService.from('users')
        .select('id, name, role')
        .eq('shop_id', shopId);
    final allPeople = <Map<String, dynamic>>[
      ...(staffRes as List).cast<Map<String, dynamic>>(),
      ...(usersRes as List).cast<Map<String, dynamic>>(),
    ];
    final people = allPeople
        .where((p) => _leaderboardVisibleRoles.contains(p['role'] as String? ?? ''))
        .toList();

    if (people.isEmpty) return [];

    // 2. Leads: assigned_to, status (for aggregation)
    final leadsData = await SupabaseService.from('leads')
        .select('assigned_to, status')
        .eq('shop_id', shopId)
        .isFilter('deleted_at', null) as List<dynamic>? ?? [];
    final leadsList = leadsData.cast<Map<String, dynamic>>();
    final assignedAgg = <String, ({int total, int proposalSent, int closedWon})>{};
    for (final p in people) {
      final id = p['id'] as String;
      assignedAgg[id] = (total: 0, proposalSent: 0, closedWon: 0);
    }
    for (final lead in leadsList) {
      final id = lead['assigned_to'] as String?;
      if (id == null || !assignedAgg.containsKey(id)) continue;
      final agg = assignedAgg[id]!;
      assignedAgg[id] = (
        total: agg.total + 1,
        proposalSent: agg.proposalSent + (lead['status'] == 'proposal_sent' ? 1 : 0),
        closedWon: agg.closedWon + (lead['status'] == 'closed_won' ? 1 : 0),
      );
    }

    // 3. Closed won leads and status_change activities for period / this month
    final leadsClosedWon = await SupabaseService.from('leads')
        .select('id, assigned_to')
        .eq('shop_id', shopId)
        .eq('status', 'closed_won')
        .isFilter('deleted_at', null) as List<dynamic>? ?? [];
    final leadIds = leadsClosedWon.cast<Map<String, dynamic>>().map((l) => l['id'] as String).toList();
    Map<String, int> closedInPeriod = {};
    Map<String, int> closedThisMonth = {};
    for (final p in people) {
      closedInPeriod[p['id'] as String] = 0;
      closedThisMonth[p['id'] as String] = 0;
    }
    if (leadIds.isNotEmpty) {
      final activitiesWithMeta = await SupabaseService.from('lead_activities')
          .select('lead_id, performed_by, created_at, metadata')
          .eq('shop_id', shopId)
          .eq('activity_type', 'status_change')
          .inFilter('lead_id', leadIds) as List<dynamic>? ?? [];
      final activitiesList = activitiesWithMeta.cast<Map<String, dynamic>>();
      final closedWonActivities = activitiesList
          .where((a) {
            final newStatus = (a['metadata'] as Map<String, dynamic>?)?['new_status'] as String?;
            return newStatus == 'closed_won' || newStatus == 'converted';
          })
          .toList();
      final latestByLead = <String, ({String performedBy, String createdAt})>{};
      for (final a in closedWonActivities) {
        final lid = a['lead_id'] as String?;
        final performedBy = a['performed_by'] as String?;
        final createdAt = a['created_at'] as String?;
        if (lid == null || performedBy == null || createdAt == null) continue;
        final existing = latestByLead[lid];
        if (existing == null || createdAt.compareTo(existing.createdAt) > 0) {
          latestByLead[lid] = (performedBy: performedBy, createdAt: createdAt);
        }
      }
      final leadsListCw = leadsClosedWon.cast<Map<String, dynamic>>();
      for (final lead in leadsListCw) {
        final lid = lead['id'] as String;
        final latest = latestByLead[lid];
        final closedBy = latest?.performedBy ?? lead['assigned_to'] as String?;
        if (closedBy == null || !closedInPeriod.containsKey(closedBy)) continue;
        final closedAtStr = latest?.createdAt;
        final closedAt = closedAtStr != null ? DateTime.tryParse(closedAtStr)?.millisecondsSinceEpoch : null;
        final inPeriod = isAllTime
            ? (closedAt == null || (closedAt >= fromTs && closedAt <= toTs))
            : (closedAt != null && closedAt >= fromTs && closedAt <= toTs);
        final inMonth = closedAt != null && closedAt >= monthFromTs && closedAt <= monthToTs;
        if (inPeriod) closedInPeriod[closedBy] = closedInPeriod[closedBy]! + 1;
        if (inMonth) closedThisMonth[closedBy] = closedThisMonth[closedBy]! + 1;
      }
    }

    // 4. Build rows (match website)
    final rows = people.map((p) {
      final id = p['id'] as String;
      final role = p['role'] as String? ?? 'Staff';
      final agg = assignedAgg[id]!;
      final totalAssigned = agg.total;
      final proposalSent = agg.proposalSent;
      final closedWonAllTime = agg.closedWon;
      final closedWonPeriod = closedInPeriod[id] ?? 0;
      final closedWonThisMonth = closedThisMonth[id] ?? 0;
      final conversionRate = totalAssigned == 0
          ? 0.0
          : ((proposalSent + closedWonAllTime) / totalAssigned * 1000).round() / 10;
      final points = _getPoints(closedWonPeriod, role);
      final status = _getPerformanceStatus(closedWonThisMonth, role);
      final safetyFundEligible = _isSafetyFundEligible(closedWonThisMonth, role);
      return LeaderboardEntry(
        rank: 0,
        staffId: id,
        staffName: p['name'] as String? ?? '—',
        role: role,
        conversions: closedWonPeriod,
        totalAssignedLeads: totalAssigned,
        proposalSent: proposalSent,
        conversionRate: conversionRate,
        points: points,
        status: status,
        safetyFundEligible: safetyFundEligible,
      );
    }).toList();

    rows.sort((a, b) {
      if (b.points != a.points) return b.points.compareTo(a.points);
      if (b.conversions != a.conversions) return b.conversions.compareTo(a.conversions);
      return b.conversionRate.compareTo(a.conversionRate);
    });
    return rows.asMap().entries.map((e) {
      final r = e.value;
      return LeaderboardEntry(
        rank: e.key + 1,
        staffId: r.staffId,
        staffName: r.staffName,
        role: r.role,
        conversions: r.conversions,
        totalAssignedLeads: r.totalAssignedLeads,
        proposalSent: r.proposalSent,
        conversionRate: r.conversionRate,
        points: r.points,
        status: r.status,
        safetyFundEligible: r.safetyFundEligible,
      );
    }).toList();
  }

  static int _getPoints(int closedWon, String role) {
    if (!_pointEligibleRoles.contains(role)) return 0;
    return closedWon * _pointsPerClosedWon;
  }

  static String? _getPerformanceStatus(int closedWonThisMonth, String role) {
    if (!_pointEligibleRoles.contains(role)) return null;
    if (closedWonThisMonth >= _minClosesPerforming) return 'Elite Closers';
    if (closedWonThisMonth >= _minClosesOnTrack) return 'On Track';
    return 'Needs Improvement';
  }

  static bool? _isSafetyFundEligible(int closedWonThisMonth, String role) {
    if (!_pointEligibleRoles.contains(role)) return null;
    return closedWonThisMonth >= _minClosesSafetyFund;
  }

  // ——— Coordinator (crm_coordinator) ———

  static ({String from, String to}) _getCoordinatorDayRange() {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day, 0, 0, 0, 0);
    final to = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    return (from: from.toIso8601String(), to: to.toIso8601String());
  }

  static ({String from, String to}) _getCoordinatorWeekRange() {
    final now = DateTime.now();
    final day = now.weekday; // 1 = Monday, 7 = Sunday
    final mondayOffset = 1 - day;
    final monday = DateTime(now.year, now.month, now.day + mondayOffset, 0, 0, 0, 0);
    final sunday = DateTime(monday.year, monday.month, monday.day + 6, 23, 59, 59, 999);
    return (from: monday.toIso8601String(), to: sunday.toIso8601String());
  }

  static ({String from, String to}) _getCoordinatorMonthRange() {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, 1, 0, 0, 0, 0);
    final to = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
    return (from: from.toIso8601String(), to: to.toIso8601String());
  }

  /// Coordinator stats: goals (100/600/2400), points per period, star points.
  /// Only valid when current user is crm_coordinator. Matches website coordinator-stats API.
  Future<CoordinatorStats> getCoordinatorStats(String shopId, String coordinatorId) async {
    final day = _getCoordinatorDayRange();
    final week = _getCoordinatorWeekRange();
    final month = _getCoordinatorMonthRange();

    final dailyList = await SupabaseService.from('leads').select('id').eq('shop_id', shopId).eq('created_by', coordinatorId).isFilter('deleted_at', null).gte('created_at', day.from).lte('created_at', day.to) as List<dynamic>? ?? [];
    final weeklyList = await SupabaseService.from('leads').select('id').eq('shop_id', shopId).eq('created_by', coordinatorId).isFilter('deleted_at', null).gte('created_at', week.from).lte('created_at', week.to) as List<dynamic>? ?? [];
    final monthlyList = await SupabaseService.from('leads').select('id').eq('shop_id', shopId).eq('created_by', coordinatorId).isFilter('deleted_at', null).gte('created_at', month.from).lte('created_at', month.to) as List<dynamic>? ?? [];
    final allTimeList = await SupabaseService.from('leads').select('id').eq('shop_id', shopId).eq('created_by', coordinatorId).isFilter('deleted_at', null) as List<dynamic>? ?? [];
    final convertedList = await SupabaseService.from('leads').select('id').eq('shop_id', shopId).eq('created_by', coordinatorId).eq('status', 'closed_won').isFilter('deleted_at', null) as List<dynamic>? ?? [];

    final dailyCount = dailyList.length;
    final weeklyCount = weeklyList.length;
    final monthlyCount = monthlyList.length;
    final allTimeCount = allTimeList.length;
    final converted = convertedList.length;

    final starPoints = converted * _starPointsPerConversion;
    final dailyPercent = _goalDaily > 0 ? (dailyCount / _goalDaily * 100).round().clamp(0, 100) : 0;
    final weeklyPercent = _goalWeekly > 0 ? (weeklyCount / _goalWeekly * 100).round().clamp(0, 100) : 0;
    final monthlyPercent = _goalMonthly > 0 ? (monthlyCount / _goalMonthly * 100).round().clamp(0, 100) : 0;

    return CoordinatorStats(
      goals: {'daily': _goalDaily, 'weekly': _goalWeekly, 'monthly': _goalMonthly},
      points: {'daily': dailyCount, 'weekly': weeklyCount, 'monthly': monthlyCount, 'allTime': allTimeCount},
      percent: {'daily': dailyPercent, 'weekly': weeklyPercent, 'monthly': monthlyPercent},
      converted: converted,
      starPoints: starPoints,
    );
  }

  /// Coordinator leaderboard: staff with role crm_coordinator, ranked by ordinary points (leads added).
  /// Matches website GET /api/reports/coordinator-leaderboard. Only coordinators see this.
  Future<List<CoordinatorLeaderboardEntry>> getCoordinatorLeaderboard(
    String shopId, {
    CoordinatorLeaderboardPeriod period = CoordinatorLeaderboardPeriod.monthly,
  }) async {
    final coordinatorsRes = await SupabaseService.from('staff')
        .select('id, name')
        .eq('shop_id', shopId)
        .eq('role', _coordinatorRole);
    final coordinators = (coordinatorsRes as List).cast<Map<String, dynamic>>();
    if (coordinators.isEmpty) return [];

    final coordinatorIds = coordinators.map((c) => c['id'] as String).toList();
    final nameById = {for (final c in coordinators) c['id'] as String: c['name'] as String? ?? '—'};

    String? from;
    String? to;
    switch (period) {
      case CoordinatorLeaderboardPeriod.allTime:
        from = '1970-01-01T00:00:00.000Z';
        to = DateTime.now().toIso8601String();
        break;
      case CoordinatorLeaderboardPeriod.daily:
        final r = _getCoordinatorDayRange();
        from = r.from;
        to = r.to;
        break;
      case CoordinatorLeaderboardPeriod.weekly:
        final r = _getCoordinatorWeekRange();
        from = r.from;
        to = r.to;
        break;
      case CoordinatorLeaderboardPeriod.monthly:
        final r = _getCoordinatorMonthRange();
        from = r.from;
        to = r.to;
        break;
    }

    final leadsInPeriod = await SupabaseService.from('leads')
        .select('created_by')
        .eq('shop_id', shopId)
        .inFilter('created_by', coordinatorIds)
        .isFilter('deleted_at', null)
        .gte('created_at', from)
        .lte('created_at', to) as List<dynamic>? ?? [];
    final ordinaryByCreator = <String, int>{};
    for (final id in coordinatorIds) {
      ordinaryByCreator[id] = 0;
    }
    for (final row in leadsInPeriod.cast<Map<String, dynamic>>()) {
      final createdBy = row['created_by'] as String?;
      if (createdBy != null && ordinaryByCreator.containsKey(createdBy)) {
        ordinaryByCreator[createdBy] = ordinaryByCreator[createdBy]! + 1;
      }
    }

    final closedLeads = await SupabaseService.from('leads')
        .select('created_by')
        .eq('shop_id', shopId)
        .eq('status', 'closed_won')
        .isFilter('deleted_at', null)
        .inFilter('created_by', coordinatorIds) as List<dynamic>? ?? [];
    final convertedByCreator = <String, int>{};
    for (final id in coordinatorIds) {
      convertedByCreator[id] = 0;
    }
    for (final row in closedLeads.cast<Map<String, dynamic>>()) {
      final createdBy = row['created_by'] as String?;
      if (createdBy != null && convertedByCreator.containsKey(createdBy)) {
        convertedByCreator[createdBy] = convertedByCreator[createdBy]! + 1;
      }
    }

    final rows = coordinatorIds.map((id) {
      final ordinary = ordinaryByCreator[id] ?? 0;
      final converted = convertedByCreator[id] ?? 0;
      return CoordinatorLeaderboardEntry(
        rank: 0,
        staffId: id,
        staffName: nameById[id] ?? '—',
        totalLeads: ordinary,
        converted: converted,
        starPoints: converted * _starPointsPerConversion,
        ordinaryPoints: ordinary,
      );
    }).toList();
    rows.sort((a, b) => b.ordinaryPoints.compareTo(a.ordinaryPoints));
    return rows.asMap().entries.map((e) {
      final r = e.value;
      return CoordinatorLeaderboardEntry(
        rank: e.key + 1,
        staffId: r.staffId,
        staffName: r.staffName,
        totalLeads: r.totalLeads,
        converted: r.converted,
        starPoints: r.starPoints,
        ordinaryPoints: r.ordinaryPoints,
      );
    }).toList();
  }
}


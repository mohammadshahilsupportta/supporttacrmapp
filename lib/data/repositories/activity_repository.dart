import '../models/activity_model.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/helpers.dart';

class ActivityRepository {
  // Get all activities for a lead
  Future<List<LeadActivity>> findByLeadId(String leadId) async {
    try {
      List<dynamic> data;
      try {
        // First try: Join with staff table for performed_by and assigned_to
        data =
            await SupabaseService.from('lead_activities')
                    .select('''
              *,
              performed_by_user:staff!performed_by(id, name, email),
              assigned_to_user:staff!assigned_to(id, name, email)
            ''')
                    .eq('lead_id', leadId)
                    .order('created_at', ascending: false)
                as List<dynamic>? ??
            [];
      } catch (e) {
        try {
          // Second try: Join with users table
          data =
              await SupabaseService.from('lead_activities')
                      .select('''
                *,
                performed_by_user:users!performed_by(id, name, email),
                assigned_to_user:users!assigned_to(id, name, email)
              ''')
                      .eq('lead_id', leadId)
                      .order('created_at', ascending: false)
                  as List<dynamic>? ??
              [];
        } catch (e2) {
          // Fallback: query without user relationships, fetch them separately
          data =
              await SupabaseService.from('lead_activities')
                      .select('*')
                      .eq('lead_id', leadId)
                      .order('created_at', ascending: false)
                  as List<dynamic>? ??
              [];

          // Fetch user data separately for performed_by and assigned_to
          final performedByIds = data
              .map(
                (a) => (a as Map<String, dynamic>)['performed_by'] as String?,
              )
              .whereType<String>()
              .toSet()
              .toList();
          final assignedToIds = data
              .map((a) => (a as Map<String, dynamic>)['assigned_to'] as String?)
              .whereType<String>()
              .toSet()
              .toList();

          Map<String, Map<String, dynamic>> performedByUsersMap = {};
          Map<String, Map<String, dynamic>> assignedToUsersMap = {};

          // Try fetching from staff table first, then fallback to users table
          for (final userId in performedByIds) {
            try {
              var user = await SupabaseService.from(
                'staff',
              ).select('id, name, email').eq('id', userId).maybeSingle();
              user ??= await SupabaseService.from(
                'users',
              ).select('id, name, email').eq('id', userId).maybeSingle();
              if (user != null) {
                performedByUsersMap[userId] = Map<String, dynamic>.from(user);
              }
            } catch (e3) {
              continue;
            }
          }

          for (final userId in assignedToIds) {
            try {
              var user = await SupabaseService.from(
                'staff',
              ).select('id, name, email').eq('id', userId).maybeSingle();
              user ??= await SupabaseService.from(
                'users',
              ).select('id, name, email').eq('id', userId).maybeSingle();
              if (user != null) {
                assignedToUsersMap[userId] = Map<String, dynamic>.from(user);
              }
            } catch (e4) {
              continue;
            }
          }

          // Merge user data into activities
          for (var activity in data) {
            final activityMap = activity as Map<String, dynamic>;
            final performedBy = activityMap['performed_by'] as String?;
            final assignedTo = activityMap['assigned_to'] as String?;

            if (performedBy != null &&
                performedByUsersMap.containsKey(performedBy)) {
              activityMap['performed_by_user'] =
                  performedByUsersMap[performedBy];
            }
            if (assignedTo != null &&
                assignedToUsersMap.containsKey(assignedTo)) {
              activityMap['assigned_to_user'] = assignedToUsersMap[assignedTo];
            }
          }
        }
      }

      return data
          .map((json) => LeadActivity.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }

  // Get a single activity by ID
  Future<LeadActivity?> findById(String id) async {
    try {
      Map<String, dynamic>? data;
      try {
        // First try: Join with staff table
        data = await SupabaseService.from('lead_activities')
            .select('''
              *,
              performed_by_user:staff!performed_by(id, name, email),
              assigned_to_user:staff!assigned_to(id, name, email)
            ''')
            .eq('id', id)
            .maybeSingle();
      } catch (e) {
        try {
          // Second try: Join with users table
          data = await SupabaseService.from('lead_activities')
              .select('''
                *,
                performed_by_user:users!performed_by(id, name, email),
                assigned_to_user:users!assigned_to(id, name, email)
              ''')
              .eq('id', id)
              .maybeSingle();
        } catch (e2) {
          // Fallback: query without user relationships
          data = await SupabaseService.from(
            'lead_activities',
          ).select('*').eq('id', id).maybeSingle();

          // Fetch user data separately if needed
          if (data != null) {
            final performedBy = data['performed_by'] as String?;
            final assignedTo = data['assigned_to'] as String?;

            if (performedBy != null) {
              var user = await SupabaseService.from(
                'staff',
              ).select('id, name, email').eq('id', performedBy).maybeSingle();
              user ??= await SupabaseService.from(
                'users',
              ).select('id, name, email').eq('id', performedBy).maybeSingle();
              if (user != null) {
                data['performed_by_user'] = user;
              }
            }

            if (assignedTo != null) {
              var user = await SupabaseService.from(
                'staff',
              ).select('id, name, email').eq('id', assignedTo).maybeSingle();
              user ??= await SupabaseService.from(
                'users',
              ).select('id, name, email').eq('id', assignedTo).maybeSingle();
              if (user != null) {
                data['assigned_to_user'] = user;
              }
            }
          }
        }
      }

      if (data == null) return null;
      return LeadActivity.fromJson(data);
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }

  // Create a new activity
  Future<LeadActivity> create(
    String leadId,
    String shopId,
    CreateActivityInput input,
    String performedBy,
  ) async {
    try {
      final activityData = input.toJson();
      activityData['lead_id'] = leadId;
      activityData['shop_id'] = shopId;
      activityData['performed_by'] = performedBy;

      // For tasks, set task_status to 'pending' by default if not provided
      if (input.activityType == ActivityType.task &&
          !activityData.containsKey('task_status')) {
        activityData['task_status'] = 'pending';
      }

      Map<String, dynamic> data;
      try {
        // First try: Join with staff table
        data = await SupabaseService.from('lead_activities')
            .insert(activityData)
            .select('''
              *,
              performed_by_user:staff!performed_by(id, name, email),
              assigned_to_user:staff!assigned_to(id, name, email)
            ''')
            .single();
      } catch (e) {
        try {
          // Second try: Join with users table
          data = await SupabaseService.from('lead_activities')
              .insert(activityData)
              .select('''
                *,
                performed_by_user:users!performed_by(id, name, email),
                assigned_to_user:users!assigned_to(id, name, email)
              ''')
              .single();
        } catch (e2) {
          // Fallback: insert without user relationships, then fetch separately
          data = await SupabaseService.from(
            'lead_activities',
          ).insert(activityData).select('*').single();

          // Fetch user data separately
          final performedBy = data['performed_by'] as String?;
          final assignedTo = data['assigned_to'] as String?;

          if (performedBy != null) {
            var user = await SupabaseService.from(
              'staff',
            ).select('id, name, email').eq('id', performedBy).maybeSingle();
            user ??= await SupabaseService.from(
              'users',
            ).select('id, name, email').eq('id', performedBy).maybeSingle();
            if (user != null) {
              data['performed_by_user'] = user;
            }
          }

          if (assignedTo != null) {
            var user = await SupabaseService.from(
              'staff',
            ).select('id, name, email').eq('id', assignedTo).maybeSingle();
            user ??= await SupabaseService.from(
              'users',
            ).select('id, name, email').eq('id', assignedTo).maybeSingle();
            if (user != null) {
              data['assigned_to_user'] = user;
            }
          }
        }
      }

      return LeadActivity.fromJson(data);
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }

  // Update an activity
  Future<LeadActivity> update(String id, UpdateActivityInput input) async {
    try {
      final updateData = input.toJson();

      // If marking as completed, set completed_at if not provided
      if (input.taskStatus == TaskStatus.completed &&
          input.completedAt == null) {
        updateData['completed_at'] = DateTime.now().toIso8601String();
      }

      Map<String, dynamic> data;
      try {
        // First try: Join with staff table
        data = await SupabaseService.from('lead_activities')
            .update(updateData)
            .eq('id', id)
            .select('''
              *,
              performed_by_user:staff!performed_by(id, name, email),
              assigned_to_user:staff!assigned_to(id, name, email)
            ''')
            .single();
      } catch (e) {
        try {
          // Second try: Join with users table
          data = await SupabaseService.from('lead_activities')
              .update(updateData)
              .eq('id', id)
              .select('''
                *,
                performed_by_user:users!performed_by(id, name, email),
                assigned_to_user:users!assigned_to(id, name, email)
              ''')
              .single();
        } catch (e2) {
          // Fallback: update without user relationships, then fetch separately
          data = await SupabaseService.from(
            'lead_activities',
          ).update(updateData).eq('id', id).select('*').single();

          // Fetch user data separately
          final performedBy = data['performed_by'] as String?;
          final assignedTo = data['assigned_to'] as String?;

          if (performedBy != null) {
            var user = await SupabaseService.from(
              'staff',
            ).select('id, name, email').eq('id', performedBy).maybeSingle();
            user ??= await SupabaseService.from(
              'users',
            ).select('id, name, email').eq('id', performedBy).maybeSingle();
            if (user != null) {
              data['performed_by_user'] = user;
            }
          }

          if (assignedTo != null) {
            var user = await SupabaseService.from(
              'staff',
            ).select('id, name, email').eq('id', assignedTo).maybeSingle();
            user ??= await SupabaseService.from(
              'users',
            ).select('id, name, email').eq('id', assignedTo).maybeSingle();
            if (user != null) {
              data['assigned_to_user'] = user;
            }
          }
        }
      }

      return LeadActivity.fromJson(data);
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }

  // Delete an activity
  Future<void> delete(String id) async {
    try {
      await SupabaseService.from('lead_activities').delete().eq('id', id);
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }

  // Get pending tasks for a lead
  Future<List<LeadActivity>> findPendingTasks(String leadId) async {
    try {
      List<dynamic> data;
      try {
        // First try: Join with staff table
        data =
            await SupabaseService.from('lead_activities')
                    .select('''
              *,
              performed_by_user:staff!performed_by(id, name, email),
              assigned_to_user:staff!assigned_to(id, name, email)
            ''')
                    .eq('lead_id', leadId)
                    .eq('activity_type', 'task')
                    .filter('task_status', 'in', '("pending","in_progress")')
                    .order('created_at', ascending: false)
                as List<dynamic>? ??
            [];
      } catch (e) {
        try {
          // Second try: Join with users table
          data =
              await SupabaseService.from('lead_activities')
                      .select('''
                *,
                performed_by_user:users!performed_by(id, name, email),
                assigned_to_user:users!assigned_to(id, name, email)
              ''')
                      .eq('lead_id', leadId)
                      .eq('activity_type', 'task')
                      .filter('task_status', 'in', '("pending","in_progress")')
                      .order('created_at', ascending: false)
                  as List<dynamic>? ??
              [];
        } catch (e2) {
          // Fallback: query without user relationships
          data =
              await SupabaseService.from('lead_activities')
                      .select('*')
                      .eq('lead_id', leadId)
                      .eq('activity_type', 'task')
                      .filter('task_status', 'in', '("pending","in_progress")')
                      .order('created_at', ascending: false)
                  as List<dynamic>? ??
              [];

          // Fetch user data separately (similar to findByLeadId)
          final performedByIds = data
              .map(
                (a) => (a as Map<String, dynamic>)['performed_by'] as String?,
              )
              .whereType<String>()
              .toSet()
              .toList();
          final assignedToIds = data
              .map((a) => (a as Map<String, dynamic>)['assigned_to'] as String?)
              .whereType<String>()
              .toSet()
              .toList();

          Map<String, Map<String, dynamic>> performedByUsersMap = {};
          Map<String, Map<String, dynamic>> assignedToUsersMap = {};

          for (final userId in performedByIds) {
            try {
              var user = await SupabaseService.from(
                'staff',
              ).select('id, name, email').eq('id', userId).maybeSingle();
              user ??= await SupabaseService.from(
                'users',
              ).select('id, name, email').eq('id', userId).maybeSingle();
              if (user != null) {
                performedByUsersMap[userId] = Map<String, dynamic>.from(user);
              }
            } catch (e3) {
              continue;
            }
          }

          for (final userId in assignedToIds) {
            try {
              var user = await SupabaseService.from(
                'staff',
              ).select('id, name, email').eq('id', userId).maybeSingle();
              user ??= await SupabaseService.from(
                'users',
              ).select('id, name, email').eq('id', userId).maybeSingle();
              if (user != null) {
                assignedToUsersMap[userId] = Map<String, dynamic>.from(user);
              }
            } catch (e4) {
              continue;
            }
          }

          for (var activity in data) {
            final activityMap = activity as Map<String, dynamic>;
            final performedBy = activityMap['performed_by'] as String?;
            final assignedTo = activityMap['assigned_to'] as String?;

            if (performedBy != null &&
                performedByUsersMap.containsKey(performedBy)) {
              activityMap['performed_by_user'] =
                  performedByUsersMap[performedBy];
            }
            if (assignedTo != null &&
                assignedToUsersMap.containsKey(assignedTo)) {
              activityMap['assigned_to_user'] = assignedToUsersMap[assignedTo];
            }
          }
        }
      }

      return data
          .map((json) => LeadActivity.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }

  // Get upcoming scheduled items (tasks and meetings)
  Future<List<LeadActivity>> findUpcomingScheduled(
    String leadId, {
    int limit = 10,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      List<dynamic> data;

      try {
        // First try: Join with staff table
        data =
            await SupabaseService.from('lead_activities')
                    .select('''
              *,
              performed_by_user:staff!performed_by(id, name, email),
              assigned_to_user:staff!assigned_to(id, name, email)
            ''')
                    .eq('lead_id', leadId)
                    .filter('activity_type', 'in', '("task","meeting")')
                    .or('due_date.gte.$now,scheduled_at.gte.$now')
                    .order('scheduled_at', ascending: true)
                    .order('due_date', ascending: true)
                    .limit(limit)
                as List<dynamic>? ??
            [];
      } catch (e) {
        try {
          // Second try: Join with users table
          data =
              await SupabaseService.from('lead_activities')
                      .select('''
                *,
                performed_by_user:users!performed_by(id, name, email),
                assigned_to_user:users!assigned_to(id, name, email)
              ''')
                      .eq('lead_id', leadId)
                      .filter('activity_type', 'in', '("task","meeting")')
                      .or('due_date.gte.$now,scheduled_at.gte.$now')
                      .order('scheduled_at', ascending: true)
                      .order('due_date', ascending: true)
                      .limit(limit)
                  as List<dynamic>? ??
              [];
        } catch (e2) {
          // Fallback: query without user relationships
          data =
              await SupabaseService.from('lead_activities')
                      .select('*')
                      .eq('lead_id', leadId)
                      .filter('activity_type', 'in', '("task","meeting")')
                      .or('due_date.gte.$now,scheduled_at.gte.$now')
                      .order('scheduled_at', ascending: true)
                      .order('due_date', ascending: true)
                      .limit(limit)
                  as List<dynamic>? ??
              [];

          // Fetch user data separately (similar to findByLeadId)
          final performedByIds = data
              .map(
                (a) => (a as Map<String, dynamic>)['performed_by'] as String?,
              )
              .whereType<String>()
              .toSet()
              .toList();
          final assignedToIds = data
              .map((a) => (a as Map<String, dynamic>)['assigned_to'] as String?)
              .whereType<String>()
              .toSet()
              .toList();

          Map<String, Map<String, dynamic>> performedByUsersMap = {};
          Map<String, Map<String, dynamic>> assignedToUsersMap = {};

          for (final userId in performedByIds) {
            try {
              var user = await SupabaseService.from(
                'staff',
              ).select('id, name, email').eq('id', userId).maybeSingle();
              user ??= await SupabaseService.from(
                'users',
              ).select('id, name, email').eq('id', userId).maybeSingle();
              if (user != null) {
                performedByUsersMap[userId] = Map<String, dynamic>.from(user);
              }
            } catch (e3) {
              continue;
            }
          }

          for (final userId in assignedToIds) {
            try {
              var user = await SupabaseService.from(
                'staff',
              ).select('id, name, email').eq('id', userId).maybeSingle();
              user ??= await SupabaseService.from(
                'users',
              ).select('id, name, email').eq('id', userId).maybeSingle();
              if (user != null) {
                assignedToUsersMap[userId] = Map<String, dynamic>.from(user);
              }
            } catch (e4) {
              continue;
            }
          }

          for (var activity in data) {
            final activityMap = activity as Map<String, dynamic>;
            final performedBy = activityMap['performed_by'] as String?;
            final assignedTo = activityMap['assigned_to'] as String?;

            if (performedBy != null &&
                performedByUsersMap.containsKey(performedBy)) {
              activityMap['performed_by_user'] =
                  performedByUsersMap[performedBy];
            }
            if (assignedTo != null &&
                assignedToUsersMap.containsKey(assignedTo)) {
              activityMap['assigned_to_user'] = assignedToUsersMap[assignedTo];
            }
          }
        }
      }

      return data
          .map((json) => LeadActivity.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }

  /// Get all tasks assigned to a specific user across all leads in a shop
  /// Used for the My Tasks calendar view
  Future<List<LeadActivity>> findMyTasks(
    String shopId,
    String userId, {
    bool includeCompleted = false,
  }) async {
    try {
      List<dynamic> data;

      // Build status filter
      final statusFilter = includeCompleted
          ? '("pending","in_progress","completed")'
          : '("pending","in_progress")';

      try {
        // First try: Join with staff table and leads table
        data =
            await SupabaseService.from('lead_activities')
                    .select('''
              *,
              performed_by_user:staff!performed_by(id, name, email),
              assigned_to_user:staff!assigned_to(id, name, email),
              lead:leads!lead_id(id, name)
            ''')
                    .eq('shop_id', shopId)
                    .eq('activity_type', 'task')
                    .eq('assigned_to', userId)
                    .filter('task_status', 'in', statusFilter)
                    .order('due_date', ascending: true, nullsFirst: false)
                    .order('created_at', ascending: false)
                as List<dynamic>? ??
            [];
      } catch (e) {
        try {
          // Second try: Join with users table
          data =
              await SupabaseService.from('lead_activities')
                      .select('''
                *,
                performed_by_user:users!performed_by(id, name, email),
                assigned_to_user:users!assigned_to(id, name, email),
                lead:leads!lead_id(id, name)
              ''')
                      .eq('shop_id', shopId)
                      .eq('activity_type', 'task')
                      .eq('assigned_to', userId)
                      .filter('task_status', 'in', statusFilter)
                      .order('due_date', ascending: true, nullsFirst: false)
                      .order('created_at', ascending: false)
                  as List<dynamic>? ??
              [];
        } catch (e2) {
          // Fallback: query without user relationships
          data =
              await SupabaseService.from('lead_activities')
                      .select('''
                *,
                lead:leads!lead_id(id, name)
              ''')
                      .eq('shop_id', shopId)
                      .eq('activity_type', 'task')
                      .eq('assigned_to', userId)
                      .filter('task_status', 'in', statusFilter)
                      .order('due_date', ascending: true, nullsFirst: false)
                      .order('created_at', ascending: false)
                  as List<dynamic>? ??
              [];

          // Fetch user data separately
          final performedByIds = data
              .map(
                (a) => (a as Map<String, dynamic>)['performed_by'] as String?,
              )
              .whereType<String>()
              .toSet()
              .toList();
          final assignedToIds = data
              .map((a) => (a as Map<String, dynamic>)['assigned_to'] as String?)
              .whereType<String>()
              .toSet()
              .toList();

          Map<String, Map<String, dynamic>> performedByUsersMap = {};
          Map<String, Map<String, dynamic>> assignedToUsersMap = {};

          for (final uid in performedByIds) {
            try {
              var user = await SupabaseService.from(
                'staff',
              ).select('id, name, email').eq('id', uid).maybeSingle();
              user ??= await SupabaseService.from(
                'users',
              ).select('id, name, email').eq('id', uid).maybeSingle();
              if (user != null) {
                performedByUsersMap[uid] = Map<String, dynamic>.from(user);
              }
            } catch (e3) {
              continue;
            }
          }

          for (final uid in assignedToIds) {
            try {
              var user = await SupabaseService.from(
                'staff',
              ).select('id, name, email').eq('id', uid).maybeSingle();
              user ??= await SupabaseService.from(
                'users',
              ).select('id, name, email').eq('id', uid).maybeSingle();
              if (user != null) {
                assignedToUsersMap[uid] = Map<String, dynamic>.from(user);
              }
            } catch (e4) {
              continue;
            }
          }

          for (var activity in data) {
            final activityMap = activity as Map<String, dynamic>;
            final performedBy = activityMap['performed_by'] as String?;
            final assignedTo = activityMap['assigned_to'] as String?;

            if (performedBy != null &&
                performedByUsersMap.containsKey(performedBy)) {
              activityMap['performed_by_user'] =
                  performedByUsersMap[performedBy];
            }
            if (assignedTo != null &&
                assignedToUsersMap.containsKey(assignedTo)) {
              activityMap['assigned_to_user'] = assignedToUsersMap[assignedTo];
            }
          }
        }
      }

      return data
          .map((json) => LeadActivity.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }
}

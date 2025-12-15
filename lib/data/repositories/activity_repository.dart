import '../models/activity_model.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/helpers.dart';

class ActivityRepository {
  // Get all activities for a lead
  Future<List<LeadActivity>> findByLeadId(String leadId) async {
    try {
      final data = await SupabaseService.from('lead_activities')
          .select('''
            *,
            performed_by_user:users!lead_activities_performed_by_fkey(id, name, email),
            assigned_to_user:users!lead_activities_assigned_to_fkey(id, name, email)
          ''')
          .eq('lead_id', leadId)
          .order('created_at', ascending: false) as List<dynamic>? ?? [];
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
      final data = await SupabaseService.from('lead_activities')
          .select('''
            *,
            performed_by_user:users!lead_activities_performed_by_fkey(id, name, email),
            assigned_to_user:users!lead_activities_assigned_to_fkey(id, name, email)
          ''')
          .eq('id', id)
          .maybeSingle();

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

      final data = await SupabaseService.from('lead_activities')
          .insert(activityData)
          .select('''
            *,
            performed_by_user:users!lead_activities_performed_by_fkey(id, name, email),
            assigned_to_user:users!lead_activities_assigned_to_fkey(id, name, email)
          ''')
          .single();

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

      final data = await SupabaseService.from('lead_activities')
          .update(updateData)
          .eq('id', id)
          .select('''
            *,
            performed_by_user:users!lead_activities_performed_by_fkey(id, name, email),
            assigned_to_user:users!lead_activities_assigned_to_fkey(id, name, email)
          ''')
          .single();

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
      final data = await SupabaseService.from('lead_activities')
          .select('''
            *,
            performed_by_user:users!lead_activities_performed_by_fkey(id, name, email),
            assigned_to_user:users!lead_activities_assigned_to_fkey(id, name, email)
          ''')
          .eq('lead_id', leadId)
          .eq('activity_type', 'task')
          .inFilter('task_status', ['pending', 'in_progress'])
          .order('due_date', ascending: true)
          .order('priority', ascending: false) as List<dynamic>? ?? [];
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

      final data = await SupabaseService.from('lead_activities')
          .select('''
            *,
            performed_by_user:users!lead_activities_performed_by_fkey(id, name, email),
            assigned_to_user:users!lead_activities_assigned_to_fkey(id, name, email)
          ''')
          .eq('lead_id', leadId)
          .inFilter('activity_type', ['task', 'meeting'])
          .or('due_date.gte.$now,scheduled_at.gte.$now')
          .order('scheduled_at', ascending: true)
          .order('due_date', ascending: true)
          .limit(limit) as List<dynamic>? ?? [];
      return data
          .map((json) => LeadActivity.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }
}


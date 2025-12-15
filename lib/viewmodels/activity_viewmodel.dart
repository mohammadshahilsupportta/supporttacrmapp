import '../data/repositories/activity_repository.dart';
import '../data/models/activity_model.dart';

class ActivityViewModel {
  final ActivityRepository _repository = ActivityRepository();

  // Get all activities for a lead
  Future<List<LeadActivity>> getActivitiesByLeadId(String leadId) async {
    return await _repository.findByLeadId(leadId);
  }

  // Get a single activity by ID
  Future<LeadActivity?> getActivityById(String id) async {
    return await _repository.findById(id);
  }

  // Create a new activity
  Future<LeadActivity> createActivity(
    String leadId,
    String shopId,
    CreateActivityInput input,
    String performedBy,
  ) async {
    return await _repository.create(leadId, shopId, input, performedBy);
  }

  // Update an activity
  Future<LeadActivity> updateActivity(
    String id,
    UpdateActivityInput input,
  ) async {
    return await _repository.update(id, input);
  }

  // Delete an activity
  Future<void> deleteActivity(String id) async {
    await _repository.delete(id);
  }

  // Get pending tasks for a lead
  Future<List<LeadActivity>> getPendingTasks(String leadId) async {
    return await _repository.findPendingTasks(leadId);
  }

  // Get upcoming scheduled items
  Future<List<LeadActivity>> getUpcomingScheduled(
    String leadId, {
    int limit = 10,
  }) async {
    return await _repository.findUpcomingScheduled(leadId, limit: limit);
  }
}


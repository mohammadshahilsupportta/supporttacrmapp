import 'package:get/get.dart';
import '../../viewmodels/activity_viewmodel.dart';
import '../../data/models/activity_model.dart';
import '../../core/utils/helpers.dart';

class ActivityController extends GetxController {
  final ActivityViewModel _viewModel = ActivityViewModel();

  // Observables
  final _isLoading = false.obs;
  final _errorMessage = ''.obs;
  final _activities = <LeadActivity>[].obs;
  final _pendingTasks = <LeadActivity>[].obs;
  final _upcomingScheduled = <LeadActivity>[].obs;

  // Getters
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  List<LeadActivity> get activities => _activities;
  List<LeadActivity> get pendingTasks => _pendingTasks;
  List<LeadActivity> get upcomingScheduled => _upcomingScheduled;

  // Load activities for a lead
  Future<void> loadActivities(String leadId) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final activities = await _viewModel.getActivitiesByLeadId(leadId);
      _activities.value = activities;
    } catch (e) {
      _errorMessage.value = Helpers.handleError(e);
    } finally {
      _isLoading.value = false;
    }
  }

  // Load pending tasks
  Future<void> loadPendingTasks(String leadId) async {
    try {
      final tasks = await _viewModel.getPendingTasks(leadId);
      _pendingTasks.value = tasks;
    } catch (e) {
      _errorMessage.value = Helpers.handleError(e);
    }
  }

  // Load upcoming scheduled items
  Future<void> loadUpcomingScheduled(String leadId, {int limit = 10}) async {
    try {
      final scheduled = await _viewModel.getUpcomingScheduled(leadId, limit: limit);
      _upcomingScheduled.value = scheduled;
    } catch (e) {
      _errorMessage.value = Helpers.handleError(e);
    }
  }

  // Create activity
  Future<bool> createActivity(
    String leadId,
    String shopId,
    CreateActivityInput input,
    String performedBy,
  ) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final activity = await _viewModel.createActivity(
        leadId,
        shopId,
        input,
        performedBy,
      );
      _activities.insert(0, activity);
      
      // If it's a task, add to pending tasks list at the top
      if (activity.activityType == ActivityType.task &&
          (activity.taskStatus == TaskStatus.pending ||
           activity.taskStatus == TaskStatus.inProgress)) {
        // Insert at the top to show newest first
        _pendingTasks.insert(0, activity);
      }
      
      return true;
    } catch (e) {
      _errorMessage.value = Helpers.handleError(e);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Update activity
  Future<bool> updateActivity(String id, UpdateActivityInput input) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final index = _activities.indexWhere((a) => a.id == id);
      LeadActivity? oldActivity;
      if (index != -1) {
        oldActivity = _activities[index];
      }
      
      final updated = await _viewModel.updateActivity(id, input);
      if (index != -1) {
        _activities[index] = updated;
      }
      
      // If task status changed, refresh pending tasks
      if (oldActivity != null &&
          oldActivity.activityType == ActivityType.task &&
          updated.activityType == ActivityType.task &&
          (oldActivity.taskStatus != updated.taskStatus ||
           updated.taskStatus == TaskStatus.pending ||
           updated.taskStatus == TaskStatus.inProgress)) {
        await loadPendingTasks(updated.leadId);
      }
      
      return true;
    } catch (e) {
      _errorMessage.value = Helpers.handleError(e);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Delete activity
  Future<bool> deleteActivity(String id) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      await _viewModel.deleteActivity(id);
      _activities.removeWhere((a) => a.id == id);
      _pendingTasks.removeWhere((a) => a.id == id);
      _upcomingScheduled.removeWhere((a) => a.id == id);
      return true;
    } catch (e) {
      _errorMessage.value = Helpers.handleError(e);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Refresh all data for a lead
  Future<void> refreshActivities(String leadId) async {
    await Future.wait([
      loadActivities(leadId),
      loadPendingTasks(leadId),
      loadUpcomingScheduled(leadId),
    ]);
  }
}


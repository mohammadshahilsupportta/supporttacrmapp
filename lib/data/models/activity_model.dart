enum ActivityType {
  task,
  taskCompleted,
  meeting,
  meetingCompleted,
  call,
  email,
  note,
  statusChange,
  assignment,
  categoryChange,
  fieldUpdate,
}

enum TaskPriority { high, medium, low }

enum TaskStatus { pending, inProgress, completed, cancelled }

enum MeetingType { inPerson, phone, video, demo, siteVisit }

enum NoteType { callSummary, meetingNotes, internalNote, followUp }

class LeadActivity {
  final String id;
  final String leadId;
  final String shopId;
  final ActivityType activityType;
  final String? title;
  final String? description;
  final DateTime? scheduledAt;
  final DateTime? completedAt;
  final DateTime? dueDate;
  final TaskPriority? priority;
  final TaskStatus? taskStatus;
  final MeetingType? meetingType;
  final String? meetingLocation;
  final int? meetingDuration;
  final String? noteContent;
  final NoteType? noteType;
  final String performedBy;
  final String? assignedTo;
  final String? relatedActivityId;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relations
  final AssignedUser? performedByUser;
  final AssignedUser? assignedToUser;

  LeadActivity({
    required this.id,
    required this.leadId,
    required this.shopId,
    required this.activityType,
    this.title,
    this.description,
    this.scheduledAt,
    this.completedAt,
    this.dueDate,
    this.priority,
    this.taskStatus,
    this.meetingType,
    this.meetingLocation,
    this.meetingDuration,
    this.noteContent,
    this.noteType,
    required this.performedBy,
    this.assignedTo,
    this.relatedActivityId,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.performedByUser,
    this.assignedToUser,
  });

  factory LeadActivity.fromJson(Map<String, dynamic> json) {
    return LeadActivity(
      id: json['id'] ?? '',
      leadId: json['lead_id'] ?? '',
      shopId: json['shop_id'] ?? '',
      activityType: _activityTypeFromString(json['activity_type'] ?? ''),
      title: json['title'],
      description: json['description'],
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.parse(json['scheduled_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      dueDate:
          json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      priority: json['priority'] != null
          ? _priorityFromString(json['priority'])
          : null,
      taskStatus: json['task_status'] != null
          ? _taskStatusFromString(json['task_status'])
          : null,
      meetingType: json['meeting_type'] != null
          ? _meetingTypeFromString(json['meeting_type'])
          : null,
      meetingLocation: json['meeting_location'],
      meetingDuration: json['meeting_duration'],
      noteContent: json['note_content'],
      noteType: json['note_type'] != null
          ? _noteTypeFromString(json['note_type'])
          : null,
      performedBy: json['performed_by'] ?? '',
      assignedTo: json['assigned_to'],
      relatedActivityId: json['related_activity_id'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      performedByUser: json['performed_by_user'] != null
          ? AssignedUser.fromJson(json['performed_by_user'])
          : null,
      assignedToUser: json['assigned_to_user'] != null
          ? AssignedUser.fromJson(json['assigned_to_user'])
          : null,
    );
  }

  static ActivityType _activityTypeFromString(String type) {
    switch (type) {
      case 'task':
        return ActivityType.task;
      case 'task_completed':
        return ActivityType.taskCompleted;
      case 'meeting':
        return ActivityType.meeting;
      case 'meeting_completed':
        return ActivityType.meetingCompleted;
      case 'call':
        return ActivityType.call;
      case 'email':
        return ActivityType.email;
      case 'note':
        return ActivityType.note;
      case 'status_change':
        return ActivityType.statusChange;
      case 'assignment':
        return ActivityType.assignment;
      case 'category_change':
        return ActivityType.categoryChange;
      case 'field_update':
        return ActivityType.fieldUpdate;
      default:
        return ActivityType.note;
    }
  }

  static TaskPriority _priorityFromString(String priority) {
    switch (priority) {
      case 'high':
        return TaskPriority.high;
      case 'medium':
        return TaskPriority.medium;
      case 'low':
        return TaskPriority.low;
      default:
        return TaskPriority.medium;
    }
  }

  static TaskStatus _taskStatusFromString(String status) {
    switch (status) {
      case 'pending':
        return TaskStatus.pending;
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'completed':
        return TaskStatus.completed;
      case 'cancelled':
        return TaskStatus.cancelled;
      default:
        return TaskStatus.pending;
    }
  }

  static MeetingType _meetingTypeFromString(String type) {
    switch (type) {
      case 'in_person':
        return MeetingType.inPerson;
      case 'phone':
        return MeetingType.phone;
      case 'video':
        return MeetingType.video;
      case 'demo':
        return MeetingType.demo;
      case 'site_visit':
        return MeetingType.siteVisit;
      default:
        return MeetingType.inPerson;
    }
  }

  static NoteType _noteTypeFromString(String type) {
    switch (type) {
      case 'call_summary':
        return NoteType.callSummary;
      case 'meeting_notes':
        return NoteType.meetingNotes;
      case 'internal_note':
        return NoteType.internalNote;
      case 'follow_up':
        return NoteType.followUp;
      default:
        return NoteType.internalNote;
    }
  }

  String get activityTypeString {
    switch (activityType) {
      case ActivityType.task:
        return 'task';
      case ActivityType.taskCompleted:
        return 'task_completed';
      case ActivityType.meeting:
        return 'meeting';
      case ActivityType.meetingCompleted:
        return 'meeting_completed';
      case ActivityType.call:
        return 'call';
      case ActivityType.email:
        return 'email';
      case ActivityType.note:
        return 'note';
      case ActivityType.statusChange:
        return 'status_change';
      case ActivityType.assignment:
        return 'assignment';
      case ActivityType.categoryChange:
        return 'category_change';
      case ActivityType.fieldUpdate:
        return 'field_update';
    }
  }

  String? get priorityString {
    if (priority == null) return null;
    switch (priority!) {
      case TaskPriority.high:
        return 'high';
      case TaskPriority.medium:
        return 'medium';
      case TaskPriority.low:
        return 'low';
    }
  }

  String? get taskStatusString {
    if (taskStatus == null) return null;
    switch (taskStatus!) {
      case TaskStatus.pending:
        return 'pending';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.completed:
        return 'completed';
      case TaskStatus.cancelled:
        return 'cancelled';
    }
  }

  String? get meetingTypeString {
    if (meetingType == null) return null;
    switch (meetingType!) {
      case MeetingType.inPerson:
        return 'in_person';
      case MeetingType.phone:
        return 'phone';
      case MeetingType.video:
        return 'video';
      case MeetingType.demo:
        return 'demo';
      case MeetingType.siteVisit:
        return 'site_visit';
    }
  }

  String? get noteTypeString {
    if (noteType == null) return null;
    switch (noteType!) {
      case NoteType.callSummary:
        return 'call_summary';
      case NoteType.meetingNotes:
        return 'meeting_notes';
      case NoteType.internalNote:
        return 'internal_note';
      case NoteType.followUp:
        return 'follow_up';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lead_id': leadId,
      'shop_id': shopId,
      'activity_type': activityTypeString,
      'title': title,
      'description': description,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'priority': priorityString,
      'task_status': taskStatusString,
      'meeting_type': meetingTypeString,
      'meeting_location': meetingLocation,
      'meeting_duration': meetingDuration,
      'note_content': noteContent,
      'note_type': noteTypeString,
      'performed_by': performedBy,
      'assigned_to': assignedTo,
      'related_activity_id': relatedActivityId,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}

class CreateActivityInput {
  final String? leadId;
  final ActivityType activityType;
  final String? title;
  final String? description;
  final DateTime? scheduledAt;
  final DateTime? dueDate;
  final TaskPriority? priority;
  final MeetingType? meetingType;
  final String? meetingLocation;
  final int? meetingDuration;
  final String? noteContent;
  final NoteType? noteType;
  final String? assignedTo;
  final Map<String, dynamic>? metadata;

  CreateActivityInput({
    this.leadId,
    required this.activityType,
    this.title,
    this.description,
    this.scheduledAt,
    this.dueDate,
    this.priority,
    this.meetingType,
    this.meetingLocation,
    this.meetingDuration,
    this.noteContent,
    this.noteType,
    this.assignedTo,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      if (leadId != null) 'lead_id': leadId,
      'activity_type': _activityTypeToString(activityType),
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (scheduledAt != null) 'scheduled_at': scheduledAt!.toIso8601String(),
      if (dueDate != null) 'due_date': dueDate!.toIso8601String(),
      if (priority != null) 'priority': _priorityToString(priority!),
      if (meetingType != null) 'meeting_type': _meetingTypeToString(meetingType!),
      if (meetingLocation != null) 'meeting_location': meetingLocation,
      if (meetingDuration != null) 'meeting_duration': meetingDuration,
      if (noteContent != null) 'note_content': noteContent,
      if (noteType != null) 'note_type': _noteTypeToString(noteType!),
      if (assignedTo != null) 'assigned_to': assignedTo,
      if (metadata != null) 'metadata': metadata,
    };
  }

  static String _activityTypeToString(ActivityType type) {
    switch (type) {
      case ActivityType.task:
        return 'task';
      case ActivityType.taskCompleted:
        return 'task_completed';
      case ActivityType.meeting:
        return 'meeting';
      case ActivityType.meetingCompleted:
        return 'meeting_completed';
      case ActivityType.call:
        return 'call';
      case ActivityType.email:
        return 'email';
      case ActivityType.note:
        return 'note';
      case ActivityType.statusChange:
        return 'status_change';
      case ActivityType.assignment:
        return 'assignment';
      case ActivityType.categoryChange:
        return 'category_change';
      case ActivityType.fieldUpdate:
        return 'field_update';
    }
  }

  static String _priorityToString(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return 'high';
      case TaskPriority.medium:
        return 'medium';
      case TaskPriority.low:
        return 'low';
    }
  }

  static String _meetingTypeToString(MeetingType type) {
    switch (type) {
      case MeetingType.inPerson:
        return 'in_person';
      case MeetingType.phone:
        return 'phone';
      case MeetingType.video:
        return 'video';
      case MeetingType.demo:
        return 'demo';
      case MeetingType.siteVisit:
        return 'site_visit';
    }
  }

  static String _noteTypeToString(NoteType type) {
    switch (type) {
      case NoteType.callSummary:
        return 'call_summary';
      case NoteType.meetingNotes:
        return 'meeting_notes';
      case NoteType.internalNote:
        return 'internal_note';
      case NoteType.followUp:
        return 'follow_up';
    }
  }
}

class UpdateActivityInput {
  final String id;
  final String? title;
  final String? description;
  final DateTime? scheduledAt;
  final DateTime? completedAt;
  final DateTime? dueDate;
  final TaskPriority? priority;
  final TaskStatus? taskStatus;
  final String? noteContent;
  final String? assignedTo;
  final Map<String, dynamic>? metadata;

  UpdateActivityInput({
    required this.id,
    this.title,
    this.description,
    this.scheduledAt,
    this.completedAt,
    this.dueDate,
    this.priority,
    this.taskStatus,
    this.noteContent,
    this.assignedTo,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (scheduledAt != null) 'scheduled_at': scheduledAt!.toIso8601String(),
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      if (dueDate != null) 'due_date': dueDate!.toIso8601String(),
      if (priority != null) 'priority': _priorityToString(priority!),
      if (taskStatus != null) 'task_status': _taskStatusToString(taskStatus!),
      if (noteContent != null) 'note_content': noteContent,
      if (assignedTo != null) 'assigned_to': assignedTo,
      if (metadata != null) 'metadata': metadata,
    };
  }

  static String _priorityToString(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return 'high';
      case TaskPriority.medium:
        return 'medium';
      case TaskPriority.low:
        return 'low';
    }
  }

  static String _taskStatusToString(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'pending';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.completed:
        return 'completed';
      case TaskStatus.cancelled:
        return 'cancelled';
    }
  }
}


import 'package:flutter/material.dart';
import '../../data/models/activity_model.dart';
import 'package:intl/intl.dart';

class ActivityCardWidget extends StatelessWidget {
  final LeadActivity activity;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ActivityCardWidget({
    super.key,
    required this.activity,
    this.onTap,
    this.onDelete,
  });

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.task:
      case ActivityType.taskCompleted:
        return Icons.task;
      case ActivityType.meeting:
      case ActivityType.meetingCompleted:
        return Icons.event;
      case ActivityType.call:
        return Icons.phone;
      case ActivityType.email:
        return Icons.email;
      case ActivityType.note:
        return Icons.note;
      case ActivityType.statusChange:
        return Icons.change_circle;
      case ActivityType.assignment:
        return Icons.person_add;
      case ActivityType.categoryChange:
        return Icons.category;
      case ActivityType.fieldUpdate:
        return Icons.edit;
    }
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.task:
        return Colors.blue;
      case ActivityType.taskCompleted:
        return Colors.green;
      case ActivityType.meeting:
        return Colors.purple;
      case ActivityType.meetingCompleted:
        return Colors.green;
      case ActivityType.call:
        return Colors.orange;
      case ActivityType.email:
        return Colors.teal;
      case ActivityType.note:
        return Colors.grey;
      case ActivityType.statusChange:
        return Colors.indigo;
      case ActivityType.assignment:
        return Colors.pink;
      case ActivityType.categoryChange:
        return Colors.cyan;
      case ActivityType.fieldUpdate:
        return Colors.amber;
    }
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    return DateFormat('MMM dd, hh:mm a').format(date);
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
        return Colors.blue;
    }
  }

  Widget _buildPriorityBadge(TaskPriority priority) {
    final color = _getPriorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.flag,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            priority.toString().split('.').last.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getActivityDisplayText() {
    // For notes, show note content
    if (activity.activityType == ActivityType.note && activity.noteContent != null) {
      return activity.noteContent!;
    }
    // For tasks, show title or description
    if (activity.activityType == ActivityType.task || 
        activity.activityType == ActivityType.taskCompleted) {
      return activity.title ?? activity.description ?? '';
    }
    // For meetings, show title or description
    if (activity.activityType == ActivityType.meeting || 
        activity.activityType == ActivityType.meetingCompleted) {
      return activity.title ?? activity.description ?? '';
    }
    // For calls, show description
    if (activity.activityType == ActivityType.call) {
      return activity.description ?? '';
    }
    // For emails, show description
    if (activity.activityType == ActivityType.email) {
      return activity.description ?? '';
    }
    // For status changes, show description or metadata
    if (activity.activityType == ActivityType.statusChange) {
      return activity.description ?? 'Status changed';
    }
    // For assignments, show description or metadata
    if (activity.activityType == ActivityType.assignment) {
      return activity.description ?? 'Assignment changed';
    }
    // For category changes, show description or metadata
    if (activity.activityType == ActivityType.categoryChange) {
      return activity.description ?? 'Category changed';
    }
    // For field updates, show description or metadata
    if (activity.activityType == ActivityType.fieldUpdate) {
      return activity.description ?? 'Field updated';
    }
    // Default: show title, description, or note content
    return activity.title ?? activity.description ?? activity.noteContent ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _getActivityColor(activity.activityType);
    final displayText = _getActivityDisplayText();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getActivityIcon(activity.activityType),
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main content text
                    if (displayText.isNotEmpty) ...[
                      Text(
                        displayText,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                    ],
                    // Additional details based on activity type
                    if (activity.activityType == ActivityType.meeting || 
                        activity.activityType == ActivityType.meetingCompleted) ...[
                      if (activity.meetingLocation != null &&
                          activity.meetingLocation!.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                activity.meetingLocation!,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (activity.meetingType != null) ...[
                        Text(
                          _getMeetingTypeLabel(activity.meetingType!),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ],
                    if (activity.activityType == ActivityType.task || 
                        activity.activityType == ActivityType.taskCompleted) ...[
                      if (activity.dueDate != null) ...[
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              'Due: ${DateFormat('MMM dd, hh:mm a').format(activity.dueDate!)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                    ],
                    // Priority and Status badges
                    if (activity.priority != null || activity.taskStatus != null) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (activity.priority != null)
                            _buildPriorityBadge(activity.priority!),
                          if (activity.taskStatus != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getTaskStatusColor(activity.taskStatus!)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _getTaskStatusColor(activity.taskStatus!)
                                      .withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                activity.taskStatusString!.replaceAll('_', ' ').toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _getTaskStatusColor(activity.taskStatus!),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    // Metadata row: User and Time
                    Row(
                      children: [
                        if (activity.performedByUser != null) ...[
                          Icon(Icons.person, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            activity.performedByUser!.name,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(width: 12),
                        ],
                        Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          activity.scheduledAt != null
                              ? _formatTime(activity.scheduledAt)
                              : _formatTime(activity.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                                fontSize: 11,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onDelete,
                  color: Colors.red,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMeetingTypeLabel(MeetingType type) {
    switch (type) {
      case MeetingType.inPerson:
        return 'In Person';
      case MeetingType.phone:
        return 'Phone Call';
      case MeetingType.video:
        return 'Video Call';
      case MeetingType.demo:
        return 'Demo';
      case MeetingType.siteVisit:
        return 'Site Visit';
    }
  }

  Color _getTaskStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Colors.orange;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.cancelled:
        return Colors.red;
    }
  }
}


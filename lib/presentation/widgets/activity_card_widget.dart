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
    return DateFormat('MMM dd, HH:mm').format(date);
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
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

  @override
  Widget build(BuildContext context) {
    final iconColor = _getActivityColor(activity.activityType);

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
                  color: iconColor.withOpacity(0.1),
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
                    if (activity.title != null) ...[
                      Text(
                        activity.title!,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (activity.description != null) ...[
                      Text(
                        activity.description!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (activity.noteContent != null) ...[
                      Text(
                        activity.noteContent!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                    ],
                    // Location (for meetings)
                    if (activity.meetingLocation != null &&
                        activity.meetingLocation!.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              activity.meetingLocation!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                    fontSize: 11,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    // Metadata row: User and Time
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (activity.performedByUser != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person, size: 12, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                activity.performedByUser!.name,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey,
                                      fontSize: 11,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              activity.scheduledAt != null
                                  ? _formatTime(activity.scheduledAt)
                                  : _formatTime(activity.createdAt),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                    fontSize: 11,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (activity.priority != null || activity.taskStatus != null) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: [
                          if (activity.priority != null)
                            _buildPriorityBadge(activity.priority!),
                          if (activity.taskStatus != null)
                            Chip(
                              label: Text(
                                activity.taskStatusString!.replaceAll('_', ' ').toUpperCase(),
                                style: const TextStyle(fontSize: 10),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                    ],
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
}


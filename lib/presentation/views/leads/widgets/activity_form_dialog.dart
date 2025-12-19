import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import '../../../../data/models/activity_model.dart';
import '../../../controllers/staff_controller.dart';

class ActivityFormDialog extends StatefulWidget {
  final String leadId;
  final String shopId;
  final String userId;
  final ActivityType? defaultActivityType;
  final Function(CreateActivityInput) onCreate;

  const ActivityFormDialog({
    super.key,
    required this.leadId,
    required this.shopId,
    required this.userId,
    this.defaultActivityType,
    required this.onCreate,
  });

  @override
  State<ActivityFormDialog> createState() => _ActivityFormDialogState();
}

class _ActivityFormDialogState extends State<ActivityFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _noteContentController = TextEditingController();
  final _meetingLocationController = TextEditingController();
  final _meetingDurationController = TextEditingController();

  ActivityType _selectedActivityType = ActivityType.note;
  TaskPriority? _selectedPriority;
  MeetingType? _selectedMeetingType;
  NoteType? _selectedNoteType;
  DateTime? _scheduledAt;
  DateTime? _dueDate;
  String? _assignedTo;

  final StaffController _staffController = Get.put(StaffController());

  @override
  void initState() {
    super.initState();
    _selectedActivityType = widget.defaultActivityType ?? ActivityType.note;
    if (widget.shopId.isNotEmpty) {
      _staffController.loadStaff(widget.shopId);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _noteContentController.dispose();
    _meetingLocationController.dispose();
    _meetingDurationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(
    BuildContext context,
    bool isScheduled,
  ) async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      // For due dates (tasks), only allow future dates
      // For scheduled dates (meetings), allow past dates too
      firstDate: isScheduled 
          ? now.subtract(const Duration(days: 365))
          : now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      // For due dates, if today is selected, set initial time to next hour
      // Otherwise, use current time
      final isToday = picked.year == now.year &&
          picked.month == now.month &&
          picked.day == now.day;
      final initialTime = isToday && !isScheduled
          ? TimeOfDay(
              hour: now.hour + 1 >= 24 ? 0 : now.hour + 1,
              minute: 0,
            )
          : TimeOfDay.now();
      
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: initialTime,
      );
      if (time != null) {
        final selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );
        
        // For due dates, validate that the selected date/time is in the future
        if (!isScheduled && selectedDateTime.isBefore(now)) {
          Get.snackbar(
            'Invalid Date',
            'Due date must be in the future',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }
        
        setState(() {
          if (isScheduled) {
            _scheduledAt = selectedDateTime;
          } else {
            _dueDate = selectedDateTime;
          }
        });
      }
    }
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    // Validate task-specific requirements
    if (_selectedActivityType == ActivityType.task) {
      if (_titleController.text.trim().isEmpty) {
        Get.snackbar(
          'Validation Error',
          'Title is required for tasks',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
    }

    // Validate note-specific requirements
    if (_selectedActivityType == ActivityType.note) {
      if (_noteContentController.text.trim().isEmpty) {
        Get.snackbar(
          'Validation Error',
          'Note content is required',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
    }

    final input = CreateActivityInput(
      leadId: widget.leadId,
      activityType: _selectedActivityType,
      title: _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : null,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      scheduledAt: _scheduledAt,
      dueDate: _dueDate,
      priority: _selectedPriority,
      meetingType: _selectedMeetingType,
      meetingLocation: _meetingLocationController.text.trim().isNotEmpty
          ? _meetingLocationController.text.trim()
          : null,
      meetingDuration: _meetingDurationController.text.trim().isNotEmpty
          ? int.tryParse(_meetingDurationController.text.trim())
          : null,
      noteContent: _noteContentController.text.trim().isNotEmpty
          ? _noteContentController.text.trim()
          : null,
      noteType: _selectedNoteType,
      assignedTo: _assignedTo,
    );

    widget.onCreate(input);
  }

  @override
  Widget build(BuildContext context) {
    final isNoteOnly = widget.defaultActivityType == ActivityType.note;
    final isTaskOnly = widget.defaultActivityType == ActivityType.task;
    
    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: isNoteOnly ? 550 : 800,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      isNoteOnly
                          ? Icons.note_add
                          : isTaskOnly
                              ? Icons.task
                              : Icons.add_task,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isNoteOnly
                                ? 'Add Note'
                                : isTaskOnly
                                    ? 'Create Task'
                                    : 'Add Activity',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (isNoteOnly) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Add a note about this lead. It will appear in the timeline.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Form Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Activity Type - Hide if default is note or task
                      if (widget.defaultActivityType != ActivityType.note &&
                          widget.defaultActivityType != ActivityType.task) ...[
                        Text(
                          'Activity Type',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<ActivityType>(
                          value: _selectedActivityType,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: ActivityType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(_getActivityTypeLabel(type)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedActivityType = value;
                                // Reset type-specific fields
                                _selectedMeetingType = null;
                                _selectedNoteType = null;
                                _selectedPriority = null;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Title - Hide for notes
                      if (_selectedActivityType != ActivityType.note) ...[
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: isTaskOnly ? 'Task Title *' : 'Title',
                            border: const OutlineInputBorder(),
                            hintText: _selectedActivityType == ActivityType.task
                                ? 'Task title (required)'
                                : 'Title',
                          ),
                          validator: (value) {
                            if ((_selectedActivityType == ActivityType.task ||
                                    isTaskOnly) &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Task title is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Description - Hide for notes
                      if (_selectedActivityType != ActivityType.note) ...[
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Task-specific fields - Order: Due Date, Priority, Assign To
                      if (_selectedActivityType == ActivityType.task ||
                          _selectedActivityType == ActivityType.taskCompleted ||
                          isTaskOnly) ...[
                        // Due Date
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Due Date'),
                          subtitle: Text(
                            _dueDate != null
                                ? DateFormat('MMM dd, yyyy HH:mm')
                                    .format(_dueDate!)
                                : 'No due date',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.event),
                            onPressed: () => _selectDate(context, false),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Priority
                        DropdownButtonFormField<TaskPriority>(
                          value: _selectedPriority,
                          decoration: const InputDecoration(
                            labelText: 'Priority',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: TaskPriority.values.map((priority) {
                            return DropdownMenuItem(
                              value: priority,
                              child: Text(priority.toString().split('.').last),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedPriority = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (_selectedActivityType == ActivityType.meeting ||
                          _selectedActivityType == ActivityType.meetingCompleted) ...[
                        // Meeting Type
                        DropdownButtonFormField<MeetingType>(
                          value: _selectedMeetingType,
                          decoration: const InputDecoration(
                            labelText: 'Meeting Type',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: MeetingType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type.toString().split('.').last),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedMeetingType = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        // Meeting Location
                        TextFormField(
                          controller: _meetingLocationController,
                          decoration: const InputDecoration(
                            labelText: 'Location',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Meeting Duration
                        TextFormField(
                          controller: _meetingDurationController,
                          decoration: const InputDecoration(
                            labelText: 'Duration (minutes)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (_selectedActivityType == ActivityType.note) ...[
                        // Note Type - Optional
                        DropdownButtonFormField<NoteType>(
                          value: _selectedNoteType,
                          decoration: const InputDecoration(
                            labelText: 'Note Type (Optional)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem<NoteType>(
                              value: null,
                              child: Text('Select note type'),
                            ),
                            ...NoteType.values.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(_getNoteTypeLabel(type)),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedNoteType = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        // Note Content - Required for notes
                        TextFormField(
                          controller: _noteContentController,
                          decoration: const InputDecoration(
                            labelText: 'Note Content *',
                            border: OutlineInputBorder(),
                            hintText: 'Enter your note here...',
                          ),
                          maxLines: 6,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Note content is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Scheduled At - Hide for tasks (only show for meetings)
                      if (_selectedActivityType == ActivityType.meeting ||
                          _selectedActivityType == ActivityType.meetingCompleted) ...[
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Scheduled At'),
                          subtitle: Text(
                            _scheduledAt != null
                                ? DateFormat('MMM dd, yyyy HH:mm')
                                    .format(_scheduledAt!)
                                : 'Not scheduled',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () => _selectDate(context, true),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Assign To - Show for tasks
                      if (_selectedActivityType == ActivityType.task ||
                          _selectedActivityType == ActivityType.taskCompleted ||
                          isTaskOnly) ...[
                        Obx(() {
                          if (_staffController.isLoading) {
                            return const CircularProgressIndicator();
                          }
                          return DropdownButtonFormField<String>(
                            value: _assignedTo,
                            decoration: const InputDecoration(
                              labelText: 'Assign To',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Unassigned'),
                              ),
                              ..._staffController.staffList
                                  .where((s) => s.isActive)
                                  .map((staff) {
                                return DropdownMenuItem<String>(
                                  value: staff.id,
                                  child: Text(staff.name),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _assignedTo = value;
                              });
                            },
                          );
                        }),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              // Actions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _handleSubmit,
                      child: const Text('Create'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getActivityTypeLabel(ActivityType type) {
    switch (type) {
      case ActivityType.task:
        return 'Task';
      case ActivityType.taskCompleted:
        return 'Task Completed';
      case ActivityType.meeting:
        return 'Meeting';
      case ActivityType.meetingCompleted:
        return 'Meeting Completed';
      case ActivityType.call:
        return 'Call';
      case ActivityType.email:
        return 'Email';
      case ActivityType.note:
        return 'Note';
      case ActivityType.statusChange:
        return 'Status Change';
      case ActivityType.assignment:
        return 'Assignment';
      case ActivityType.categoryChange:
        return 'Category Change';
      case ActivityType.fieldUpdate:
        return 'Field Update';
    }
  }

  String _getNoteTypeLabel(NoteType type) {
    switch (type) {
      case NoteType.callSummary:
        return 'Call Summary';
      case NoteType.meetingNotes:
        return 'Meeting Notes';
      case NoteType.internalNote:
        return 'Internal Note';
      case NoteType.followUp:
        return 'Follow Up';
    }
  }
}


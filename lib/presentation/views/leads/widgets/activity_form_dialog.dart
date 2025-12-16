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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          if (isScheduled) {
            _scheduledAt = DateTime(
              picked.year,
              picked.month,
              picked.day,
              time.hour,
              time.minute,
            );
          } else {
            _dueDate = DateTime(
              picked.year,
              picked.month,
              picked.day,
              time.hour,
              time.minute,
            );
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
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
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
                    const Icon(Icons.add_task),
                    const SizedBox(width: 8),
                    Text(
                      'Add Activity',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Activity Type
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

                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          border: const OutlineInputBorder(),
                          hintText: _selectedActivityType == ActivityType.task
                              ? 'Task title (required)'
                              : 'Title',
                        ),
                        validator: (value) {
                          if (_selectedActivityType == ActivityType.task &&
                              (value == null || value.trim().isEmpty)) {
                            return 'Title is required for tasks';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Type-specific fields
                      if (_selectedActivityType == ActivityType.task ||
                          _selectedActivityType == ActivityType.taskCompleted) ...[
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
                        // Note Type
                        DropdownButtonFormField<NoteType>(
                          value: _selectedNoteType,
                          decoration: const InputDecoration(
                            labelText: 'Note Type',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: NoteType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type.toString().split('.').last),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedNoteType = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        // Note Content
                        TextFormField(
                          controller: _noteContentController,
                          decoration: const InputDecoration(
                            labelText: 'Note Content',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 4,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Scheduled At
                      if (_selectedActivityType == ActivityType.meeting ||
                          _selectedActivityType == ActivityType.task) ...[
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

                      // Due Date
                      if (_selectedActivityType == ActivityType.task) ...[
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
                        const SizedBox(height: 8),
                      ],

                      // Assign To
                      if (_selectedActivityType == ActivityType.task) ...[
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
}


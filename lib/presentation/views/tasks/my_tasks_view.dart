import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../controllers/auth_controller.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart' as error_widget;
import '../../../data/models/activity_model.dart';
import '../../../data/repositories/activity_repository.dart';
import '../../../app/routes/app_routes.dart';

class MyTasksView extends StatefulWidget {
  const MyTasksView({super.key});

  @override
  State<MyTasksView> createState() => _MyTasksViewState();
}

class _MyTasksViewState extends State<MyTasksView> {
  final ActivityRepository _activityRepository = ActivityRepository();

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  List<LeadActivity> _allTasks = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _initialLoadAttempted = false;
  Worker? _authWorker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptInitialLoad();
    });
  }

  @override
  void dispose() {
    _authWorker?.dispose();
    super.dispose();
  }

  void _attemptInitialLoad() {
    final authController = Get.find<AuthController>();

    // If already authenticated, load immediately
    if (authController.isAuthenticated &&
        authController.shop != null &&
        authController.user != null) {
      _loadTasks();
      _initialLoadAttempted = true;
      return;
    }

    // Wait for shop and user to be loaded
    _authWorker = ever(authController.shopRx, (shop) {
      if (shop != null &&
          authController.user != null &&
          !_initialLoadAttempted) {
        _initialLoadAttempted = true;
        _loadTasks();
      }
    });

    // Also listen to user changes
    ever(authController.userRx, (user) {
      if (user != null &&
          authController.shop != null &&
          !_initialLoadAttempted) {
        _initialLoadAttempted = true;
        _loadTasks();
      }
    });
  }

  Future<void> _loadTasks() async {
    final authController = Get.find<AuthController>();
    if (authController.shop == null || authController.user == null) {
      // Don't show error immediately, might still be initializing
      if (!authController.isAuthenticated) {
        setState(() {
          _isLoading = true; // Keep loading state while waiting
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tasks = await _activityRepository.findMyTasks(
        authController.shop!.id,
        authController.user!.id,
      );
      if (mounted) {
        setState(() {
          _allTasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  // Group tasks by date for calendar markers
  Map<DateTime, List<LeadActivity>> get _tasksByDate {
    final Map<DateTime, List<LeadActivity>> map = {};
    for (final task in _allTasks) {
      if (task.dueDate != null) {
        final dateOnly = DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
        );
        if (!map.containsKey(dateOnly)) {
          map[dateOnly] = [];
        }
        map[dateOnly]!.add(task);
      }
    }
    return map;
  }

  // Tasks for selected date
  List<LeadActivity> get _selectedDateTasks {
    final dateOnly = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    return _tasksByDate[dateOnly] ?? [];
  }

  // Tasks without due date
  List<LeadActivity> get _tasksWithoutDate {
    return _allTasks.where((task) => task.dueDate == null).toList();
  }

  // Check if a task is overdue
  bool _isOverdue(LeadActivity task) {
    if (task.dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(
      task.dueDate!.year,
      task.dueDate!.month,
      task.dueDate!.day,
    );
    return dueDate.isBefore(today) &&
        task.taskStatus != TaskStatus.completed &&
        task.taskStatus != TaskStatus.cancelled;
  }

  // Check if any task on a date is overdue
  bool _hasOverdueOnDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final tasks = _tasksByDate[dateOnly] ?? [];
    return tasks.any(_isOverdue);
  }

  Color _getPriorityColor(TaskPriority? priority) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(TaskStatus? status) {
    switch (status) {
      case TaskStatus.pending:
        return Colors.blue;
      case TaskStatus.inProgress:
        return Colors.purple;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.cancelled:
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _getStatusLabel(TaskStatus? status) {
    switch (status) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.cancelled:
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }

  String _getPriorityLabel(TaskPriority? priority) {
    switch (priority) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return const LoadingWidget();
    }

    if (_errorMessage != null) {
      return error_widget.ErrorDisplayWidget(
        message: _errorMessage!,
        onRetry: _loadTasks,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Header
          // SliverToBoxAdapter(
          //   child: Padding(
          //     padding: const EdgeInsets.all(16),
          //     child: Row(
          //       children: [
          //         Icon(
          //           Icons.calendar_month,
          //           size: 28,
          //           color: colorScheme.primary,
          //         ),
          //         const SizedBox(width: 12),
          //         Text(
          //           'My Tasks',
          //           style: theme.textTheme.headlineSmall?.copyWith(
          //             fontWeight: FontWeight.bold,
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),

          // Calendar
          SliverToBoxAdapter(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    TableCalendar<LeadActivity>(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      calendarFormat: _calendarFormat,
                      eventLoader: (day) {
                        final dateOnly = DateTime(day.year, day.month, day.day);
                        return _tasksByDate[dateOnly] ?? [];
                      },
                      startingDayOfWeek: StartingDayOfWeek.sunday,
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: true,
                        weekendTextStyle: TextStyle(
                          color: colorScheme.onSurface,
                        ),
                        holidayTextStyle: TextStyle(
                          color: colorScheme.onSurface,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        todayTextStyle: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                        markerDecoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        markersMaxCount: 3,
                        markerSize: 6,
                        markerMargin: const EdgeInsets.symmetric(
                          horizontal: 0.5,
                        ),
                      ),
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, date, events) {
                          if (events.isEmpty) return null;
                          final hasOverdue = _hasOverdueOnDate(date);
                          return Positioned(
                            bottom: 1,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: hasOverdue
                                        ? Colors.red
                                        : colorScheme.primary,
                                  ),
                                ),
                                if (events.length > 1)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 2),
                                    child: Text(
                                      '+${events.length - 1}',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: hasOverdue
                                            ? Colors.red
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: theme.textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        leftChevronIcon: Icon(
                          Icons.chevron_left,
                          color: colorScheme.onSurface,
                        ),
                        rightChevronIcon: Icon(
                          Icons.chevron_right,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      onFormatChanged: (format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                      },
                    ),

                    // Today button and Legend
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _focusedDay = DateTime.now();
                                _selectedDay = DateTime.now();
                              });
                            },
                            icon: const Icon(Icons.today, size: 16),
                            label: const Text('Today'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              minimumSize: const Size(0, 32),
                            ),
                          ),
                          const Spacer(),
                          // Legend
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Tasks',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Overdue',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Selected Date Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isToday(_selectedDay)
                        ? 'Today'
                        : DateFormat('MMMM d, yyyy').format(_selectedDay),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_selectedDateTasks.length} task${_selectedDateTasks.length != 1 ? 's' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tasks for selected date
          if (_selectedDateTasks.isEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 48,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No tasks scheduled',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final task = _selectedDateTasks[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: _buildTaskCard(task),
                );
              }, childCount: _selectedDateTasks.length),
            ),

          // Tasks without due date section
          if (_tasksWithoutDate.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'No Due Date',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_tasksWithoutDate.length}',
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= 3 && _tasksWithoutDate.length > 3) {
                    // Show "more tasks" indicator
                    if (index == 3) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          '+${_tasksWithoutDate.length - 3} more tasks without due date',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }
                  final task = _tasksWithoutDate[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: _buildTaskCard(task),
                  );
                },
                childCount: _tasksWithoutDate.length > 3
                    ? 4
                    : _tasksWithoutDate.length,
              ),
            ),
          ],

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Widget _buildTaskCard(LeadActivity task) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isOverdue = _isOverdue(task);

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isOverdue
            ? const BorderSide(color: Colors.red, width: 0)
            : BorderSide.none,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isOverdue
              ? const Border(left: BorderSide(color: Colors.red, width: 4))
              : null,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Navigate to lead detail
            Get.toNamed(AppRoutes.LEAD_DETAIL.replaceAll(':id', task.leadId));
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and priority
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title ?? 'Untitled Task',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (task.priority != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(
                            task.priority,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getPriorityColor(
                              task.priority,
                            ).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _getPriorityLabel(task.priority),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _getPriorityColor(task.priority),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Description
                if (task.description != null &&
                    task.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 8),

                // Lead name, status, and arrow
                Row(
                  children: [
                    // Lead name
                    if (task.lead != null) ...[
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          task.lead!.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],

                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          task.taskStatus,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusLabel(task.taskStatus),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _getStatusColor(task.taskStatus),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Arrow indicator
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

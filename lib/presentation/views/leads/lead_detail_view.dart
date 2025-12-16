import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/lead_controller.dart';
import '../../controllers/activity_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/staff_controller.dart';
import '../../controllers/category_controller.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart' as error_widget;
import '../../widgets/activity_card_widget.dart';
import '../../../data/models/lead_model.dart';
import '../../../data/models/activity_model.dart';
import 'package:intl/intl.dart';
import 'widgets/activity_form_dialog.dart';

class LeadDetailView extends StatefulWidget {
  final String leadId;

  const LeadDetailView({super.key, required this.leadId});

  @override
  State<LeadDetailView> createState() => _LeadDetailViewState();
}

class _LeadDetailViewState extends State<LeadDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LeadController _leadController = Get.find<LeadController>();
  final ActivityController _activityController = Get.put(ActivityController());
  final AuthController _authController = Get.find<AuthController>();
  final StaffController _staffController = Get.put(StaffController());
  final CategoryController _categoryController = Get.put(CategoryController());

  String _activityFilter = 'all'; // all, tasks, meetings, calls, notes

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  void _loadData() {
    _leadController.loadLeadById(widget.leadId);
    _activityController.refreshActivities(widget.leadId);
    if (_authController.shop != null) {
      _staffController.loadStaff(_authController.shop!.id);
      _categoryController.loadCategories(_authController.shop!.id);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getStatusColor(LeadStatus status) {
    switch (status) {
      case LeadStatus.newLead:
        return Colors.blue;
      case LeadStatus.contacted:
        return Colors.orange;
      case LeadStatus.qualified:
        return Colors.purple;
      case LeadStatus.converted:
        return Colors.green;
      case LeadStatus.lost:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(LeadStatus status) {
    switch (status) {
      case LeadStatus.newLead:
        return Icons.fiber_new;
      case LeadStatus.contacted:
        return Icons.phone;
      case LeadStatus.qualified:
        return Icons.verified;
      case LeadStatus.converted:
        return Icons.check_circle;
      case LeadStatus.lost:
        return Icons.cancel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final lead = _leadController.selectedLead;
          return Text(lead?.name ?? 'Lead Details');
        }),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _showEditLeadDialog();
                  break;
                case 'status':
                  _showStatusUpdateDialog();
                  break;
                case 'assign':
                  _showAssignStaffDialog();
                  break;
                case 'categories':
                  _showCategoryDialog();
                  break;
                case 'delete':
                  _showDeleteDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Edit Lead'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'status',
                child: Row(
                  children: [
                    Icon(Icons.change_circle, size: 20),
                    SizedBox(width: 8),
                    Text('Update Status'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'assign',
                child: Row(
                  children: [
                    Icon(Icons.person_add, size: 20),
                    SizedBox(width: 8),
                    Text('Assign Staff'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'categories',
                child: Row(
                  children: [
                    Icon(Icons.category, size: 20),
                    SizedBox(width: 8),
                    Text('Manage Categories'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Lead', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard_outlined)),
            Tab(text: 'Timeline', icon: Icon(Icons.history)),
            Tab(text: 'Tasks', icon: Icon(Icons.task_outlined)),
          ],
        ),
      ),
      body: Obx(() {
        if (_leadController.isLoading && _leadController.selectedLead == null) {
          return const LoadingWidget();
        }

        if (_leadController.errorMessage.isNotEmpty) {
          return error_widget.ErrorDisplayWidget(
            message: _leadController.errorMessage,
            onRetry: _loadData,
          );
        }

        final lead = _leadController.selectedLead;
        if (lead == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Lead not found'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await _leadController.loadLeadById(widget.leadId);
            await _activityController.refreshActivities(widget.leadId);
          },
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(lead, theme),
              _buildTimelineTab(),
              _buildTasksTab(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildOverviewTab(LeadWithRelationsModel lead, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats Cards
          _buildQuickStatsCards(theme),
          const SizedBox(height: 16),

          // Header Card with Status and Quick Actions
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Status Row
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: _getStatusColor(lead.status).withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _getStatusColor(lead.status).withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            lead.name.isNotEmpty
                                ? lead.name[0].toUpperCase()
                                : 'L',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(lead.status),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lead.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(lead.status)
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _getStatusColor(lead.status)
                                      .withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getStatusIcon(lead.status),
                                    size: 14,
                                    color: _getStatusColor(lead.status),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    LeadModel.statusToString(lead.status)
                                        .toUpperCase(),
                                    style: TextStyle(
                                      color: _getStatusColor(lead.status),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Quick Action Buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _showStatusUpdateDialog,
                        icon: const Icon(Icons.change_circle, size: 18),
                        label: const Text('Change Status'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showAddActivityDialog(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Activity'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      if (lead.phone != null || lead.email != null || lead.whatsapp != null)
                        OutlinedButton.icon(
                          onPressed: () => _showContactMenu(lead),
                          icon: const Icon(Icons.phone, size: 18),
                          label: const Text('Contact'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Assigned To Card
          if (lead.assignedUser != null)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      child: Text(
                        lead.assignedUser!.name[0].toUpperCase(),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assigned To',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lead.assignedUser!.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _showAssignStaffDialog,
                      child: const Text('Change'),
                    ),
                  ],
                ),
              ),
            ),
          if (lead.assignedUser == null) ...[
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: InkWell(
                onTap: _showAssignStaffDialog,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.person_add_outlined, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Assign to Staff',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Contact Information
          _buildSectionHeader('Contact Information'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (lead.email != null)
                    _buildInfoRow(Icons.email_outlined, 'Email', lead.email!,
                        onTap: () => _sendEmail(lead.email!)),
                  if (lead.phone != null)
                    _buildInfoRow(Icons.phone_outlined, 'Phone', lead.phone!,
                        onTap: () => _makeCall(lead.phone!)),
                  if (lead.whatsapp != null)
                    _buildInfoRow(Icons.chat_bubble_outline, 'WhatsApp',
                        lead.whatsapp!,
                        onTap: () => _openWhatsApp(lead.whatsapp!)),
                  if (lead.company != null)
                    _buildInfoRow(Icons.business_outlined, 'Company', lead.company!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Additional Information
          if (lead.address != null ||
              lead.occupation != null ||
              lead.fieldOfWork != null ||
              lead.source != null) ...[
            _buildSectionHeader('Additional Information'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (lead.source != null)
                      _buildInfoRow(
                        Icons.source,
                        'Source',
                        LeadModel.sourceToString(lead.source!),
                      ),
                    if (lead.address != null)
                      _buildInfoRow(
                          Icons.location_on_outlined, 'Address', lead.address!),
                    if (lead.occupation != null)
                      _buildInfoRow(
                          Icons.work_outline, 'Occupation', lead.occupation!),
                    if (lead.fieldOfWork != null)
                      _buildInfoRow(Icons.category_outlined, 'Field of Work',
                          lead.fieldOfWork!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Categories
          if (lead.categories.isNotEmpty) ...[
            _buildSectionHeader('Categories'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: lead.categories.map((category) {
                    final categoryColor = category.color != null &&
                            category.color!.isNotEmpty
                        ? Color(int.parse(
                            category.color!.replaceFirst('#', '0xFF')))
                        : Colors.grey;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: categoryColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: categoryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            category.name,
                            style: TextStyle(
                              color: categoryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Products
          if (lead.products != null && lead.products!.isNotEmpty) ...[
            _buildSectionHeader('Products'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: lead.products!.map((product) {
                    return Chip(
                      label: Text(product),
                      avatar: const Icon(Icons.shopping_bag_outlined, size: 16),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Notes
          if (lead.notes != null && lead.notes!.isNotEmpty) ...[
            _buildSectionHeader('Notes'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  lead.notes!,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Metadata
          _buildSectionHeader('Metadata'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow(
                    Icons.calendar_today_outlined,
                    'Created',
                    DateFormat('MMM dd, yyyy HH:mm').format(lead.createdAt),
                  ),
                  _buildInfoRow(
                    Icons.update_outlined,
                    'Last Updated',
                    DateFormat('MMM dd, yyyy HH:mm').format(lead.updatedAt),
                  ),
                  if (lead.createdByUser != null)
                    _buildInfoRow(
                      Icons.person_outline,
                      'Created By',
                      lead.createdByUser!.name,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsCards(ThemeData _) {
    return Obx(() {
      final activities = _activityController.activities;
      final pendingTasks = _activityController.pendingTasks;
      final lastActivity = activities.isNotEmpty ? activities.first : null;

      return Row(
        children: [
          Expanded(
            child: _buildStatCard(
              Theme.of(context),
              'Total Activities',
              activities.length.toString(),
              Icons.history,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              Theme.of(context),
              'Pending Tasks',
              pendingTasks.length.toString(),
              Icons.task_outlined,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              Theme.of(context),
              'Last Activity',
              lastActivity != null
                  ? DateFormat('MMM dd').format(lastActivity.createdAt)
                  : 'None',
              Icons.access_time,
              Colors.purple,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildStatCard(
    ThemeData theme,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey,
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineTab() {
    return Obx(() {
      if (_activityController.isLoading &&
          _activityController.activities.isEmpty) {
        return const LoadingWidget();
      }

      final activities = _getFilteredActivities();

      if (activities.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.history, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No activities yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _showAddActivityDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Activity'),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('tasks', 'Tasks'),
                  const SizedBox(width: 8),
                  _buildFilterChip('meetings', 'Meetings'),
                  const SizedBox(width: 8),
                  _buildFilterChip('calls', 'Calls'),
                  const SizedBox(width: 8),
                  _buildFilterChip('notes', 'Notes'),
                ],
              ),
            ),
          ),
          // Add Activity Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => _showAddActivityDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Activity'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
          // Timeline
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                final isLast = index == activities.length - 1;
                return _buildTimelineItem(activity, isLast);
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _activityFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _activityFilter = value;
        });
      },
    );
  }

  List<LeadActivity> _getFilteredActivities() {
    final allActivities = _activityController.activities;
    switch (_activityFilter) {
      case 'tasks':
        return allActivities
            .where((a) =>
                a.activityType == ActivityType.task ||
                a.activityType == ActivityType.taskCompleted)
            .toList();
      case 'meetings':
        return allActivities
            .where((a) =>
                a.activityType == ActivityType.meeting ||
                a.activityType == ActivityType.meetingCompleted)
            .toList();
      case 'calls':
        return allActivities
            .where((a) => a.activityType == ActivityType.call)
            .toList();
      case 'notes':
        return allActivities
            .where((a) => a.activityType == ActivityType.note)
            .toList();
      default:
        return allActivities;
    }
  }

  Widget _buildTimelineItem(LeadActivity activity, bool isLast) {
    final iconColor = _getActivityColor(activity.activityType);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline Line
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: iconColor, width: 2),
              ),
              child: Icon(
                _getActivityIcon(activity.activityType),
                color: iconColor,
                size: 16,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 80,
                color: Colors.grey.withOpacity(0.3),
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        const SizedBox(width: 12),
        // Activity Card
        Expanded(
          child: ActivityCardWidget(
            activity: activity,
            onTap: () {
              // Show activity details
            },
            onDelete: () {
              _deleteActivity(activity);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTasksTab() {
    return Obx(() {
      if (_activityController.pendingTasks.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.task_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No pending tasks',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _showAddActivityDialog(activityType: ActivityType.task),
                icon: const Icon(Icons.add),
                label: const Text('Add Task'),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => _showAddActivityDialog(activityType: ActivityType.task),
              icon: const Icon(Icons.add),
              label: const Text('Add Task'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _activityController.pendingTasks.length,
              itemBuilder: (context, index) {
                final task = _activityController.pendingTasks[index];
                return ActivityCardWidget(
                  activity: task,
                  onTap: () {
                    // Show task details or mark as complete
                    _markTaskComplete(task);
                  },
                  onDelete: () {
                    _deleteActivity(task);
                  },
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    final widget = Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            IconButton(
              icon: const Icon(Icons.open_in_new, size: 18),
              onPressed: onTap,
              color: Theme.of(context).colorScheme.primary,
            ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        child: widget,
      );
    }
    return widget;
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

  // Contact Actions
  void _showContactMenu(LeadWithRelationsModel lead) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: const Text('Call'),
              subtitle: lead.phone != null ? Text(lead.phone!) : null,
              enabled: lead.phone != null,
              onTap: lead.phone != null
                  ? () {
                      Navigator.pop(context);
                      _makeCall(lead.phone!);
                    }
                  : null,
            ),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.blue),
              title: const Text('Email'),
              subtitle: lead.email != null ? Text(lead.email!) : null,
              enabled: lead.email != null,
              onTap: lead.email != null
                  ? () {
                      Navigator.pop(context);
                      _sendEmail(lead.email!);
                    }
                  : null,
            ),
            if (lead.whatsapp != null)
              ListTile(
                leading: const Icon(Icons.chat, color: Colors.green),
                title: const Text('WhatsApp'),
                subtitle: Text(lead.whatsapp!),
                onTap: () {
                  Navigator.pop(context);
                  _openWhatsApp(lead.whatsapp!);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      Get.snackbar('Error', 'Could not make phone call',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      Get.snackbar('Error', 'Could not open email client',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final uri = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('Error', 'Could not open WhatsApp',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // Dialogs
  void _showAddActivityDialog({ActivityType? activityType}) {
    final lead = _leadController.selectedLead;
    if (lead == null || _authController.shop == null) return;

    showDialog(
      context: context,
      builder: (context) => ActivityFormDialog(
        leadId: lead.id,
        shopId: _authController.shop!.id,
        userId: _authController.user!.id,
        defaultActivityType: activityType,
        onCreate: (activity) async {
          final success = await _activityController.createActivity(
            lead.id,
            _authController.shop!.id,
            activity,
            _authController.user!.id,
          );
          if (success) {
            Get.back();
            Get.snackbar(
              'Success',
              'Activity created successfully',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
          } else {
            Get.snackbar(
              'Error',
              _activityController.errorMessage,
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        },
      ),
    );
  }

  void _showStatusUpdateDialog() {
    final lead = _leadController.selectedLead;
    if (lead == null) return;

    LeadStatus? selectedStatus = lead.status;

    Get.dialog(
      AlertDialog(
        title: const Text('Update Status'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: LeadStatus.values.map((status) {
                return RadioListTile<LeadStatus>(
                  title: Text(LeadModel.statusToString(status)),
                  value: status,
                  groupValue: selectedStatus,
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value;
                    });
                  },
                );
              }).toList(),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedStatus != null && selectedStatus != lead.status) {
                final input = CreateLeadInput(
                  name: lead.name,
                  email: lead.email,
                  phone: lead.phone,
                  whatsapp: lead.whatsapp,
                  company: lead.company,
                  address: lead.address,
                  occupation: lead.occupation,
                  fieldOfWork: lead.fieldOfWork,
                  source: lead.source,
                  notes: lead.notes,
                  status: selectedStatus,
                  assignedTo: lead.assignedTo,
                  categoryIds: lead.categories.map((c) => c.id).toList(),
                  products: lead.products,
                );
                final success =
                    await _leadController.updateLead(lead.id, input);
                Get.back();
                if (success) {
                  Get.snackbar(
                    'Success',
                    'Status updated successfully',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                } else {
                  Get.snackbar(
                    'Error',
                    _leadController.errorMessage,
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showAssignStaffDialog() {
    final lead = _leadController.selectedLead;
    if (lead == null || _authController.shop == null) return;

    String? selectedStaffId = lead.assignedTo;

    Get.dialog(
      AlertDialog(
        title: const Text('Assign Staff'),
        content: Obx(() {
          if (_staffController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String?>(
                    title: const Text('Unassigned'),
                    value: null,
                    groupValue: selectedStaffId,
                    onChanged: (value) {
                      setState(() {
                        selectedStaffId = value;
                      });
                    },
                  ),
                  ..._staffController.staffList
                      .where((s) => s.isActive)
                      .map((staff) {
                    return RadioListTile<String?>(
                      title: Text(staff.name),
                      subtitle: Text(staff.email),
                      value: staff.id,
                      groupValue: selectedStaffId,
                      onChanged: (value) {
                        setState(() {
                          selectedStaffId = value;
                        });
                      },
                    );
                  }),
                ],
              );
            },
          );
        }),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedStaffId != lead.assignedTo) {
                final input = CreateLeadInput(
                  name: lead.name,
                  email: lead.email,
                  phone: lead.phone,
                  whatsapp: lead.whatsapp,
                  company: lead.company,
                  address: lead.address,
                  occupation: lead.occupation,
                  fieldOfWork: lead.fieldOfWork,
                  source: lead.source,
                  notes: lead.notes,
                  status: lead.status,
                  assignedTo: selectedStaffId,
                  categoryIds: lead.categories.map((c) => c.id).toList(),
                  products: lead.products,
                );
                final success =
                    await _leadController.updateLead(lead.id, input);
                Get.back();
                if (success) {
                  Get.snackbar(
                    'Success',
                    'Staff assignment updated',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                } else {
                  Get.snackbar(
                    'Error',
                    _leadController.errorMessage,
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              }
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  void _showCategoryDialog() {
    final lead = _leadController.selectedLead;
    if (lead == null || _authController.shop == null) return;

    List<String> selectedCategoryIds =
        lead.categories.map((c) => c.id).toList();

    Get.dialog(
      AlertDialog(
        title: const Text('Manage Categories'),
        content: Obx(() {
          if (_categoryController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _categoryController.categories.length,
                  itemBuilder: (context, index) {
                    final category = _categoryController.categories[index];
                    final isSelected =
                        selectedCategoryIds.contains(category.id);
                    return CheckboxListTile(
                      title: Text(category.name),
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            selectedCategoryIds.add(category.id);
                          } else {
                            selectedCategoryIds.remove(category.id);
                          }
                        });
                      },
                    );
                  },
                ),
              );
            },
          );
        }),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final input = CreateLeadInput(
                name: lead.name,
                email: lead.email,
                phone: lead.phone,
                whatsapp: lead.whatsapp,
                company: lead.company,
                address: lead.address,
                occupation: lead.occupation,
                fieldOfWork: lead.fieldOfWork,
                source: lead.source,
                notes: lead.notes,
                status: lead.status,
                assignedTo: lead.assignedTo,
                categoryIds: selectedCategoryIds,
                products: lead.products,
              );
              final success =
                  await _leadController.updateLead(lead.id, input);
              Get.back();
              if (success) {
                Get.snackbar(
                  'Success',
                  'Categories updated',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } else {
                Get.snackbar(
                  'Error',
                  _leadController.errorMessage,
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showEditLeadDialog() {
    // Navigate to edit screen or show edit dialog
    Get.snackbar(
      'Edit Lead',
      'Edit functionality coming soon',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showDeleteDialog() {
    final lead = _leadController.selectedLead;
    if (lead == null || _authController.shop == null) return;

    Get.dialog(
      AlertDialog(
        title: const Text('Delete Lead'),
        content: const Text(
            'Are you sure you want to delete this lead? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await _leadController.deleteLead(
                lead.id,
                _authController.shop!.id,
              );
              Get.back();
              if (success) {
                Get.back(); // Close detail view
                Get.snackbar(
                  'Success',
                  'Lead deleted successfully',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } else {
                Get.snackbar(
                  'Error',
                  _leadController.errorMessage,
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteActivity(LeadActivity activity) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Activity'),
        content: const Text('Are you sure you want to delete this activity?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _activityController.deleteActivity(activity.id);
      if (success) {
        Get.snackbar(
          'Success',
          'Activity deleted',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          _activityController.errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  Future<void> _markTaskComplete(LeadActivity task) async {
    if (task.activityType != ActivityType.task) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Mark Task Complete'),
        content: const Text('Mark this task as completed?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final input = UpdateActivityInput(
        id: task.id,
        taskStatus: TaskStatus.completed,
        completedAt: DateTime.now(),
      );
      final success = await _activityController.updateActivity(task.id, input);
      if (success) {
        Get.snackbar(
          'Success',
          'Task marked as completed',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          _activityController.errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }
}

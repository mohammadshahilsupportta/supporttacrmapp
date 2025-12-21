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
import '../../../app/routes/app_routes.dart';

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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.12),
                  width: 1,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.primaryContainer,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: theme.colorScheme.onPrimaryContainer,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                unselectedLabelStyle: theme.textTheme.labelMedium?.copyWith(
                  fontSize: 13,
                ),
                padding: EdgeInsets.zero,
                tabs: const [
                  Tab(
                    height: 48,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.dashboard_outlined, size: 18),
                        SizedBox(width: 6),
                        Text('Overview'),
                      ],
                    ),
                  ),
                  Tab(
                    height: 48,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history, size: 18),
                        SizedBox(width: 6),
                        Text('Timeline'),
                      ],
                    ),
                  ),
                  Tab(
                    height: 48,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.task_outlined, size: 18),
                        SizedBox(width: 6),
                        Text('Tasks'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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

        return TabBarView(
          controller: _tabController,
          children: [
            RefreshIndicator(
              onRefresh: () async {
                await _leadController.loadLeadById(widget.leadId);
                await _activityController.refreshActivities(widget.leadId);
              },
              child: _buildOverviewTab(lead, theme),
            ),
            RefreshIndicator(
              onRefresh: () async {
                await _leadController.loadLeadById(widget.leadId);
                await _activityController.refreshActivities(widget.leadId);
              },
              child: _buildTimelineTab(),
            ),
            RefreshIndicator(
              onRefresh: () async {
                await _leadController.loadLeadById(widget.leadId);
                await _activityController.refreshActivities(widget.leadId);
              },
              child: _buildTasksTab(),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildOverviewTab(LeadWithRelationsModel lead, ThemeData theme) {
    // Extract requirement from notes
    String? requirement;
    if (lead.notes != null && lead.notes!.isNotEmpty) {
      final requirementMatch = RegExp(r'REQUIREMENT:\n([\s\S]*?)(?:\n\n|$)')
          .firstMatch(lead.notes!);
      requirement = requirementMatch?.group(1)?.trim();
      if (requirement != null && requirement.isEmpty) {
        requirement = null;
      }
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
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

          // Requirement (extracted from notes)
          if (requirement != null && requirement.isNotEmpty) ...[
            _buildSectionHeader('Requirement'),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What the lead is looking for',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      requirement,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
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

      final lead = _leadController.selectedLead;
      final score = lead?.score;
      final scoreCategory = lead?.scoreCategory;

      return Column(
        children: [
          Row(
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
          ),
          if (score != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    Theme.of(context),
                    'Lead Score',
                    '$score',
                    _getScoreIcon(scoreCategory),
                    _getScoreColor(score, scoreCategory),
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    });
  }

  Color _getScoreColor(int score, String? category) {
    if (category != null) {
      switch (category.toLowerCase()) {
        case 'hot':
          return Colors.red;
        case 'warm':
          return Colors.orange;
        case 'cold':
          return Colors.blue;
        default:
          return Colors.grey;
      }
    }
    if (score >= 75) return Colors.red;
    if (score >= 50) return Colors.orange;
    if (score >= 25) return Colors.blue;
    return Colors.grey;
  }

  IconData _getScoreIcon(String? category) {
    if (category != null) {
      switch (category.toLowerCase()) {
        case 'hot':
          return Icons.local_fire_department;
        case 'warm':
          return Icons.wb_sunny;
        case 'cold':
          return Icons.ac_unit;
        default:
          return Icons.star;
      }
    }
    return Icons.star;
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

      return Column(
        children: [
          // Filter Chips - Always visible
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
          // Add Note Button - Always visible
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _showAddActivityDialog(activityType: ActivityType.note);
                });
              },
              icon: const Icon(Icons.note_add),
              label: const Text('Add Note'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
          // Timeline - Shows activities or empty state
          Expanded(
            child: activities.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.history, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              _activityController.activities.isEmpty
                                  ? 'No activities yet'
                                  : 'No ${_getFilterLabel()} found',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey,
                                  ),
                            ),
                            const SizedBox(height: 8),
                        if (_activityController.activities.isEmpty)
                          ElevatedButton.icon(
                            onPressed: () {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _showAddActivityDialog(activityType: ActivityType.note);
                              });
                            },
                            icon: const Icon(Icons.note_add),
                            label: const Text('Add Note'),
                          ),
                          ],
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
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

  String _getFilterLabel() {
    switch (_activityFilter) {
      case 'tasks':
        return 'tasks';
      case 'meetings':
        return 'meetings';
      case 'calls':
        return 'calls';
      case 'notes':
        return 'notes';
      default:
        return 'activities';
    }
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _activityFilter == value;
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected 
              ? Colors.white 
              : theme.colorScheme.onSurface,
        ),
      ),
      selected: isSelected,
      selectedColor: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surface,
      checkmarkColor: Colors.white,
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
          ),
        ),
      ],
    );
  }

  Widget _buildTasksTab() {
    return Obx(() {
      if (_activityController.pendingTasks.isEmpty) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
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
                    onPressed: () {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _showAddActivityDialog(activityType: ActivityType.task);
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Task'),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _showAddActivityDialog(activityType: ActivityType.task);
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Task'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: _activityController.pendingTasks.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4,
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _activityController.pendingTasks.length,
              itemBuilder: (context, index) {
                final task = _activityController.pendingTasks[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Dismissible(
                    key: Key(task.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 28,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Complete',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      // Mark as complete without showing dialog
                      await _markTaskCompleteSwipe(task);
                      return true; // Dismiss the item
                    },
                    onDismissed: (direction) {
                      // Task is already marked as complete in confirmDismiss
                    },
                    child: Card(
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Activity content (replicating ActivityCardWidget structure)
                          _buildTaskCardContent(task),
                          // Swipe indicator at bottom - always visible
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                              border: Border(
                                top: BorderSide(
                                  color: Colors.green.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.swipe_left,
                                  size: 18,
                                  color: Colors.green.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Swipe left to complete',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildTaskCardContent(LeadActivity task) {
    final theme = Theme.of(context);
    final iconColor = Colors.blue; // Task color
    final displayText = task.title ?? task.description ?? '';

    return InkWell(
      onTap: () {
        _markTaskComplete(task);
      },
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
                Icons.task,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (displayText.isNotEmpty) ...[
                    Text(
                      displayText,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (task.dueDate != null) ...[
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Due: ${DateFormat('MMM dd, hh:mm a').format(task.dueDate!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (task.priority != null || task.taskStatus != null) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (task.priority != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(task.priority!).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getPriorityColor(task.priority!).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.flag,
                                  size: 12,
                                  color: _getPriorityColor(task.priority!),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  task.priority.toString().split('.').last.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _getPriorityColor(task.priority!),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (task.taskStatus != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getTaskStatusColor(task.taskStatus!).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getTaskStatusColor(task.taskStatus!).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              task.taskStatusString!.replaceAll('_', ' ').toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _getTaskStatusColor(task.taskStatus!),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      if (task.performedByUser != null) ...[
                        Icon(Icons.person, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          task.performedByUser!.name,
                          style: theme.textTheme.bodySmall?.copyWith(
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
                        task.scheduledAt != null
                            ? DateFormat('MMM dd, hh:mm a').format(task.scheduledAt!)
                            : DateFormat('MMM dd, hh:mm a').format(task.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () {
                _deleteActivity(task, isTask: true);
              },
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
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
          // Create activity (dialog will handle loading state)
          final success = await _activityController.createActivity(
            lead.id,
            _authController.shop!.id,
            activity,
            _authController.user!.id,
          );
          
          // Close dialog after operation completes
          if (context.mounted) {
            Navigator.of(context).pop();
          }
          
          // Wait a bit for state updates to complete
          await Future.delayed(const Duration(milliseconds: 100));
          
          if (success) {
            Get.snackbar(
              'Success',
              'Activity created successfully',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
          } else {
            // Get error message after state update
            final errorMsg = _activityController.errorMessage;
            Get.snackbar(
              'Error',
              errorMsg.isNotEmpty ? errorMsg : 'Failed to create activity',
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
    final lead = _leadController.selectedLead;
    if (lead == null) {
      Get.snackbar(
        'Error',
        'Lead data not available',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    Get.toNamed(
      AppRoutes.LEAD_EDIT.replaceAll(':id', lead.id),
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

  Future<void> _deleteActivity(LeadActivity activity, {bool isTask = false}) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(isTask ? 'Delete Task' : 'Delete Activity'),
        content: Text(isTask 
            ? 'Are you sure you want to delete this task?'
            : 'Are you sure you want to delete this activity?'),
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
          isTask ? 'Task deleted' : 'Activity deleted',
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
      await _markTaskCompleteSwipe(task);
    }
  }

  Future<void> _markTaskCompleteSwipe(LeadActivity task) async {
    if (task.activityType != ActivityType.task) return;

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
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    } else {
      Get.snackbar(
        'Error',
        _activityController.errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/lead_controller.dart';
import '../../controllers/activity_controller.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart' as error_widget;
import '../../widgets/activity_card_widget.dart';
import '../../../data/models/lead_model.dart';
import '../../../data/models/activity_model.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Delay loading until after the widget tree is built to avoid build conflicts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  void _loadData() {
    _leadController.loadLeadById(widget.leadId);
    _activityController.refreshActivities(widget.leadId);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final lead = _leadController.selectedLead;
          return Text(lead?.name ?? 'Lead Details');
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit lead
              // Get.toNamed(AppRoutes.LEAD_EDIT, arguments: widget.leadId);
            },
            tooltip: 'Edit Lead',
          ),
          IconButton(
            icon: const Icon(Icons.add_task),
            onPressed: () {
              _showAddActivityDialog();
            },
            tooltip: 'Add Activity',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Details', icon: Icon(Icons.info)),
            Tab(text: 'Activities', icon: Icon(Icons.history)),
            Tab(text: 'Tasks', icon: Icon(Icons.task)),
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
              _buildDetailsTab(lead),
              _buildActivitiesTab(),
              _buildTasksTab(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDetailsTab(LeadWithRelationsModel lead) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Chip(
                        label: Text(
                          LeadModel.statusToString(lead.status).toUpperCase(),
                        ),
                        backgroundColor: _getStatusColor(lead.status).withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: _getStatusColor(lead.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (lead.assignedUser != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Assigned To',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lead.assignedUser!.name,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Contact Information
          _buildSectionHeader('Contact Information'),
          _buildInfoCard([
            if (lead.email != null)
              _buildInfoRow(Icons.email, 'Email', lead.email!),
            if (lead.phone != null)
              _buildInfoRow(Icons.phone, 'Phone', lead.phone!),
            if (lead.whatsapp != null)
              _buildInfoRow(Icons.chat, 'WhatsApp', lead.whatsapp!),
            if (lead.company != null)
              _buildInfoRow(Icons.business, 'Company', lead.company!),
          ]),

          // Additional Information
          if (lead.address != null ||
              lead.occupation != null ||
              lead.fieldOfWork != null) ...[
            const SizedBox(height: 16),
            _buildSectionHeader('Additional Information'),
            _buildInfoCard([
              if (lead.address != null)
                _buildInfoRow(Icons.location_on, 'Address', lead.address!),
              if (lead.occupation != null)
                _buildInfoRow(Icons.work, 'Occupation', lead.occupation!),
              if (lead.fieldOfWork != null)
                _buildInfoRow(Icons.category, 'Field of Work', lead.fieldOfWork!),
            ]),
          ],

          // Products
          if (lead.products != null && lead.products!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSectionHeader('Products'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: lead.products!.map((product) {
                    return Chip(
                      label: Text(product),
                      avatar: const Icon(Icons.shopping_bag, size: 16),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],

          // Categories
          if (lead.categories.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSectionHeader('Categories'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: lead.categories.map((category) {
                    return Chip(
                      label: Text(category.name),
                      backgroundColor: category.color != null
                          ? Color(int.parse(category.color!.replaceFirst('#', '0xFF')))
                              .withOpacity(0.2)
                          : null,
                    );
                  }).toList(),
                ),
              ),
            ),
          ],

          // Notes
          if (lead.notes != null && lead.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSectionHeader('Notes'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  lead.notes!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],

          // Metadata
          const SizedBox(height: 16),
          _buildSectionHeader('Metadata'),
          _buildInfoCard([
            _buildInfoRow(
              Icons.calendar_today,
              'Created',
              DateFormat('MMM dd, yyyy HH:mm').format(lead.createdAt),
            ),
            _buildInfoRow(
              Icons.update,
              'Last Updated',
              DateFormat('MMM dd, yyyy HH:mm').format(lead.updatedAt),
            ),
            if (lead.createdByUser != null)
              _buildInfoRow(
                Icons.person,
                'Created By',
                lead.createdByUser!.name,
              ),
          ]),
        ],
      ),
    );
  }

  Widget _buildActivitiesTab() {
    return Obx(() {
      if (_activityController.isLoading &&
          _activityController.activities.isEmpty) {
        return const LoadingWidget();
      }

      if (_activityController.activities.isEmpty) {
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
                onPressed: _showAddActivityDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Activity'),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _activityController.activities.length,
        itemBuilder: (context, index) {
          final activity = _activityController.activities[index];
          return ActivityCardWidget(
            activity: activity,
            onTap: () {
              // Show activity details or edit
            },
            onDelete: () {
              _deleteActivity(activity);
            },
          );
        },
      );
    });
  }

  Widget _buildTasksTab() {
    return Obx(() {
      if (_activityController.pendingTasks.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.task, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No pending tasks',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _activityController.pendingTasks.length,
        itemBuilder: (context, index) {
          final task = _activityController.pendingTasks[index];
          return ActivityCardWidget(
            activity: task,
            onTap: () {
              // Show task details or mark as complete
            },
            onDelete: () {
              _deleteActivity(task);
            },
          );
        },
      );
    });
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddActivityDialog() {
    // TODO: Show dialog to create activity
    // For now, just show a snackbar
    Get.snackbar(
      'Add Activity',
      'Activity creation form coming soon',
      snackPosition: SnackPosition.BOTTOM,
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
        );
      } else {
        Get.snackbar(
          'Error',
          _activityController.errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
        );
      }
    }
  }
}


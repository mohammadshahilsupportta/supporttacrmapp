import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/staff_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/category_controller.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart' as error_widget;
import '../../../data/models/staff_model.dart';
import '../../../data/models/user_model.dart';
import 'widgets/category_permissions_dialog.dart';
import 'package:intl/intl.dart';

class StaffDetailView extends StatefulWidget {
  final String staffId;

  const StaffDetailView({super.key, required this.staffId});

  @override
  State<StaffDetailView> createState() => _StaffDetailViewState();
}

class _StaffDetailViewState extends State<StaffDetailView> {
  final StaffController _staffController = Get.find<StaffController>();
  final AuthController _authController = Get.find<AuthController>();
  final CategoryController _categoryController = Get.put(CategoryController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  void _loadData() {
    _staffController.loadStaffWithPermissions(widget.staffId);
    if (_authController.shop != null) {
      _categoryController.loadCategories(_authController.shop!.id);
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.shopOwner:
        return Colors.purple;
      case UserRole.admin:
        return Colors.blue;
      case UserRole.marketingManager:
        return Colors.green;
      case UserRole.officeStaff:
        return Colors.blue;
      case UserRole.freelance:
        return Colors.teal;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.shopOwner:
        return Icons.shield;
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.marketingManager:
        return Icons.trending_up;
      case UserRole.officeStaff:
        return Icons.business_center;
      case UserRole.freelance:
        return Icons.person;
    }
  }

  String _getUserInitials(String name) {
    final parts = name.split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'S';
  }

  bool _canManageStaff(UserModel? user) {
    if (user == null) return false;
    return user.role == UserRole.shopOwner || user.role == UserRole.admin;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canManage = _canManageStaff(_authController.user);

    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final staff = _staffController.selectedStaff;
          return Text(staff?.name ?? 'Staff Details');
        }),
        actions: canManage
            ? [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'toggle':
                        _toggleActive();
                        break;
                      case 'categories':
                        _showManageCategoriesDialog();
                        break;
                      case 'delete':
                        _showDeleteDialog();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            _staffController.selectedStaff?.isActive == true
                                ? Icons.toggle_on
                                : Icons.toggle_off,
                            size: 20,
                            color: _staffController.selectedStaff?.isActive == true
                                ? Colors.green
                                : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(_staffController.selectedStaff?.isActive == true
                              ? 'Deactivate'
                              : 'Activate'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'categories',
                      child: Row(
                        children: [
                          Icon(Icons.folder_open, size: 20),
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
                          Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ]
            : null,
      ),
      body: Obx(() {
        if (_staffController.isLoading && _staffController.selectedStaff == null) {
          return const LoadingWidget();
        }

        if (_staffController.errorMessage.isNotEmpty) {
          return error_widget.ErrorDisplayWidget(
            message: _staffController.errorMessage,
            onRetry: _loadData,
          );
        }

        final staff = _staffController.selectedStaff;
        if (staff == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Staff member not found'),
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
            await _staffController.loadStaffWithPermissions(widget.staffId);
            if (_authController.shop != null) {
              await _categoryController.loadCategories(_authController.shop!.id);
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                _buildHeaderCard(staff, theme),
                const SizedBox(height: 16),

                // Information Card
                _buildInformationCard(staff, theme),
                const SizedBox(height: 16),

                // Category Permissions Card
                _buildCategoryPermissionsCard(staff, theme),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeaderCard(StaffWithPermissionsModel staff, ThemeData theme) {
    final roleColor = _getRoleColor(staff.role);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: roleColor.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _getUserInitials(staff.name),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: roleColor,
                        letterSpacing: 0.5,
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
                        staff.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Role Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: roleColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getRoleIcon(staff.role),
                              size: 16,
                              color: roleColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              UserModel.roleDisplayName(staff.role),
                              style: TextStyle(
                                color: roleColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
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
                          color: (staff.isActive ? Colors.green : Colors.red)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (staff.isActive ? Colors.green : Colors.red)
                                .withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              staff.isActive
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              size: 16,
                              color: staff.isActive ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              staff.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                color: staff.isActive ? Colors.green : Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
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
          ],
        ),
      ),
    );
  }

  Widget _buildInformationCard(StaffWithPermissionsModel staff, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Information',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              theme,
              Icons.email_outlined,
              'Email',
              staff.email,
              Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              theme,
              Icons.person_outline,
              'Role',
              UserModel.roleDisplayName(staff.role),
              _getRoleColor(staff.role),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              theme,
              Icons.calendar_today_outlined,
              'Created',
              DateFormat('MMM dd, yyyy').format(staff.createdAt),
              Colors.grey,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              theme,
              Icons.update_outlined,
              'Last Updated',
              DateFormat('MMM dd, yyyy').format(staff.updatedAt),
              Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPermissionsCard(
    StaffWithPermissionsModel staff,
    ThemeData theme,
  ) {
    final roleColor = _getRoleColor(staff.role);
    final hasAllCategories = staff.role == UserRole.marketingManager ||
        staff.role == UserRole.admin ||
        staff.role == UserRole.shopOwner;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Category Permissions',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_canManageStaff(_authController.user))
                  TextButton.icon(
                    onPressed: _showManageCategoriesDialog,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Manage'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (hasAllCategories)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: roleColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: roleColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Has access to all categories',
                      style: TextStyle(
                        color: roleColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else if (staff.categoryPermissions.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'No category permissions assigned',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: staff.categoryPermissions.map((category) {
                  final catColor = category.color != null &&
                          category.color!.isNotEmpty
                      ? Color(int.parse(
                          category.color!.replaceFirst('#', '0xFF')))
                      : roleColor;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: catColor.withValues(alpha: 0.3),
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
                            color: catColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          category.name,
                          style: TextStyle(
                            color: catColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  void _toggleActive() async {
    final staff = _staffController.selectedStaff;
    if (staff == null) return;

    final newStatus = !staff.isActive;
    final success = newStatus
        ? await _staffController.updateStaff(
            UpdateStaffInput(
              id: staff.id,
              isActive: true,
            ),
          )
        : await _staffController.deactivateStaff(staff.id);

    if (success) {
      Get.snackbar(
        'Success',
        'Staff member ${newStatus ? 'activated' : 'deactivated'} successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      // Reload staff data
      await _staffController.loadStaffWithPermissions(widget.staffId);
    } else {
      Get.snackbar(
        'Error',
        _staffController.errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _showManageCategoriesDialog() {
    final staff = _staffController.selectedStaff;
    if (staff == null || _authController.shop == null) return;

    showDialog(
      context: context,
      builder: (context) => CategoryPermissionsDialog(
        staff: staff,
        categories: _categoryController.categories,
        selectedCategoryIds: staff.categoryPermissions.map((c) => c.id).toList(),
        onSave: (categoryIds) async {
          final success = await _staffController.assignCategories(
            staff.id,
            _authController.shop!.id,
            categoryIds,
          );
          if (success) {
            Get.back();
            Get.snackbar(
              'Success',
              'Category permissions updated successfully',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white,
              duration: const Duration(seconds: 2),
            );
            // Reload staff data
            await _staffController.loadStaffWithPermissions(widget.staffId);
          } else {
            Get.snackbar(
              'Error',
              _staffController.errorMessage,
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
              duration: const Duration(seconds: 3),
            );
          }
        },
      ),
    );
  }

  void _showDeleteDialog() {
    final staff = _staffController.selectedStaff;
    if (staff == null) return;

    Get.dialog(
      AlertDialog(
        title: const Text('Delete Staff Member'),
        content: Text(
          'Are you sure you want to permanently delete ${staff.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              final success = await _staffController.deleteStaff(staff.id);
              if (success) {
                Get.snackbar(
                  'Success',
                  'Staff member deleted permanently',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 2),
                );
                Get.back(); // Navigate back to staff list
              } else {
                Get.snackbar(
                  'Error',
                  _staffController.errorMessage,
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 3),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}


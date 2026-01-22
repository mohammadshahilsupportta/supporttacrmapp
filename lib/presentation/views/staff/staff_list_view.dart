import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/staff_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/category_controller.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart' as error_widget;
import '../../../data/models/staff_model.dart';
import '../../../data/models/user_model.dart';
import '../../../app/routes/app_routes.dart';
import 'widgets/staff_card_widget.dart';
import 'widgets/category_permissions_dialog.dart';

class StaffListView extends StatefulWidget {
  const StaffListView({super.key});

  @override
  State<StaffListView> createState() => _StaffListViewState();
}

class _StaffListViewState extends State<StaffListView>
    with WidgetsBindingObserver {
  bool _hasInitialized = false;
  Worker? _shopWorker;
  final TextEditingController _searchController = TextEditingController();

  bool _canManageStaff(UserModel? user) {
    if (user == null) return false;
    return user.role == UserRole.shopOwner || user.role == UserRole.admin;
  }

  void _loadDataIfNeeded(
    AuthController authController,
    StaffController staffController,
    CategoryController categoryController, {
    bool force = false,
  }) {
    if (authController.shop != null) {
      if (force ||
          (staffController.staffList.isEmpty && !staffController.isLoading)) {
        staffController.loadStaff(authController.shop!.id, force: force);
      }
      if (categoryController.categories.isEmpty &&
          !categoryController.isLoading) {
        categoryController.loadCategories(authController.shop!.id);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final authController = Get.find<AuthController>();
    final staffController = Get.put(StaffController());
    final categoryController = Get.put(CategoryController());

    // Load staff and categories when view is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasInitialized) {
        _hasInitialized = true;
        _loadDataIfNeeded(authController, staffController, categoryController);
      }
    });

    // Use a worker to listen to shop changes and load staff when shop becomes available
    _shopWorker = ever(authController.shopRx, (shop) {
      if (shop != null && mounted) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _loadDataIfNeeded(
              authController,
              staffController,
              categoryController,
            );
          }
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      final authController = Get.find<AuthController>();
      final staffController = Get.find<StaffController>();
      final categoryController = Get.find<CategoryController>();
      _loadDataIfNeeded(
        authController,
        staffController,
        categoryController,
        force: true,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _shopWorker?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<StaffWithPermissionsModel> _filterStaff(
    List<StaffWithPermissionsModel> staffList,
    String query,
  ) {
    if (query.trim().isEmpty) {
      return staffList;
    }

    final searchLower = query.toLowerCase().trim();
    return staffList.where((staff) {
      final nameMatch = staff.name.toLowerCase().contains(searchLower);
      final emailMatch = staff.email.toLowerCase().contains(searchLower);
      final roleMatch = UserModel.roleDisplayName(
        staff.role,
      ).toLowerCase().contains(searchLower);
      return nameMatch || emailMatch || roleMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final staffController = Get.find<StaffController>();
    final categoryController = Get.find<CategoryController>();

    final canManage = _canManageStaff(authController.user);

    return Obx(() {
      if (staffController.isLoading && staffController.staffList.isEmpty) {
        return const LoadingWidget();
      }

      if (staffController.errorMessage.isNotEmpty) {
        return error_widget.ErrorDisplayWidget(
          message: staffController.errorMessage,
          onRetry: () {
            if (authController.shop != null) {
              staffController.loadStaff(authController.shop!.id);
            }
          },
        );
      }

      if (staffController.staffList.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.people_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No staff members yet',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your first staff member to get started',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              if (canManage) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Get.toNamed(AppRoutes.staffCreate);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Staff'),
                ),
              ],
            ],
          ),
        );
      }

      final filteredStaff = _filterStaff(
        staffController.staffList,
        _searchController.text,
      );

      return RefreshIndicator(
        onRefresh: () async {
          if (authController.shop != null) {
            await staffController.loadStaff(authController.shop!.id);
            await categoryController.loadCategories(authController.shop!.id);
          }
        },
        child: Column(
          children: [
            // Search field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name, email, or role',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() => _searchController.clear());
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            // Staff list
            Expanded(
              child: filteredStaff.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No staff found',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your search',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: filteredStaff.length,
                      itemBuilder: (context, index) {
                        final staff = filteredStaff[index];
                        return StaffCardWidget(
                          staff: staff,
                          canManage: canManage,
                          onTap: () {
                            // Navigate to staff detail page
                            Get.toNamed(
                              AppRoutes.staffDetail.replaceAll(':id', staff.id),
                            );
                          },
                          onToggleActive: () async {
                            final newStatus = !staff.isActive;
                            final success = newStatus
                                ? await staffController.updateStaff(
                                    UpdateStaffInput(
                                      id: staff.id,
                                      isActive: true,
                                    ),
                                  )
                                : await staffController.deactivateStaff(
                                    staff.id,
                                  );

                            if (success) {
                              Get.snackbar(
                                'Success',
                                'Staff member ${newStatus ? 'activated' : 'deactivated'} successfully',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.green,
                                colorText: Colors.white,
                              );
                            } else {
                              Get.snackbar(
                                'Error',
                                staffController.errorMessage,
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                            }
                          },
                          onManageCategories: () {
                            showDialog(
                              context: context,
                              builder: (context) => CategoryPermissionsDialog(
                                staff: staff,
                                categories: categoryController.categories,
                                selectedCategoryIds: staff.categoryPermissions
                                    .map((c) => c.id)
                                    .toList(),
                                onSave: (categoryIds) async {
                                  if (authController.shop != null) {
                                    final success = await staffController
                                        .assignCategories(
                                          staff.id,
                                          authController.shop!.id,
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
                                      );
                                    } else {
                                      Get.snackbar(
                                        'Error',
                                        staffController.errorMessage,
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                    }
                                  }
                                },
                              ),
                            );
                          },
                          onDelete: () {
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
                                      final success = await staffController
                                          .deleteStaff(staff.id);
                                      if (success) {
                                        Get.snackbar(
                                          'Success',
                                          'Staff member deleted permanently',
                                          snackPosition: SnackPosition.BOTTOM,
                                          backgroundColor: Colors.green,
                                          colorText: Colors.white,
                                        );
                                      } else {
                                        Get.snackbar(
                                          'Error',
                                          staffController.errorMessage,
                                          snackPosition: SnackPosition.BOTTOM,
                                          backgroundColor: Colors.red,
                                          colorText: Colors.white,
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
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    });
  }
}

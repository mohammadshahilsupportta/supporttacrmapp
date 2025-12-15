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

class _StaffListViewState extends State<StaffListView> {
  bool _hasInitialized = false;
  Worker? _shopWorker;

  bool _canManageStaff(UserModel? user) {
    if (user == null) return false;
    return user.role == UserRole.shopOwner || user.role == UserRole.admin;
  }

  void _loadDataIfNeeded(
    AuthController authController,
    StaffController staffController,
    CategoryController categoryController,
  ) {
    if (authController.shop != null) {
      if (staffController.staffList.isEmpty && !staffController.isLoading) {
        staffController.loadStaff(authController.shop!.id);
      }
      if (categoryController.categories.isEmpty && !categoryController.isLoading) {
        categoryController.loadCategories(authController.shop!.id);
      }
    }
  }

  @override
  void initState() {
    super.initState();
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
    _shopWorker = ever(
      authController.shopRx,
      (shop) {
        if (shop != null && mounted) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              _loadDataIfNeeded(authController, staffController, categoryController);
            }
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _shopWorker?.dispose();
    super.dispose();
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your first staff member to get started',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              if (canManage) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Get.toNamed(AppRoutes.STAFF_CREATE);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Staff'),
                ),
              ],
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          if (authController.shop != null) {
            await staffController.loadStaff(authController.shop!.id);
            await categoryController.loadCategories(authController.shop!.id);
          }
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: staffController.staffList.length,
          itemBuilder: (context, index) {
            final staff = staffController.staffList[index];
            return StaffCardWidget(
              staff: staff,
              canManage: canManage,
              onTap: () {
                // Navigate to staff detail page
                // Get.toNamed(AppRoutes.STAFF_DETAIL.replaceAll(':id', staff.id));
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
                    : await staffController.deactivateStaff(staff.id);

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
                        final success = await staffController.assignCategories(
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
                          final success =
                              await staffController.deleteStaff(staff.id);
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
      );
    });
  }
}

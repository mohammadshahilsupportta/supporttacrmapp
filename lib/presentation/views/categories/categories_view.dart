import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/category_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart' as error_widget;
import '../../../data/models/category_model.dart';
import '../../../data/models/user_model.dart';
import '../../widgets/category_card_widget.dart';
import 'widgets/category_form_dialog.dart';

class CategoriesView extends StatefulWidget {
  const CategoriesView({super.key});

  @override
  State<CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<CategoriesView> {
  bool _hasInitialized = false;
  Worker? _shopWorker;

  bool _hasPermission(UserModel? user) {
    if (user == null) return false;
    return user.role == UserRole.shopOwner || user.role == UserRole.admin;
  }

  void _loadDataIfNeeded(
    AuthController authController,
    CategoryController categoryController,
  ) {
    if (authController.shop != null) {
      if (categoryController.categories.isEmpty &&
          !categoryController.isLoading) {
        categoryController.loadCategories(authController.shop!.id);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final authController = Get.find<AuthController>();
    final categoryController = Get.put(CategoryController());

    // Load categories when view is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasInitialized) {
        _hasInitialized = true;
        _loadDataIfNeeded(authController, categoryController);
      }
    });

    // Use a worker to listen to shop changes
    _shopWorker = ever(
      authController.shopRx,
      (shop) {
        if (shop != null && mounted) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              _loadDataIfNeeded(authController, categoryController);
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

  Future<void> _handleCreate(CreateCategoryInput input) async {
    final authController = Get.find<AuthController>();
    final categoryController = Get.find<CategoryController>();

    if (authController.shop == null) {
      Get.snackbar(
        'Error',
        'Shop information not available',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final success = await categoryController.createCategory(
      authController.shop!.id,
      input,
    );

    if (success) {
      Get.back();
      Get.snackbar(
        'Success',
        'Category created successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        categoryController.errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _handleUpdate(UpdateCategoryInput input) async {
    final categoryController = Get.find<CategoryController>();

    final success = await categoryController.updateCategory(input);

    if (success) {
      Get.back();
      Get.snackbar(
        'Success',
        'Category updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        categoryController.errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _handleDelete(CategoryModel category) async {
    final authController = Get.find<AuthController>();
    final categoryController = Get.find<CategoryController>();

    if (authController.shop == null) {
      return;
    }

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${category.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await categoryController.deleteCategory(
        category.id,
        authController.shop!.id,
      );

      if (success) {
        Get.snackbar(
          'Success',
          'Category deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          categoryController.errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  void _openFormDialog({CategoryModel? category}) {
    showDialog(
      context: context,
      builder: (context) => CategoryFormDialog(
        category: category,
        onCreate: _handleCreate,
        onUpdate: _handleUpdate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final categoryController = Get.find<CategoryController>();

    final hasPermission = _hasPermission(authController.user);

    if (!hasPermission) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              "You don't have permission to access this page.",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      );
    }

    return Obx(() {
      if (categoryController.isLoading && categoryController.categories.isEmpty) {
        return const LoadingWidget();
      }

      if (categoryController.errorMessage.isNotEmpty) {
        return error_widget.ErrorDisplayWidget(
          message: categoryController.errorMessage,
          onRetry: () {
            if (authController.shop != null) {
              categoryController.loadCategories(authController.shop!.id);
            }
          },
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          if (authController.shop != null) {
            await categoryController.loadCategories(authController.shop!.id);
          }
        },
        child: categoryController.categories.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.category_outlined,
                        size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'No categories yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first category to organize your leads',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _openFormDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Your First Category'),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categoryController.categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final category = categoryController.categories[index];
                  return CategoryCardWidget(
                    category: category,
                    onEdit: () => _openFormDialog(category: category),
                    onDelete: () => _handleDelete(category),
                  );
                },
              ),
      );
    });
  }
}

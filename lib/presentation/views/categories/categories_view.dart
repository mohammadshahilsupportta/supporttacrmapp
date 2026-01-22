import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/category_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart' as error_widget;
import '../../../data/models/category_model.dart';
import '../../../data/models/user_model.dart';
import '../../../app/routes/app_routes.dart';
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
  final TextEditingController _searchController = TextEditingController();

  bool _canModifyCategories(UserModel? user) {
    // Only shop owner and admin can edit/delete categories
    if (user == null) return false;
    return user.role == UserRole.shopOwner || user.role == UserRole.admin;
  }

  bool _canAddCategories(UserModel? user) {
    // Staff can add categories but not edit/delete
    if (user == null) return false;
    return user.role == UserRole.shopOwner ||
        user.role == UserRole.admin ||
        user.role == UserRole.officeStaff ||
        user.role == UserRole.marketingManager ||
        user.role == UserRole.freelance;
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
    _shopWorker = ever(authController.shopRx, (shop) {
      if (shop != null && mounted) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _loadDataIfNeeded(authController, categoryController);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _shopWorker?.dispose();
    _searchController.dispose();
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

    final success = await categoryController.updateCategory(
      input,
      shopId: authController.shop!.id,
    );

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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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

    return Obx(() {
      // Allow all authenticated users to view categories
      // Only restrict if user is not authenticated
      if (!authController.isAuthenticated || authController.user == null) {
        // Show loading if still checking auth, otherwise show error
        if (authController.isLoading) {
          return const LoadingWidget();
        }
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                "You don't have permission to access this page.",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        );
      }

      final canModify = _canModifyCategories(authController.user);
      final canAdd = _canAddCategories(authController.user);

      if (categoryController.isLoading &&
          categoryController.categories.isEmpty) {
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

      // Filter categories based on search query
      final searchQuery = _searchController.text.toLowerCase().trim();
      final filteredCategories = searchQuery.isEmpty
          ? categoryController.categories
          : categoryController.categories.where((category) {
              final nameMatch = category.name.toLowerCase().contains(
                searchQuery,
              );
              final descMatch =
                  category.description != null &&
                  category.description!.toLowerCase().contains(searchQuery);
              return nameMatch || descMatch;
            }).toList();

      // Check if we're being used as a standalone route (needs Scaffold) or in IndexedStack (no Scaffold needed)
      final isStandaloneRoute = Get.currentRoute == AppRoutes.CATEGORIES;
      
      final content = RefreshIndicator(
        onRefresh: () async {
          if (authController.shop != null) {
            await categoryController.loadCategories(authController.shop!.id);
          }
        },
        child: Column(
          children: [
            // Search field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Material(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search categories...',
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
                    fillColor: Colors.transparent,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withOpacity(0.2),
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
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
            ),
            // Categories list
            Expanded(
              child: filteredCategories.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            searchQuery.isEmpty
                                ? Icons.category_outlined
                                : Icons.search_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            searchQuery.isEmpty
                                ? 'No categories yet'
                                : 'No categories found',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            searchQuery.isEmpty
                                ? 'Create your first category to organize your leads'
                                : 'Try a different search term',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey),
                          ),
                          if (searchQuery.isEmpty) ...[
                            const SizedBox(height: 24),
                            if (canAdd)
                              ElevatedButton.icon(
                                onPressed: () => _openFormDialog(),
                                icon: const Icon(Icons.add),
                                label: const Text('Create Your First Category'),
                              ),
                          ],
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredCategories.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final category = filteredCategories[index];
                        return CategoryCardWidget(
                          category: category,
                          onEdit: canModify
                              ? () => _openFormDialog(category: category)
                              : null,
                          onDelete: canModify
                              ? () => _handleDelete(category)
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      );

      // Wrap in Scaffold only if accessed as standalone route
      if (isStandaloneRoute) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          appBar: AppBar(
            title: const Text('Categories'),
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.surface,
          ),
          floatingActionButton: canAdd
              ? FloatingActionButton.extended(
                  onPressed: () => _openFormDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Category'),
                )
              : null,
          body: content,
        );
      }

      // When used in IndexedStack, wrap in Container with background (HomeView provides Scaffold)
      return Container(
        color: Theme.of(context).colorScheme.background,
        child: content,
      );
    });
  }
}

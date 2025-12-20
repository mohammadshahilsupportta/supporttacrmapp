import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../widgets/stats_card_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart' as error_widget;
import '../../../data/models/lead_model.dart';
import '../../../data/models/shop_model.dart';
import '../../../data/models/user_model.dart';
import '../../../app/routes/app_routes.dart';
import '../leads/leads_list_view.dart';
import '../categories/categories_view.dart';
import '../settings/settings_view.dart';
import '../staff/staff_list_view.dart';
import '../tasks/my_tasks_view.dart';
import '../../widgets/shop_card_widget.dart';
import '../../widgets/user_card_widget.dart';
import '../categories/widgets/category_form_dialog.dart';
import '../../controllers/category_controller.dart';
import '../../controllers/lead_controller.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;
  final NotchBottomBarController _notchController = NotchBottomBarController(
    index: 0,
  );
  Worker? _shopWorker;
  Worker? _userWorker;

  @override
  void initState() {
    super.initState();
    final authController = Get.find<AuthController>();
    final dashboardController = Get.find<DashboardController>();

    // Load stats when shop becomes available (after first frame)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadStats(authController, dashboardController);
    });

    // Use a worker to listen to shop changes and load stats when shop becomes available
    _shopWorker = ever(authController.shopRx, (ShopModel? shop) {
      if (shop != null && mounted) {
        // Small delay to ensure controller is ready
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _checkAndLoadStats(authController, dashboardController);
          }
        });
      }
    });

    // Listen to user changes and reset index if user becomes null (sign out)
    _userWorker = ever(authController.userRx, (UserModel? user) {
      if (user == null && mounted) {
        // User signed out, reset to dashboard
        setState(() {
          _currentIndex = 0;
        });
        _notchController.jumpTo(0);
      }
    });
  }

  @override
  void dispose() {
    _shopWorker?.dispose();
    _userWorker?.dispose();
    _notchController.dispose();
    super.dispose();
  }

  void _checkAndLoadStats(
    AuthController authController,
    DashboardController dashboardController,
  ) {
    if (mounted &&
        authController.shop != null &&
        dashboardController.stats == null &&
        !dashboardController.isLoading) {
      dashboardController.loadStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Controllers should already be registered via bindings
    // Use find instead of put to avoid recreating them
    final authController = Get.find<AuthController>();
    final dashboardController = Get.find<DashboardController>();

    return Scaffold(
      appBar: AppBar(title: Text(_getAppBarTitle(_currentIndex))),
      drawer: _buildDrawer(context, authController),
      body: _buildBody(_currentIndex, authController, dashboardController),
      floatingActionButton: _buildFloatingActionButton(
        _currentIndex,
        authController,
      ),
      bottomNavigationBar: Obx(() {
        // Access userRx to trigger rebuild when user changes
        authController.userRx.value; // This makes Obx reactive to user changes
        return _buildCustomBottomNavBar();
      }),
    );
  }

  bool _canViewStaff(UserModel? user) {
    if (user == null) return false;
    // Only shop owners and admins can view staff
    return user.role == UserRole.shopOwner || user.role == UserRole.admin;
  }

  bool _canViewCategories(UserModel? user) {
    if (user == null) return false;
    // Shop owners, admins, and staff can view categories
    return user.role == UserRole.shopOwner ||
        user.role == UserRole.admin ||
        user.role == UserRole.officeStaff ||
        user.role == UserRole.marketingManager ||
        user.role == UserRole.freelance;
  }

  bool _isStaffRole(UserModel? user) {
    if (user == null) return false;
    return user.role != UserRole.shopOwner && user.role != UserRole.admin;
  }

  void _correctFiltersForTab(int index, AuthController authController) {
    if (authController.shop == null) return;

    final leadController = Get.find<LeadController>();
    final isStaffRole = _isStaffRole(authController.user);

    // Determine which view is at this index
    // For staff: Dashboard(0), Leads(1), MyTasks(2), Categories(3), Settings(4)
    // For admin: Dashboard(0), Leads(1), Staff(2), Categories(3), Settings(4)

    if (isStaffRole) {
      if (index == 1) {
        // Leads screen - set createdBy to current user (only show leads they created)
        final currentFilters = leadController.filters;
        final shouldHaveCreatedBy = authController.user?.id;
        if (currentFilters == null ||
            currentFilters.createdBy != shouldHaveCreatedBy ||
            currentFilters.assignedTo != null) {
          leadController.setFilters(
            LeadFilters(
              status: currentFilters?.status,
              source: currentFilters?.source,
              categoryIds: currentFilters?.categoryIds,
              search: currentFilters?.search,
              scoreCategories: currentFilters?.scoreCategories,
              assignedTo: null, // Clear assignedTo for Leads
              createdBy: shouldHaveCreatedBy, // Set createdBy for staff
            ),
          );
          leadController.loadLeads(
            authController.shop!.id,
            reset: true,
            silent: true,
          );
        }
      } else if (index == 2) {
        // My Tasks screen - set assignedTo to current user
        if (authController.user != null) {
          final currentFilters = leadController.filters;
          final shouldHaveAssignedTo = authController.user!.id;
          if (currentFilters == null ||
              currentFilters.assignedTo != shouldHaveAssignedTo ||
              currentFilters.createdBy != null) {
            leadController.setFilters(
              LeadFilters(
                assignedTo: shouldHaveAssignedTo,
                search: currentFilters?.search,
                createdBy: null, // Clear createdBy for My Tasks
              ),
            );
            leadController.loadLeads(
              authController.shop!.id,
              reset: true,
              silent: true,
            );
          }
        }
      }
    } else {
      // Admin/Owner - Leads screen should have no filters
      if (index == 1) {
        final currentFilters = leadController.filters;
        if (currentFilters != null &&
            (currentFilters.assignedTo != null ||
                currentFilters.createdBy != null)) {
          leadController.setFilters(
            LeadFilters(
              status: currentFilters.status,
              source: currentFilters.source,
              categoryIds: currentFilters.categoryIds,
              search: currentFilters.search,
              scoreCategories: currentFilters.scoreCategories,
              assignedTo: null, // Clear assignedTo for Leads
              createdBy: null, // Clear createdBy for Leads
            ),
          );
          leadController.loadLeads(
            authController.shop!.id,
            reset: true,
            silent: true,
          );
        }
      }
    }
  }

  int _getActualIndex(
    int displayedIndex,
    bool canViewStaff,
    bool canViewCategories,
  ) {
    // Since both bottom nav and IndexedStack are built conditionally in the same way,
    // the displayed index should match the actual index directly
    return displayedIndex;
  }

  String _getAppBarTitle(int index) {
    final authController = Get.find<AuthController>();
    final canViewStaff = _canViewStaff(authController.user);
    final canViewCategories = _canViewCategories(authController.user);
    final isStaffRole =
        authController.user?.role != UserRole.shopOwner &&
        authController.user?.role != UserRole.admin;

    // Map displayed index to title based on visible tabs
    if (index == 0) return 'Dashboard';
    if (index == 1) return 'Leads';

    if (isStaffRole) {
      if (index == 2) return 'My Tasks';
      if (canViewCategories) {
        if (index == 3) return 'Categories';
        if (index == 4) return 'Settings';
      } else {
        if (index == 3) return 'Settings';
      }
    } else {
      if (canViewStaff) {
        if (index == 2) return 'Staff';
        if (canViewCategories) {
          if (index == 3) return 'Categories';
          if (index == 4) return 'Settings';
        } else {
          if (index == 3) return 'Settings';
        }
      } else {
        if (canViewCategories) {
          if (index == 2) return 'Categories';
          if (index == 3) return 'Settings';
        } else {
          if (index == 2) return 'Settings';
        }
      }
    }

    return 'Dashboard';
  }

  Widget _buildBody(
    int index,
    AuthController authController,
    DashboardController dashboardController,
  ) {
    final canViewStaff = _canViewStaff(authController.user);
    final canViewCategories = _canViewCategories(authController.user);
    final isStaffRole =
        authController.user?.role != UserRole.shopOwner &&
        authController.user?.role != UserRole.admin;
    final actualIndex = _getActualIndex(index, canViewStaff, canViewCategories);

    // Use IndexedStack to preserve state of all tabs
    // Build children in the same order as IndexedStack expects
    final children = <Widget>[
      _buildDashboardContent(authController, dashboardController),
    ];

    // For staff role, add both Leads and My Tasks
    if (isStaffRole) {
      children.add(const LeadsListView()); // All leads (read-only for staff)
      children.add(const MyTasksView()); // Only assigned leads (read-only)
    } else {
      children.add(
        const LeadsListView(),
      ); // All leads (editable for admin/owner)
    }

    if (canViewStaff) {
      children.add(const StaffListView());
    }

    if (canViewCategories) {
      children.add(const CategoriesView());
    }

    children.add(const SettingsView());

    // Ensure index is within bounds
    final safeIndex = actualIndex < children.length ? actualIndex : 0;

    return IndexedStack(index: safeIndex, children: children);
  }

  Widget _buildCustomBottomNavBar() {
    final theme = Theme.of(context);
    final authController = Get.find<AuthController>();
    // Access user reactively - Obx will rebuild when userRx changes
    final user = authController.userRx.value;
    final canViewStaff = _canViewStaff(user);
    final isStaffRole =
        user?.role != UserRole.shopOwner && user?.role != UserRole.admin;

    // Build bottom bar items conditionally
    final bottomBarItems = <BottomBarItem>[
      BottomBarItem(
        inActiveItem: Icon(
          Icons.dashboard_outlined,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        activeItem: Icon(Icons.dashboard, color: theme.colorScheme.onPrimary),
        itemLabel: 'Dashboard',
      ),
      BottomBarItem(
        inActiveItem: Icon(
          Icons.people_outline,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        activeItem: Icon(Icons.people, color: theme.colorScheme.onPrimary),
        itemLabel: 'Leads',
      ),
    ];

    // For staff role, add My Tasks tab
    if (isStaffRole) {
      bottomBarItems.add(
        BottomBarItem(
          inActiveItem: Icon(
            Icons.task_outlined,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          activeItem: Icon(Icons.task, color: theme.colorScheme.onPrimary),
          itemLabel: 'My Tasks',
        ),
      );
    }

    // Only add Staff tab if user can view staff
    if (canViewStaff) {
      bottomBarItems.add(
        BottomBarItem(
          inActiveItem: Icon(
            Icons.group_outlined,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          activeItem: Icon(Icons.group, color: theme.colorScheme.onPrimary),
          itemLabel: 'Staff',
        ),
      );
    }

    // Add Categories tab only if user can view categories
    final canViewCategories = _canViewCategories(user);
    if (canViewCategories) {
      bottomBarItems.add(
        BottomBarItem(
          inActiveItem: Icon(
            Icons.category_outlined,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          activeItem: Icon(Icons.category, color: theme.colorScheme.onPrimary),
          itemLabel: 'Categories',
        ),
      );
    }

    // Add Settings tab (always visible)
    bottomBarItems.add(
      BottomBarItem(
        inActiveItem: Icon(
          Icons.settings_outlined,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        activeItem: Icon(Icons.settings, color: theme.colorScheme.onPrimary),
        itemLabel: 'Settings',
      ),
    );

    // Ensure current index is within bounds
    final safeCurrentIndex =
        bottomBarItems.isNotEmpty && _currentIndex < bottomBarItems.length
        ? _currentIndex
        : 0;

    // Update state and controller if index is out of bounds (using post-frame to avoid setState during build)
    if (_currentIndex != safeCurrentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _currentIndex = safeCurrentIndex;
          });
          _notchController.jumpTo(safeCurrentIndex);
        }
      });
    }

    // Ensure controller index is valid before building AnimatedNotchBottomBar
    // This prevents the "Initial page index cannot be higher" error
    if (bottomBarItems.isNotEmpty &&
        _notchController.index >= bottomBarItems.length) {
      _notchController.jumpTo(0);
    }

    // Get system navigation bar height to add padding
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: 0),
        child: AnimatedNotchBottomBar(
          notchBottomBarController: _notchController,
          color: theme.colorScheme.surface,
          showLabel: true,
          notchColor: theme.colorScheme.primary,
          kIconSize: 24.0,
          kBottomRadius: 30.0,
          bottomBarItems: bottomBarItems,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            _notchController.jumpTo(index);
            // Force filter correction when switching tabs
            _correctFiltersForTab(index, authController);
          },
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton(int index, AuthController authController) {
    final canViewStaff = _canViewStaff(authController.user);
    final canViewCategories = _canViewCategories(authController.user);
    final isStaffRole =
        authController.user?.role != UserRole.shopOwner &&
        authController.user?.role != UserRole.admin;

    switch (index) {
      case 1: // Leads
        // All users (including staff) can create leads
        return FloatingActionButton.extended(
          onPressed: () {
            Get.toNamed(AppRoutes.LEAD_CREATE);
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Lead'),
        );
      case 2: // My Tasks (staff only) or Staff (admin/owner)
        if (isStaffRole) {
          // My Tasks - no FAB (read-only)
          return null;
        }
        // Staff tab for admin/owner
        if (canViewStaff) {
          return FloatingActionButton.extended(
            onPressed: () {
              Get.toNamed(AppRoutes.STAFF_CREATE);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Staff'),
          );
        } else if (canViewCategories) {
          return FloatingActionButton.extended(
            onPressed: () {
              _showCategoryFormDialog(authController);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Category'),
          );
        }
        return null;
      case 3: // Categories (if canViewCategories) or Staff (if canViewStaff and not staff role)
        if (isStaffRole) {
          // Staff role at index 3 would be Categories
          if (canViewCategories) {
            return FloatingActionButton.extended(
              onPressed: () {
                _showCategoryFormDialog(authController);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Category'),
            );
          }
        } else {
          // Admin/owner at index 3 would be Categories (if Staff is at 2)
          if (canViewCategories) {
            return FloatingActionButton.extended(
              onPressed: () {
                _showCategoryFormDialog(authController);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Category'),
            );
          }
        }
        return null;
      default:
        return null; // No FAB for Dashboard and Settings
    }
  }

  void _showCategoryFormDialog(AuthController authController) {
    final categoryController = Get.put(CategoryController());
    showDialog(
      context: context,
      builder: (context) => CategoryFormDialog(
        onCreate: (input) async {
          if (authController.shop != null) {
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
        },
        onUpdate: (input) async {
          if (authController.shop != null) {
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
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthController authController) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (authController.user != null)
                  CircleAvatar(
                    radius: 30,
                    child: Text(
                      authController.user!.name
                          .split(' ')
                          .map((n) => n.isNotEmpty ? n[0] : '')
                          .join('')
                          .toUpperCase()
                          .substring(
                            0,
                            authController.user!.name.split(' ').length > 1
                                ? 2
                                : 1,
                          ),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                const SizedBox(height: 8),
                if (authController.user != null)
                  Text(
                    authController.user!.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (authController.shop != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    authController.shop!.name,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _currentIndex = 0;
              });
              _notchController.jumpTo(0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Leads'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _currentIndex = 1;
              });
              _notchController.jumpTo(1);
            },
          ),
          if (_isStaffRole(authController.user))
            ListTile(
              leading: const Icon(Icons.task),
              title: const Text('My Tasks'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _currentIndex = 2;
                });
                _notchController.jumpTo(2);
              },
            ),
          if (_canViewStaff(authController.user))
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Staff'),
              onTap: () {
                Navigator.pop(context);
                final isStaffRole = _isStaffRole(authController.user);
                int staffIndex;
                if (isStaffRole) {
                  staffIndex = 3; // After Leads and My Tasks
                } else {
                  staffIndex = 2; // After Leads
                }
                setState(() {
                  _currentIndex = staffIndex;
                });
                _notchController.jumpTo(staffIndex);
              },
            ),
          if (_canViewCategories(authController.user))
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Categories'),
              onTap: () {
                Navigator.pop(context);
                final isStaffRole = _isStaffRole(authController.user);
                final canViewStaff = _canViewStaff(authController.user);
                int categoriesIndex;
                if (isStaffRole) {
                  categoriesIndex = 3; // After Leads and My Tasks
                } else if (canViewStaff) {
                  categoriesIndex = 3; // After Leads and Staff
                } else {
                  categoriesIndex = 2; // After Leads
                }
                setState(() {
                  _currentIndex = categoriesIndex;
                });
                _notchController.jumpTo(categoriesIndex);
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              final isStaffRole = _isStaffRole(authController.user);
              final canViewStaff = _canViewStaff(authController.user);
              final canViewCategories = _canViewCategories(authController.user);
              int settingsIndex;
              if (isStaffRole) {
                // Staff: Dashboard(0), Leads(1), MyTasks(2), Categories(3), Settings(4)
                settingsIndex = canViewCategories ? 4 : 3;
              } else if (canViewStaff && canViewCategories) {
                // Admin/Owner: Dashboard(0), Leads(1), Staff(2), Categories(3), Settings(4)
                settingsIndex = 4;
              } else if (canViewStaff || canViewCategories) {
                settingsIndex = 3;
              } else {
                settingsIndex = 2;
              }
              setState(() {
                _currentIndex = settingsIndex;
              });
              _notchController.jumpTo(settingsIndex);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Get.toNamed(AppRoutes.PROFILE);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              authController.signOut();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(
    AuthController authController,
    DashboardController dashboardController,
  ) {
    return Obx(() {
      final stats = dashboardController.stats;
      final isLoading = dashboardController.isLoading;
      final shop = authController.shop;

      // Trigger load when shop becomes available and stats are null
      if (shop != null && stats == null && !isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            dashboardController.loadStats();
          }
        });
      }

      if (authController.isLoading || (isLoading && stats == null)) {
        return const LoadingWidget();
      }

      if (authController.user == null || shop == null) {
        return error_widget.ErrorDisplayWidget(
          message: 'Not authorized to access this page.',
          onRetry: () => authController.checkAuthStatus(),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          if (authController.shop != null) {
            await dashboardController.loadStats();
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              // Text(
              //   'Dashboard',
              //   style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              //         fontWeight: FontWeight.bold,
              //       ),
              // ),
              // const SizedBox(height: 4),
              Text(
                'Welcome back, ${authController.user!.name}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Error message if any
              Obx(() {
                if (dashboardController.errorMessage.isNotEmpty) {
                  return Card(
                    color: Colors.red.shade50,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  dashboardController.errorMessage,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => dashboardController.loadStats(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

              // Quick Stats - 4 Cards
              Obx(() {
                final stats = dashboardController.stats;
                final isLoading = dashboardController.isLoading;
                final activeStaff = dashboardController.activeStaffCount;
                final user = authController.user;
                final isStaffRole =
                    user?.role != UserRole.shopOwner &&
                    user?.role != UserRole.admin;

                // Show loading state only if actively loading and no stats
                if (isLoading && stats == null) {
                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.4,
                    children: List.generate(
                      4,
                      (index) => const Card(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                // Always show stats (even if 0 or null)
                final totalLeads = stats?.total ?? 0;
                final recentCount = stats?.recentCount ?? 0;
                final conversionRate = stats != null && stats.total > 0
                    ? ((stats.byStatus[LeadStatus.converted] ?? 0) /
                          stats.total *
                          100)
                    : 0.0;

                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.4,
                  children: [
                    StatsCardWidget(
                      title: 'Total Leads',
                      value: totalLeads.toString(),
                      subtitle: isStaffRole
                          ? 'Your leads'
                          : 'All leads in your shop',
                      icon: Icons.people,
                      iconColor: Colors.blue,
                    ),
                    StatsCardWidget(
                      title: 'Conversion Rate',
                      value: '${conversionRate.toStringAsFixed(1)}%',
                      subtitle: 'Leads converted to customers',
                      icon: Icons.trending_up,
                      iconColor: Colors.green,
                    ),
                    StatsCardWidget(
                      title: 'New Leads',
                      value: recentCount.toString(),
                      subtitle: isStaffRole
                          ? 'Your leads this week'
                          : 'Leads added this week',
                      icon: Icons.person_add,
                      iconColor: Colors.orange,
                    ),
                    // Show different card for staff vs admin/owner
                    if (isStaffRole)
                      StatsCardWidget(
                        title: 'My Tasks',
                        value: (stats?.assignedCount ?? 0).toString(),
                        subtitle: 'Leads assigned to you',
                        icon: Icons.task,
                        iconColor: Colors.purple,
                      )
                    else
                      StatsCardWidget(
                        title: 'Active Staff',
                        value: activeStaff.toString(),
                        subtitle: 'Team members',
                        icon: Icons.verified_user,
                        iconColor: Colors.purple,
                      ),
                  ],
                );
              }),
              const SizedBox(height: 24),

              // Lead Status Overview
              Obx(() {
                final stats = dashboardController.stats;
                final isLoading = dashboardController.isLoading;

                if (isLoading && stats == null) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                // Always show the card, even if stats are null or empty
                final byStatus = stats?.byStatus ?? <LeadStatus, int>{};

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lead Status Overview',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Breakdown of leads by their current status',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatusItem(
                              context,
                              'New',
                              (byStatus[LeadStatus.newLead] ?? 0).toString(),
                              Colors.blue,
                            ),
                            _buildStatusItem(
                              context,
                              'Contacted',
                              (byStatus[LeadStatus.contacted] ?? 0).toString(),
                              Colors.orange,
                            ),
                            _buildStatusItem(
                              context,
                              'Qualified',
                              (byStatus[LeadStatus.qualified] ?? 0).toString(),
                              Colors.purple,
                            ),
                            _buildStatusItem(
                              context,
                              'Converted',
                              (byStatus[LeadStatus.converted] ?? 0).toString(),
                              Colors.green,
                            ),
                            _buildStatusItem(
                              context,
                              'Lost',
                              (byStatus[LeadStatus.lost] ?? 0).toString(),
                              Colors.red,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),

              // Shop and User Information
              Obx(() {
                final user = authController.user;
                final shop = authController.shop;

                if (user == null || shop == null) {
                  return const SizedBox.shrink();
                }

                return Column(
                  children: [
                    ShopCardWidget(shop: shop),
                    const SizedBox(height: 16),
                    UserCardWidget(user: user),
                  ],
                );
              }),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStatusItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }
}

import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../widgets/stats_card_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart' as error_widget;
import '../../../data/models/lead_model.dart';
import '../../../app/routes/app_routes.dart';
import '../leads/leads_list_view.dart';
import '../categories/categories_view.dart';
import '../settings/settings_view.dart';
import '../staff/staff_list_view.dart';
import '../../widgets/shop_card_widget.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;
  bool _hasInitialized = false;
  final NotchBottomBarController _notchController = NotchBottomBarController(
    index: 0,
  );

  @override
  void initState() {
    super.initState();
    final authController = Get.find<AuthController>();
    final dashboardController = Get.find<DashboardController>();

    // Load stats when shop becomes available (after first frame)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadStats(authController, dashboardController);
    });

    // Use a worker to listen to shop changes
    // We'll check periodically or on user interaction
  }

  @override
  void dispose() {
    _notchController.dispose();
    super.dispose();
  }

  void _checkAndLoadStats(
    AuthController authController,
    DashboardController dashboardController,
  ) {
    if (mounted &&
        !_hasInitialized &&
        authController.shop != null &&
        dashboardController.stats == null &&
        !dashboardController.isLoading) {
      _hasInitialized = true;
      dashboardController.loadStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.put(AuthController());
    final dashboardController = Get.put(DashboardController());

    return Scaffold(
      appBar: AppBar(title: Text(_getAppBarTitle(_currentIndex))),
      drawer: _buildDrawer(context, authController),
      body: _buildBody(_currentIndex, authController, dashboardController),
      floatingActionButton: _buildFloatingActionButton(
        _currentIndex,
        authController,
      ),
      bottomNavigationBar: _buildCustomBottomNavBar(),
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Leads';
      case 2:
        return 'Staff';
      case 3:
        return 'Categories';
      case 4:
        return 'Settings';
      default:
        return 'Dashboard';
    }
  }

  Widget _buildBody(
    int index,
    AuthController authController,
    DashboardController dashboardController,
  ) {
    switch (index) {
      case 0:
        return _buildDashboardContent(authController, dashboardController);
      case 1:
        return const LeadsListView();
      case 2:
        return const StaffListView();
      case 3:
        return const CategoriesView();
      case 4:
        return const SettingsView();
      default:
        return _buildDashboardContent(authController, dashboardController);
    }
  }

  Widget _buildCustomBottomNavBar() {
    return AnimatedNotchBottomBar(
      notchBottomBarController: _notchController,
      color: Colors.white,
      showLabel: true,
      notchColor: Theme.of(context).primaryColor,
      kIconSize: 24.0,
      kBottomRadius: 30.0,
      bottomBarItems: [
        const BottomBarItem(
          inActiveItem: Icon(Icons.dashboard_outlined, color: Colors.grey),
          activeItem: Icon(Icons.dashboard, color: Colors.white),
          itemLabel: 'Dashboard',
        ),
        const BottomBarItem(
          inActiveItem: Icon(Icons.people_outline, color: Colors.grey),
          activeItem: Icon(Icons.people, color: Colors.white),
          itemLabel: 'Leads',
        ),
        const BottomBarItem(
          inActiveItem: Icon(Icons.group_outlined, color: Colors.grey),
          activeItem: Icon(Icons.group, color: Colors.white),
          itemLabel: 'Staff',
        ),
        const BottomBarItem(
          inActiveItem: Icon(Icons.category_outlined, color: Colors.grey),
          activeItem: Icon(Icons.category, color: Colors.white),
          itemLabel: 'Categories',
        ),
        const BottomBarItem(
          inActiveItem: Icon(Icons.settings_outlined, color: Colors.grey),
          activeItem: Icon(Icons.settings, color: Colors.white),
          itemLabel: 'Settings',
        ),
      ],
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
        _notchController.jumpTo(index);
      },
    );
  }

  Widget? _buildFloatingActionButton(int index, AuthController authController) {
    switch (index) {
      case 1: // Leads
        return FloatingActionButton.extended(
          onPressed: () {
            Get.toNamed(AppRoutes.LEAD_CREATE);
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Lead'),
        );
      case 2: // Staff
        return FloatingActionButton.extended(
          onPressed: () {
            Get.snackbar('Add Staff', 'Add staff functionality coming soon!');
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Staff'),
        );
      case 3: // Categories
        return FloatingActionButton.extended(
          onPressed: () {
            Get.snackbar(
              'Add Category',
              'Add category functionality coming soon!',
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Category'),
        );
      default:
        return null; // No FAB for Dashboard and Settings
    }
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
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('Staff'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _currentIndex = 2;
              });
              _notchController.jumpTo(2);
            },
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Categories'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _currentIndex = 3;
              });
              _notchController.jumpTo(3);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _currentIndex = 4;
              });
              _notchController.jumpTo(4);
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

      if (authController.isLoading || (isLoading && stats == null)) {
        return const LoadingWidget();
      }

      if (authController.user == null || authController.shop == null) {
        return error_widget.ErrorDisplayWidget(
          message: 'Not authorized to access this page.',
          onRetry: () => authController.checkAuthStatus(),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          if (authController.shop != null) {
            _hasInitialized = false; // Reset flag to allow reload
            await dashboardController.loadStats();
            _hasInitialized = true;
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
                      subtitle: 'All leads in your shop',
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
                      subtitle: 'Leads added this week',
                      icon: Icons.person_add,
                      iconColor: Colors.orange,
                    ),
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

              // Shop Information
              ShopCardWidget(shop: authController.shop!),
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

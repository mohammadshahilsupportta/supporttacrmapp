import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/lead_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/category_controller.dart';
import '../../controllers/staff_controller.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart' as error_widget;
import '../../widgets/lead_card_widget.dart';
import '../../../data/models/lead_model.dart';
import '../../../app/routes/app_routes.dart';

class MyTasksView extends StatefulWidget {
  const MyTasksView({super.key});

  @override
  State<MyTasksView> createState() => _MyTasksViewState();
}

class _MyTasksViewState extends State<MyTasksView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounceTimer;
  bool _initialLoadAttempted = false;

  @override
  void initState() {
    super.initState();
    final authController = Get.find<AuthController>();
    
    // Initialize controllers
    if (!Get.isRegistered<LeadController>()) {
      Get.put(LeadController());
    }
    if (!Get.isRegistered<CategoryController>()) {
      Get.put(CategoryController());
    }
    if (!Get.isRegistered<StaffController>()) {
      Get.put(StaffController());
    }

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptInitialLoad(authController);
    });
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _attemptInitialLoad(AuthController authController) {
    if (authController.shop != null && 
        authController.user != null && 
        !_initialLoadAttempted) {
      _loadMyTasks(authController);
      _initialLoadAttempted = true;
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      final authController = Get.find<AuthController>();
      final leadController = Get.find<LeadController>();
      if (authController.shop != null && 
          leadController.hasMore && 
          !leadController.isLoadingMore) {
        leadController.loadMoreLeads(authController.shop!.id);
      }
    }
  }

  void _loadMyTasks(AuthController authController, {bool silent = false}) {
    if (authController.shop == null || authController.user == null) return;

    final leadController = Get.find<LeadController>();
    
    // Filter leads assigned to current staff user
    leadController.setFilters(
      LeadFilters(
        assignedTo: authController.user!.id, // Only leads assigned to this staff
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      ),
    );
    
    leadController.loadLeads(authController.shop!.id, reset: true, silent: silent);
  }

  void _onSearchChanged(String value) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _loadMyTasks(Get.find<AuthController>(), silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    
    // Always ensure filters are correct for My Tasks screen (assignedTo = current user)
    if (authController.shop != null && authController.user != null) {
      final leadController = Get.find<LeadController>();
      final currentFilters = leadController.filters;
      final shouldHaveAssignedTo = authController.user!.id;
      
      if (currentFilters == null || 
          currentFilters.assignedTo != shouldHaveAssignedTo) {
        // Filters are incorrect, fix immediately
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _loadMyTasks(authController, silent: true);
          }
        });
      }
    }
    
    return Obx(() {
      if (!authController.isAuthenticated || authController.user == null) {
        return const Center(child: Text('Not authenticated'));
      }

      final leadController = Get.find<LeadController>();
      
      if (leadController.isLoading && leadController.leads.isEmpty) {
        return const LoadingWidget();
      }

      if (leadController.errorMessage.isNotEmpty) {
        return error_widget.ErrorDisplayWidget(
          message: leadController.errorMessage,
          onRetry: () => _loadMyTasks(authController),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          _loadMyTasks(authController);
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search my tasks...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _loadMyTasks(Get.find<AuthController>(), silent: true);
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
            ),
            
            // Leads list
            if (leadController.leads.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.task_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No tasks assigned',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You don\'t have any leads assigned to you yet',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final lead = leadController.leads[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: LeadCardWidget(
                        lead: lead,
                        onTap: () {
                          Get.toNamed('${AppRoutes.LEAD_DETAIL.replaceAll(':id', lead.id)}');
                        },
                        isReadOnly: false, // Allow editing
                        canEditStatus: true, // Can edit status in My Tasks
                        canEditAssignedTo: false, // Cannot edit assigned to (read-only)
                      ),
                    );
                  },
                  childCount: leadController.leads.length,
                ),
              ),
            
            // Loading more indicator
            if (leadController.isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      );
    });
  }
}


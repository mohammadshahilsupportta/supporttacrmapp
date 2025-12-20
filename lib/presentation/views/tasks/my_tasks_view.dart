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
  LeadSource? _selectedSource;
  String? _selectedCategoryId;
  final Set<LeadStatus> _selectedStatuses = <LeadStatus>{};
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
      
      // Load categories for filter dropdown
      final categoryController = Get.find<CategoryController>();
      if (categoryController.categories.isEmpty) {
        categoryController.loadCategories(authController.shop!.id);
      }
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
    
    // Filter leads assigned to current staff user with all filters
    leadController.setFilters(
      LeadFilters(
        assignedTo: authController.user!.id, // Only leads assigned to this staff
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        status: _selectedStatuses.isEmpty ? null : _selectedStatuses.toList(),
        source: _selectedSource,
        categoryIds: _selectedCategoryId != null ? <String>[_selectedCategoryId!] : null,
      ),
    );
    
    leadController.loadLeads(authController.shop!.id, reset: true, silent: silent);
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _loadMyTasks(Get.find<AuthController>(), silent: true);
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedSource = null;
      _selectedCategoryId = null;
      _selectedStatuses.clear();
    });
    _loadMyTasks(Get.find<AuthController>(), silent: true);
  }

  String _sourceLabel(LeadSource source) {
    switch (source) {
      case LeadSource.website:
        return 'Website';
      case LeadSource.phone:
        return 'Phone';
      case LeadSource.walkIn:
        return 'Walk-in';
      case LeadSource.referral:
        return 'Referral';
      case LeadSource.socialMedia:
        return 'Social Media';
      case LeadSource.email:
        return 'Email';
      case LeadSource.other:
        return 'Other';
    }
  }

  String _statusLabel(LeadStatus status) {
    switch (status) {
      case LeadStatus.newLead:
        return 'New';
      case LeadStatus.contacted:
        return 'Contacted';
      case LeadStatus.qualified:
        return 'Qualified';
      case LeadStatus.converted:
        return 'Converted';
      case LeadStatus.lost:
        return 'Lost';
    }
  }

  Color _statusColor(LeadStatus status) {
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

  Widget _buildFilters(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final categoryController = Get.find<CategoryController>();
    final categories = categoryController.categories;
    
    // Calculate active filters count
    final activeFiltersCount = _selectedStatuses.length +
        (_selectedCategoryId != null ? 1 : 0) +
        (_selectedSource != null ? 1 : 0) +
        (_searchController.text.isNotEmpty ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search field with clear button
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search my tasks...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() => _searchController.clear());
                            _loadMyTasks(Get.find<AuthController>(), silent: true);
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
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
                onChanged: _onSearchChanged,
              ),
            ),
            if (activeFiltersCount > 0) ...[
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Clear'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(0, 36),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        
        // Status Filter - Compact horizontal scroll
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  'Status:',
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              ...LeadStatus.values.map((status) {
                final isSelected = _selectedStatuses.contains(status);
                final color = _statusColor(status);
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    selected: isSelected,
                    label: Text(
                      _statusLabel(status),
                      style: const TextStyle(fontSize: 12),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedStatuses.add(status);
                        } else {
                          _selectedStatuses.remove(status);
                        }
                      });
                      Future.microtask(() => _loadMyTasks(Get.find<AuthController>(), silent: true));
                    },
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    selectedColor: color.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? color : Theme.of(context).colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: isSelected 
                          ? color 
                          : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Category and Source in single row
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: const Icon(Icons.category_outlined),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
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
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Categories'),
                  ),
                  ...categories.map(
                    (cat) => DropdownMenuItem<String>(
                      value: cat.id,
                      child: Text(cat.name),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedCategoryId = value);
                  Future.microtask(() => _loadMyTasks(Get.find<AuthController>(), silent: true));
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<LeadSource>(
                value: _selectedSource,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Source',
                  prefixIcon: const Icon(Icons.filter_alt_outlined),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
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
                items: [
                  const DropdownMenuItem<LeadSource>(
                    value: null,
                    child: Text('All Sources'),
                  ),
                  ...LeadSource.values.map(
                    (source) => DropdownMenuItem<LeadSource>(
                      value: source,
                      child: Text(_sourceLabel(source)),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedSource = value);
                  Future.microtask(() => _loadMyTasks(Get.find<AuthController>(), silent: true));
                },
              ),
            ),
          ],
        ),
      ],
    );
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
            // Filters section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: _buildFilters(context),
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


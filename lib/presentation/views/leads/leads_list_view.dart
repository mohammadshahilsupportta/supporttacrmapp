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
import '../../widgets/lead_table_widget.dart';
import '../../../app/routes/app_routes.dart';
import '../../../data/models/lead_model.dart';
import '../../../data/models/user_model.dart';

class LeadsListView extends StatefulWidget {
  const LeadsListView({super.key});

  @override
  State<LeadsListView> createState() => _LeadsListViewState();
}

class _LeadsListViewState extends State<LeadsListView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  LeadSource? _selectedSource;
  String? _selectedCategoryId;
  final Set<LeadStatus> _selectedStatuses = <LeadStatus>{};
  final Set<String> _selectedScoreCategories = <String>{};
  String? _selectedCountry;
  String? _selectedState;
  String? _selectedCity;
  String? _selectedDistrict;
  Timer? _searchDebounceTimer;
  bool _initialLoadAttempted = false;

  bool _isStaffRole(AuthController authController) {
    final user = authController.user;
    if (user == null) return false;
    return user.role != UserRole.shopOwner && user.role != UserRole.admin;
  }

  @override
  void initState() {
    super.initState();
    final authController = Get.find<AuthController>();
    // Initialize controllers only if they don't exist
    if (!Get.isRegistered<LeadController>()) {
      Get.put(LeadController());
    }
    if (!Get.isRegistered<CategoryController>()) {
      Get.put(CategoryController());
    }
    if (!Get.isRegistered<StaffController>()) {
      Get.put(StaffController());
    }

    // Setup scroll listener for pagination
    _scrollController.addListener(_onScroll);

    // Load data on first frame - always attempt load on first mount
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
    if (authController.shop != null && !_initialLoadAttempted) {
      // Always load on first mount, regardless of current state
      _applyFiltersAndLoad(silent: false); // Use non-silent for initial load to show loading
      _initialLoadAttempted = true;
      
      final categoryController = Get.find<CategoryController>();
      if (categoryController.categories.isEmpty) {
        categoryController.loadCategories(authController.shop!.id);
      }
      // Load staff for assignment dropdown
      final staffController = Get.find<StaffController>();
      if (staffController.staffList.isEmpty) {
        staffController.loadStaff(authController.shop!.id);
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      // Load more when 80% scrolled
      final authController = Get.find<AuthController>();
      final leadController = Get.find<LeadController>();
      if (authController.shop != null && leadController.hasMore && !leadController.isLoadingMore) {
        leadController.loadMoreLeads(authController.shop!.id);
      }
    }
  }

  void _applyFiltersAndLoad({bool debounce = false, bool silent = false}) {
    if (debounce) {
      // Cancel previous timer
      _searchDebounceTimer?.cancel();
      
      // Create new timer with 500ms delay
      _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        _executeFiltersAndLoad(silent: true); // Silent mode for search
      });
    } else {
      _executeFiltersAndLoad(silent: silent);
    }
  }

  void _executeFiltersAndLoad({bool silent = false}) {
    final authController = Get.find<AuthController>();
    final leadController = Get.find<LeadController>();
    if (authController.shop == null) return;

    // For staff role, filter by createdBy (only show leads they created)
    final isStaffRole = _isStaffRole(authController);
    final createdBy = isStaffRole && authController.user != null 
        ? authController.user!.id 
        : null;

    leadController.setFilters(
      LeadFilters(
        status: _selectedStatuses.isEmpty ? null : _selectedStatuses.toList(),
        source: _selectedSource,
        categoryIds:
            _selectedCategoryId != null ? <String>[_selectedCategoryId!] : null,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        scoreCategories: _selectedScoreCategories.isEmpty
            ? null
            : _selectedScoreCategories.toList(),
        country: _selectedCountry,
        state: _selectedState,
        city: _selectedCity,
        district: _selectedDistrict,
        assignedTo: null, // Always clear assignedTo filter in Leads screen
        createdBy: createdBy, // Filter by createdBy for staff role
      ),
    );
    leadController.loadLeads(authController.shop!.id, reset: true, silent: silent);
    // Only load stats if not silent (search doesn't need stats refresh)
    if (!silent) {
      leadController.loadStats(authController.shop!.id);
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedSource = null;
      _selectedCategoryId = null;
      _selectedStatuses.clear();
      _selectedScoreCategories.clear();
      _selectedCountry = null;
      _selectedState = null;
      _selectedCity = null;
      _selectedDistrict = null;
    });
    // Use silent loading for filter clearing
    _applyFiltersAndLoad(silent: true);
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

  /// Get unique location values from current leads
  List<String> _getUniqueLocationValues(
    String type, {
    String? country,
    String? state,
    String? city,
  }) {
    final leadController = Get.find<LeadController>();
    final leads = leadController.leads;

    final values = <String>{};
    for (final lead in leads) {
      String? value;
      switch (type) {
        case 'country':
          value = lead.country;
          break;
        case 'state':
          value = lead.state;
          if (country != null && lead.country != country) continue;
          break;
        case 'city':
          value = lead.city;
          if (country != null && lead.country != country) continue;
          if (state != null && lead.state != state) continue;
          break;
        case 'district':
          value = lead.district;
          if (country != null && lead.country != country) continue;
          if (state != null && lead.state != state) continue;
          if (city != null && lead.city != city) continue;
          break;
      }
      if (value != null && value.trim().isNotEmpty) {
        values.add(value);
      }
    }
    final sorted = values.toList()..sort();
    return sorted;
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

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final categoryController = Get.find<CategoryController>();
    
    // Ensure data loads when widget becomes visible (for IndexedStack)
    // This handles the case where widget is created before shop is available
    if (authController.shop != null && !_initialLoadAttempted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _attemptInitialLoad(authController);
        }
      });
    }
    
    // Always ensure filters are correct for Leads screen
    final leadController = Get.find<LeadController>();
    final currentFilters = leadController.filters;
    final isStaffRole = _isStaffRole(authController);
    final shouldHaveCreatedBy = isStaffRole && authController.user != null 
        ? authController.user!.id 
        : null;
    
    if (currentFilters != null && 
        (currentFilters.assignedTo != null || 
         currentFilters.createdBy != shouldHaveCreatedBy)) {
      // Filters are incorrect, fix immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _executeFiltersAndLoad(silent: true);
        }
      });
    }

    return Obx(() {
      final leadController = Get.find<LeadController>();
      
      // Ensure data loads if shop is available and leads are empty
      if (authController.shop != null && 
          leadController.leads.isEmpty && 
          !leadController.isLoading && 
          !_initialLoadAttempted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _attemptInitialLoad(authController);
          }
        });
      }
      
      // Only show loading widget on initial load, not during search
      final isSearching = _searchController.text.trim().isNotEmpty;
      if (leadController.isLoading && leadController.leads.isEmpty && !isSearching) {
        return const LoadingWidget();
      }

      if (leadController.errorMessage.isNotEmpty) {
        return error_widget.ErrorDisplayWidget(
          message: leadController.errorMessage,
          onRetry: () {
            if (authController.shop != null) {
              leadController.loadLeads(authController.shop!.id, reset: true);
            }
          },
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          if (authController.shop != null) {
            await leadController.loadLeads(authController.shop!.id, reset: true);
          }
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: _buildFilters(context, categoryController),
              ),
            ),
            // Content - Table for desktop, Cards for mobile
            if (leadController.leads.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No leads found',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text('Try adjusting your filters'),
                    ],
                  ),
                ),
              )
            else
              // Content: Table for desktop, Cards for mobile
              SliverLayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.crossAxisExtent >= 768) {
                    // Desktop - Table View as Sliver
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withOpacity(0.2),
                            ),
                          ),
                          child: LeadTableWidget(
                            leads: leadController.leads,
                            isLoading: leadController.isLoading,
                          ),
                        ),
                      ),
                    );
                  } else {
                    // Mobile - Card View with pagination as SliverList
                    return SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index >= leadController.leads.length) {
                              // Loading more indicator
                              if (leadController.isLoadingMore) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            }
                            final lead = leadController.leads[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: LeadCardWidget(
                                lead: lead,
                                onTap: () {
                                  Get.toNamed(
                                    AppRoutes.LEAD_DETAIL.replaceAll(':id', lead.id),
                                  );
                                },
                                isReadOnly: _isStaffRole(authController),
                                canEditStatus: !_isStaffRole(authController), // Staff cannot edit status in Leads
                                canEditAssignedTo: !_isStaffRole(authController), // Staff cannot edit assigned to in Leads
                              ),
                            );
                          },
                          childCount: leadController.leads.length + (leadController.isLoadingMore ? 1 : 0),
                        ),
                      ),
                    );
                  }
                },
              ),
          ],
        ),
      );
    });
  }

  Widget _buildFilters(
    BuildContext context,
    CategoryController categoryController,
  ) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final categories = categoryController.categories;
    
    // Calculate active filters count
    final activeFiltersCount = _selectedStatuses.length +
        (_selectedCategoryId != null ? 1 : 0) +
        (_selectedSource != null ? 1 : 0) +
        (_searchController.text.isNotEmpty ? 1 : 0) +
        _selectedScoreCategories.length +
        (_selectedCountry != null ? 1 : 0) +
        (_selectedState != null ? 1 : 0) +
        (_selectedCity != null ? 1 : 0) +
        (_selectedDistrict != null ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search field with clear button - Compact
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name, email, phone, or company',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() => _searchController.clear());
                            _applyFiltersAndLoad();
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
                onChanged: (_) {
                  setState(() {});
                  _applyFiltersAndLoad(debounce: true);
                },
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
                      // Use Future.microtask to ensure setState completes first, use silent loading
                      Future.microtask(() => _applyFiltersAndLoad(silent: true));
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
                  // Use Future.microtask to ensure setState completes first, use silent loading
                  Future.microtask(() => _applyFiltersAndLoad(silent: true));
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
                  // Use Future.microtask to ensure setState completes first, use silent loading
                  Future.microtask(() => _applyFiltersAndLoad(silent: true));
                },
              ),
            ),
          ],
        ),

        // Location Filters
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Country Filter
            SizedBox(
              width: 120,
              child: DropdownButtonFormField<String>(
                value: _selectedCountry,
                decoration: InputDecoration(
                  labelText: 'Country',
                  prefixIcon: const Icon(Icons.public_outlined, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Countries', style: TextStyle(fontSize: 12)),
                  ),
                  ..._getUniqueLocationValues('country').map(
                    (country) => DropdownMenuItem<String>(
                      value: country,
                      child: Text(country, style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCountry = value;
                    // Clear dependent filters when country changes
                    if (value == null) {
                      _selectedState = null;
                      _selectedCity = null;
                      _selectedDistrict = null;
                    } else {
                      _selectedState = null;
                      _selectedCity = null;
                      _selectedDistrict = null;
                    }
                  });
                  Future.microtask(() => _applyFiltersAndLoad(silent: true));
                },
              ),
            ),
            // State Filter
            SizedBox(
              width: 120,
              child: DropdownButtonFormField<String>(
                value: _selectedState,
                decoration: InputDecoration(
                  labelText: 'State',
                  prefixIcon: const Icon(Icons.map_outlined, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All States', style: TextStyle(fontSize: 12)),
                  ),
                  ..._getUniqueLocationValues('state', country: _selectedCountry).map(
                    (state) => DropdownMenuItem<String>(
                      value: state,
                      child: Text(state, style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedState = value;
                    // Clear dependent filters when state changes
                    if (value == null) {
                      _selectedCity = null;
                      _selectedDistrict = null;
                    } else {
                      _selectedCity = null;
                      _selectedDistrict = null;
                    }
                  });
                  Future.microtask(() => _applyFiltersAndLoad(silent: true));
                },
              ),
            ),
            // City Filter
            SizedBox(
              width: 120,
              child: DropdownButtonFormField<String>(
                value: _selectedCity,
                decoration: InputDecoration(
                  labelText: 'City',
                  prefixIcon: const Icon(Icons.location_city_outlined, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Cities', style: TextStyle(fontSize: 12)),
                  ),
                  ..._getUniqueLocationValues('city', country: _selectedCountry, state: _selectedState).map(
                    (city) => DropdownMenuItem<String>(
                      value: city,
                      child: Text(city, style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCity = value;
                    // Clear dependent filters when city changes
                    if (value == null) {
                      _selectedDistrict = null;
                    } else {
                      _selectedDistrict = null;
                    }
                  });
                  Future.microtask(() => _applyFiltersAndLoad(silent: true));
                },
              ),
            ),
            // District Filter
            SizedBox(
              width: 120,
              child: DropdownButtonFormField<String>(
                value: _selectedDistrict,
                decoration: InputDecoration(
                  labelText: 'District',
                  prefixIcon: const Icon(Icons.place_outlined, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Districts', style: TextStyle(fontSize: 12)),
                  ),
                  ..._getUniqueLocationValues('district', country: _selectedCountry, state: _selectedState, city: _selectedCity).map(
                    (district) => DropdownMenuItem<String>(
                      value: district,
                      child: Text(district, style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedDistrict = value);
                  Future.microtask(() => _applyFiltersAndLoad(silent: true));
                },
              ),
            ),
          ],
        ),

        // Active Filters Display - Compact
        if (activeFiltersCount > 0) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ..._selectedStatuses.map((status) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Chip(
                      label: Text(
                        'Status: ${_statusLabel(status)}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      onDeleted: () {
                        setState(() {
                          _selectedStatuses.remove(status);
                        });
                        // Use Future.microtask to ensure setState completes first, use silent loading
                        Future.microtask(() => _applyFiltersAndLoad(silent: true));
                      },
                      deleteIcon: const Icon(Icons.close, size: 14),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  );
                }),
                if (_selectedCategoryId != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Chip(
                      label: Text(
                        'Category: ${categories.firstWhere((c) => c.id == _selectedCategoryId).name}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      onDeleted: () {
                        setState(() => _selectedCategoryId = null);
                        // Use Future.microtask to ensure setState completes first, use silent loading
                        Future.microtask(() => _applyFiltersAndLoad(silent: true));
                      },
                      deleteIcon: const Icon(Icons.close, size: 14),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                if (_selectedSource != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Chip(
                      label: Text(
                        'Source: ${_sourceLabel(_selectedSource!)}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      onDeleted: () {
                        setState(() => _selectedSource = null);
                        // Use Future.microtask to ensure setState completes first, use silent loading
                        Future.microtask(() => _applyFiltersAndLoad(silent: true));
                      },
                      deleteIcon: const Icon(Icons.close, size: 14),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ..._selectedScoreCategories.map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Chip(
                      label: Text(
                        'Score: ${category.toUpperCase()}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      onDeleted: () {
                        setState(() {
                          _selectedScoreCategories.remove(category);
                        });
                        Future.microtask(() => _applyFiltersAndLoad(silent: true));
                      },
                      deleteIcon: const Icon(Icons.close, size: 14),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  );
                }),
                if (_selectedCountry != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Chip(
                      label: Text(
                        'Country: $_selectedCountry',
                        style: const TextStyle(fontSize: 11),
                      ),
                      onDeleted: () {
                        setState(() {
                          _selectedCountry = null;
                          _selectedState = null;
                          _selectedCity = null;
                          _selectedDistrict = null;
                        });
                        Future.microtask(() => _applyFiltersAndLoad(silent: true));
                      },
                      deleteIcon: const Icon(Icons.close, size: 14),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                if (_selectedState != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Chip(
                      label: Text(
                        'State: $_selectedState',
                        style: const TextStyle(fontSize: 11),
                      ),
                      onDeleted: () {
                        setState(() {
                          _selectedState = null;
                          _selectedCity = null;
                          _selectedDistrict = null;
                        });
                        Future.microtask(() => _applyFiltersAndLoad(silent: true));
                      },
                      deleteIcon: const Icon(Icons.close, size: 14),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                if (_selectedCity != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Chip(
                      label: Text(
                        'City: $_selectedCity',
                        style: const TextStyle(fontSize: 11),
                      ),
                      onDeleted: () {
                        setState(() {
                          _selectedCity = null;
                          _selectedDistrict = null;
                        });
                        Future.microtask(() => _applyFiltersAndLoad(silent: true));
                      },
                      deleteIcon: const Icon(Icons.close, size: 14),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                if (_selectedDistrict != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Chip(
                      label: Text(
                        'District: $_selectedDistrict',
                        style: const TextStyle(fontSize: 11),
                      ),
                      onDeleted: () {
                        setState(() => _selectedDistrict = null);
                        Future.microtask(() => _applyFiltersAndLoad(silent: true));
                      },
                      deleteIcon: const Icon(Icons.close, size: 14),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
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
}



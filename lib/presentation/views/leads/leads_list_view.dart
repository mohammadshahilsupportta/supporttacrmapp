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

class LeadsListView extends StatefulWidget {
  const LeadsListView({super.key});

  @override
  State<LeadsListView> createState() => _LeadsListViewState();
}

class _LeadsListViewState extends State<LeadsListView> {
  final TextEditingController _searchController = TextEditingController();
  LeadSource? _selectedSource;
  String? _selectedCategoryId;
  final Set<LeadStatus> _selectedStatuses = {LeadStatus.newLead};
  final Set<String> _selectedScoreCategories = <String>{};

  @override
  void initState() {
    super.initState();
    final authController = Get.find<AuthController>();
    Get.put(LeadController());
    final categoryController = Get.put(CategoryController());
    final staffController = Get.put(StaffController());

    // Load data on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authController.shop != null) {
        _applyFiltersAndLoad();
        if (categoryController.categories.isEmpty) {
          categoryController.loadCategories(authController.shop!.id);
        }
        // Load staff for assignment dropdown
        if (staffController.staffList.isEmpty) {
          staffController.loadStaff(authController.shop!.id);
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFiltersAndLoad() {
    final authController = Get.find<AuthController>();
    final leadController = Get.find<LeadController>();
    if (authController.shop == null) return;

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
      ),
    );
    leadController.loadLeads(authController.shop!.id);
    leadController.loadStats(authController.shop!.id);
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedSource = null;
      _selectedCategoryId = null;
      _selectedStatuses
        ..clear()
        ..add(LeadStatus.newLead);
      _selectedScoreCategories.clear();
    });
    _applyFiltersAndLoad();
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

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final leadController = Get.put(LeadController());
    final categoryController = Get.put(CategoryController());

    return Obx(() {
      if (leadController.isLoading && leadController.leads.isEmpty) {
        return const LoadingWidget();
      }

      if (leadController.errorMessage.isNotEmpty) {
        return error_widget.ErrorDisplayWidget(
          message: leadController.errorMessage,
          onRetry: () {
            if (authController.shop != null) {
              leadController.loadLeads(authController.shop!.id);
            }
          },
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          if (authController.shop != null) {
            await leadController.loadLeads(authController.shop!.id);
          }
        },
        child: CustomScrollView(
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
              // Desktop: Table View
              SliverToBoxAdapter(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 768) {
                      // Desktop - Table View
                      return Padding(
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
                      );
                    } else {
                      // Mobile - Card View
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: leadController.leads.map(
                            (lead) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: LeadCardWidget(
                                lead: lead,
                                onTap: () {
                                  Get.toNamed(
                                    AppRoutes.LEAD_DETAIL.replaceAll(':id', lead.id),
                                  );
                                },
                              ),
                            ),
                          ).toList(),
                        ),
                      );
                    }
                  },
                ),
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
        _selectedScoreCategories.length;

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
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            setState(() => _searchController.clear());
                            _applyFiltersAndLoad();
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: (_) {
                  setState(() {});
                  _applyFiltersAndLoad();
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
                      _applyFiltersAndLoad();
                    },
                    selectedColor: color.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? color : null,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: isSelected ? color : Colors.grey.shade300,
                      width: 1,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined, size: 20),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                  _applyFiltersAndLoad();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<LeadSource>(
                value: _selectedSource,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Source',
                  prefixIcon: Icon(Icons.filter_alt_outlined, size: 20),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                  _applyFiltersAndLoad();
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
                        _applyFiltersAndLoad();
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
                        _applyFiltersAndLoad();
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
                        _applyFiltersAndLoad();
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
                        _applyFiltersAndLoad();
                      },
                      deleteIcon: const Icon(Icons.close, size: 14),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  );
                }),
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



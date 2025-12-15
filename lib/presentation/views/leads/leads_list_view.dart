import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/lead_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/category_controller.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart' as error_widget;
import '../../widgets/lead_card_widget.dart';
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

  @override
  void initState() {
    super.initState();
    final authController = Get.find<AuthController>();
    Get.put(LeadController());
    final categoryController = Get.put(CategoryController());

    // Load data on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authController.shop != null) {
        _applyFiltersAndLoad();
        if (categoryController.categories.isEmpty) {
          categoryController.loadCategories(authController.shop!.id);
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildFilters(context, categoryController),
            const SizedBox(height: 12),
            if (leadController.leads.isEmpty)
              Center(
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
                    const Text('Start by adding your first lead'),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Get.toNamed(AppRoutes.LEAD_CREATE);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Lead'),
                    ),
                  ],
                ),
              )
            else
              ...leadController.leads.map(
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search field
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search by name, email, phone, company',
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
          ),
          onChanged: (_) => _applyFiltersAndLoad(),
        ),
        const SizedBox(height: 12),

        // Filter chips for status
        Text(
          'Status',
          style: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: LeadStatus.values.map((status) {
              final isSelected = _selectedStatuses.contains(status);
              final color = _statusColor(status);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: isSelected,
                  label: Text(_statusLabel(status)),
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
                  backgroundColor: theme.colorScheme.surfaceVariant,
                  selectedColor: color.withOpacity(0.15),
                  checkmarkColor: color,
                  labelStyle: textTheme.bodyMedium?.copyWith(
                    color: isSelected ? color : theme.colorScheme.onSurface,
                  ),
                  side: BorderSide(
                    color: isSelected ? color.withOpacity(0.4) : theme.dividerColor,
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // Dropdowns
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All categories'),
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
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<LeadSource>(
                value: _selectedSource,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Source',
                  prefixIcon: Icon(Icons.filter_alt_outlined),
                ),
                items: [
                  const DropdownMenuItem<LeadSource>(
                    value: null,
                    child: Text('All sources'),
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

        const SizedBox(height: 12),

        // Clear filters button
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.refresh),
            label: const Text('Reset filters'),
          ),
        ),
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



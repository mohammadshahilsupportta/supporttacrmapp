import 'package:flutter/material.dart';
import '../../../../data/models/staff_model.dart';
import '../../../../data/models/category_model.dart';
import '../../../../data/models/user_model.dart';

class CategoryPermissionsDialog extends StatefulWidget {
  final StaffWithPermissionsModel staff;
  final List<CategoryModel> categories;
  final List<String> selectedCategoryIds;
  final Function(List<String>) onSave;

  const CategoryPermissionsDialog({
    super.key,
    required this.staff,
    required this.categories,
    required this.selectedCategoryIds,
    required this.onSave,
  });

  @override
  State<CategoryPermissionsDialog> createState() =>
      _CategoryPermissionsDialogState();
}

class _CategoryPermissionsDialogState
    extends State<CategoryPermissionsDialog> {
  late List<String> _selectedCategoryIds;

  @override
  void initState() {
    super.initState();
    _selectedCategoryIds = List.from(widget.selectedCategoryIds);
  }

  void _toggleCategory(String categoryId) {
    setState(() {
      if (_selectedCategoryIds.contains(categoryId)) {
        _selectedCategoryIds.remove(categoryId);
      } else {
        _selectedCategoryIds.add(categoryId);
      }
    });
  }

  String _getCategoryAccessText() {
    if (widget.staff.role == UserRole.marketingManager ||
        widget.staff.role == UserRole.admin ||
        widget.staff.role == UserRole.shopOwner) {
      return 'All categories';
    }
    if (_selectedCategoryIds.isEmpty) {
      return 'No categories';
    }
    return '${_selectedCategoryIds.length} category${_selectedCategoryIds.length != 1 ? 's' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final canSelectCategories = widget.staff.role != UserRole.marketingManager &&
        widget.staff.role != UserRole.admin &&
        widget.staff.role != UserRole.shopOwner;

    return AlertDialog(
      title: const Text('Manage Category Access'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select which categories ${widget.staff.name} can access',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (!canSelectCategories)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This role has access to all categories',
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.categories.length,
                  itemBuilder: (context, index) {
                    final category = widget.categories[index];
                    final isSelected = _selectedCategoryIds.contains(category.id);

                    return CheckboxListTile(
                      title: Row(
                        children: [
                          if (category.color != null)
                            Container(
                              width: 16,
                              height: 16,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Color(
                                  int.parse(
                                    category.color!.replaceFirst('#', '0xFF'),
                                  ),
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              category.name,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      value: isSelected,
                      onChanged: (value) => _toggleCategory(category.id),
                    );
                  },
                ),
              ),
              if (widget.categories.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No categories available',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ),
            ],
            const SizedBox(height: 8),
            Text(
              'Access: ${_getCategoryAccessText()}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: canSelectCategories
              ? () => widget.onSave(_selectedCategoryIds)
              : null,
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}


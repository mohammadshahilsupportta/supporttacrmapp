import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/models/category_model.dart';

class CategoryFormDialog extends StatefulWidget {
  final CategoryModel? category;
  final Function(CreateCategoryInput input) onCreate;
  final Function(UpdateCategoryInput input) onUpdate;

  const CategoryFormDialog({
    super.key,
    this.category,
    required this.onCreate,
    required this.onUpdate,
  });

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _colorController = TextEditingController();
  String? _selectedColor;

  static const List<String> _presetColors = [
    '#EF4444', // red
    '#F97316', // orange
    '#F59E0B', // amber
    '#EAB308', // yellow
    '#84CC16', // lime
    '#22C55E', // green
    '#10B981', // emerald
    '#14B8A6', // teal
    '#06B6D4', // cyan
    '#0EA5E9', // sky
    '#3B82F6', // blue
    '#6366F1', // indigo
    '#8B5CF6', // violet
    '#A855F7', // purple
    '#D946EF', // fuchsia
    '#EC4899', // pink
  ];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _descriptionController.text = widget.category!.description ?? '';
      _colorController.text = widget.category!.color ?? '';
      _selectedColor = widget.category!.color;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  bool _isValidColor(String? color) {
    if (color == null || color.isEmpty) return true;
    final hexPattern = RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$');
    return hexPattern.hasMatch(color);
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final color = _colorController.text.trim();

    if (widget.category != null) {
      widget.onUpdate(
        UpdateCategoryInput(
          id: widget.category!.id,
          name: name,
          description: description.isNotEmpty ? description : null,
          color: color.isNotEmpty ? color : null,
        ),
      );
    } else {
      widget.onCreate(
        CreateCategoryInput(
          name: name,
          description: description.isNotEmpty ? description : null,
          color: color.isNotEmpty ? color : null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category != null ? 'Edit Category' : 'Create Category'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label),
                    hintText: 'e.g., Product Sales, Service Inquiry',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    if (value.trim().length > 255) {
                      return 'Name must be less than 255 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                    hintText: 'Optional description for this category',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _colorController,
                  decoration: const InputDecoration(
                    labelText: 'Color',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.palette),
                    hintText: '#FF0000',
                    helperText: 'Choose a color to visually identify this category',
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[#0-9A-Fa-f]')),
                  ],
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (!_isValidColor(value)) {
                        return 'Invalid color format (e.g., #FF0000)';
                      }
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      _selectedColor = value.isNotEmpty ? value : null;
                    });
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'Preset Colors:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presetColors.map((color) {
                    final isSelected = _selectedColor == color;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                          _colorController.text = color;
                        });
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.grey.shade300,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _handleSubmit,
          child: Text(widget.category != null ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}


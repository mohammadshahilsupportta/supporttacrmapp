import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/staff_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/category_controller.dart';
import '../../../data/models/staff_model.dart';
import '../../../data/models/user_model.dart';
import '../../../core/widgets/loading_widget.dart';

class StaffCreateView extends StatefulWidget {
  const StaffCreateView({super.key});

  @override
  State<StaffCreateView> createState() => _StaffCreateViewState();
}

class _StaffCreateViewState extends State<StaffCreateView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  UserRole _selectedRole = UserRole.officeStaff;
  List<String> _selectedCategoryIds = [];
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authController = Get.find<AuthController>();
    final staffController = Get.find<StaffController>();

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

    final input = CreateStaffInput(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
      categoryIds: _selectedCategoryIds.isNotEmpty ? _selectedCategoryIds : null,
      phone: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
    );

    final success = await staffController.createStaff(
      authController.shop!.id,
      input,
    );

    if (success) {
      Get.snackbar(
        'Success',
        'Staff member created successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Get.back();
    } else {
      Get.snackbar(
        'Error',
        staffController.errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showCategoryDialog() {
    final categoryController = Get.find<CategoryController>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Categories'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: categoryController.categories.length,
            itemBuilder: (context, index) {
              final category = categoryController.categories[index];
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
                    Expanded(child: Text(category.name)),
                  ],
                ),
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedCategoryIds.add(category.id);
                    } else {
                      _selectedCategoryIds.remove(category.id);
                    }
                  });
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final staffController = Get.find<StaffController>();
    final categoryController = Get.find<CategoryController>();

    // Load categories if not loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authController.shop != null &&
          categoryController.categories.isEmpty) {
        categoryController.loadCategories(authController.shop!.id);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Staff Member'),
      ),
      body: Obx(() {
        if (staffController.isLoading) {
          return const LoadingWidget();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<UserRole>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                  items: [
                    UserRole.admin,
                    UserRole.marketingManager,
                    UserRole.officeStaff,
                    UserRole.freelance,
                  ].map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(UserModel.roleDisplayName(role)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedRole = value;
                        // Clear category selection if role has full access
                        if (value == UserRole.admin ||
                            value == UserRole.marketingManager) {
                          _selectedCategoryIds.clear();
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (_selectedRole != UserRole.admin &&
                    _selectedRole != UserRole.marketingManager) ...[
                  OutlinedButton.icon(
                    onPressed: _showCategoryDialog,
                    icon: const Icon(Icons.folder_open),
                    label: Text(
                      _selectedCategoryIds.isEmpty
                          ? 'Select Categories'
                          : '${_selectedCategoryIds.length} category${_selectedCategoryIds.length != 1 ? 's' : ''} selected',
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedCategoryIds.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: _selectedCategoryIds.map((categoryId) {
                        final category = categoryController.categories
                            .firstWhere((c) => c.id == categoryId);
                        return Chip(
                          label: Text(
                            category.name,
                            style: const TextStyle(fontSize: 12),
                          ),
                          onDeleted: () {
                            setState(() {
                              _selectedCategoryIds.remove(categoryId);
                            });
                          },
                        );
                      }).toList(),
                    ),
                ] else ...[
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
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Create Staff Member'),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}


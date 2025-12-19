import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/lead_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/category_controller.dart';
import '../../controllers/staff_controller.dart';
import '../../../data/models/lead_model.dart';
import '../../../data/models/category_model.dart';
import '../../../core/widgets/loading_widget.dart';

class LeadEditView extends StatefulWidget {
  final String leadId;

  const LeadEditView({super.key, required this.leadId});

  @override
  State<LeadEditView> createState() => _LeadEditViewState();
}

class _LeadEditViewState extends State<LeadEditView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _companyController = TextEditingController();
  final _addressController = TextEditingController();
  final _occupationController = TextEditingController();
  final _fieldOfWorkController = TextEditingController();
  final _notesController = TextEditingController();
  final _productsController = TextEditingController();

  LeadSource? _selectedSource;
  LeadStatus? _selectedStatus;
  String? _selectedAssignedTo;
  List<String> _selectedCategoryIds = [];

  bool _submitting = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Defer data loading to after the first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLeadData();
    });
  }

  Future<void> _loadLeadData() async {
    if (!mounted) return;
    
    final leadController = Get.find<LeadController>();
    final categoryController = Get.put(CategoryController());
    final staffController = Get.put(StaffController());
    final authController = Get.find<AuthController>();

    // Load lead data
    await leadController.loadLeadById(widget.leadId);
    
    // Load categories and staff
    if (authController.shop != null) {
      if (categoryController.categories.isEmpty) {
        await categoryController.loadCategories(authController.shop!.id);
      }
      if (staffController.staffList.isEmpty) {
        await staffController.loadStaff(authController.shop!.id);
      }
    }

    if (!mounted) return;
    
    final lead = leadController.selectedLead;
    if (lead != null) {
      setState(() {
        _nameController.text = lead.name;
        _emailController.text = lead.email ?? '';
        _phoneController.text = lead.phone ?? '';
        _whatsappController.text = lead.whatsapp ?? '';
        _companyController.text = lead.company ?? '';
        _addressController.text = lead.address ?? '';
        _occupationController.text = lead.occupation ?? '';
        _fieldOfWorkController.text = lead.fieldOfWork ?? '';
        _notesController.text = lead.notes ?? '';
        _productsController.text = lead.products?.join(', ') ?? '';
        _selectedSource = lead.source;
        _selectedStatus = lead.status;
        _selectedAssignedTo = lead.assignedTo;
        _selectedCategoryIds = lead.categories.map((c) => c.id).toList();
        _loading = false;
      });
    } else {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _companyController.dispose();
    _addressController.dispose();
    _occupationController.dispose();
    _fieldOfWorkController.dispose();
    _notesController.dispose();
    _productsController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final authController = Get.find<AuthController>();
    final leadController = Get.find<LeadController>();

    if (authController.shop == null) {
      Get.snackbar(
        'Error',
        'Shop info not available',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _submitting = true);

    final products = _productsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final input = CreateLeadInput(
      name: _nameController.text.trim(),
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
      phone: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
      whatsapp: _whatsappController.text.trim().isNotEmpty
          ? _whatsappController.text.trim()
          : null,
      company: _companyController.text.trim().isNotEmpty
          ? _companyController.text.trim()
          : null,
      address: _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : null,
      occupation: _occupationController.text.trim().isNotEmpty
          ? _occupationController.text.trim()
          : null,
      fieldOfWork: _fieldOfWorkController.text.trim().isNotEmpty
          ? _fieldOfWorkController.text.trim()
          : null,
      source: _selectedSource,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      status: _selectedStatus ?? LeadStatus.newLead,
      assignedTo: _selectedAssignedTo,
      categoryIds:
          _selectedCategoryIds.isNotEmpty ? _selectedCategoryIds : null,
      products: products.isNotEmpty ? products : null,
    );

    final ok = await leadController.updateLead(widget.leadId, input);

    setState(() => _submitting = false);

    if (ok) {
      // Navigate back to lead detail screen
      Get.back();
      
      // Show success message after navigation completes
      Future.delayed(const Duration(milliseconds: 500), () {
        Get.snackbar(
          'Success',
          'Lead updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16),
          icon: const Icon(Icons.check_circle, color: Colors.white),
          shouldIconPulse: false,
        );
      });
    } else {
      Get.snackbar(
        'Error',
        leadController.errorMessage.isNotEmpty
            ? leadController.errorMessage
            : 'Failed to update lead',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.error, color: Colors.white),
        shouldIconPulse: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryController = Get.find<CategoryController>();
    final staffController = Get.find<StaffController>();

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Lead'),
        ),
        body: const LoadingWidget(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Lead'),
      ),
      body: Obx(() {
        final categories = categoryController.categories;
        final staffList = staffController.staffList;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  title: 'Contact',
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _whatsappController,
                      decoration: const InputDecoration(
                        labelText: 'WhatsApp',
                        prefixIcon: Icon(Icons.chat_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: 'Company & Work',
                  children: [
                    TextFormField(
                      controller: _companyController,
                      decoration: const InputDecoration(
                        labelText: 'Company',
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _occupationController,
                      decoration: const InputDecoration(
                        labelText: 'Occupation',
                        prefixIcon: Icon(Icons.work_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _fieldOfWorkController,
                      decoration: const InputDecoration(
                        labelText: 'Field of Work',
                        prefixIcon: Icon(Icons.engineering_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _productsController,
                      decoration: const InputDecoration(
                        labelText: 'Products (comma separated)',
                        prefixIcon: Icon(Icons.shopping_bag_outlined),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: 'Status & Categories',
                  children: [
                    DropdownButtonFormField<LeadSource>(
                      value: _selectedSource,
                      decoration: const InputDecoration(
                        labelText: 'Source',
                        prefixIcon: Icon(Icons.filter_alt_outlined),
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<LeadSource>(
                          value: null,
                          child: Text('Select source'),
                        ),
                        ...LeadSource.values.map(
                          (s) => DropdownMenuItem<LeadSource>(
                            value: s,
                            child: Text(_sourceLabel(s)),
                          ),
                        ),
                      ],
                      onChanged: (val) => setState(() => _selectedSource = val),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<LeadStatus>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status *',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      isExpanded: true,
                      items: LeadStatus.values
                          .map(
                            (s) => DropdownMenuItem<LeadStatus>(
                              value: s,
                              child: Text(_statusLabel(s)),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedStatus = val);
                        }
                      },
                      validator: (val) =>
                          val == null ? 'Status is required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedAssignedTo,
                      decoration: const InputDecoration(
                        labelText: 'Assigned To',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Unassigned'),
                        ),
                        ...staffList.map(
                          (staff) => DropdownMenuItem<String>(
                            value: staff.id,
                            child: Text(staff.name),
                          ),
                        ),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedAssignedTo = val),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Categories',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories
                          .map(
                            (CategoryModel cat) => FilterChip(
                              label: Text(cat.name),
                              selected: _selectedCategoryIds.contains(cat.id),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedCategoryIds.add(cat.id);
                                  } else {
                                    _selectedCategoryIds.remove(cat.id);
                                  }
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SafeArea(
                  top: false,
                  minimum: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _submitting ? null : _handleSubmit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        _submitting ? 'Updating...' : 'Update Lead',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
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
}

Widget _buildSection({
  required String title,
  required List<Widget> children,
}) {
  return Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: Colors.grey.shade300,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );
}


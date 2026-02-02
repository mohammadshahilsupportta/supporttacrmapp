import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/lead_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/category_controller.dart';
import '../../controllers/staff_controller.dart';
import '../../../data/models/lead_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/user_model.dart';
import '../../../core/widgets/loading_widget.dart';

class LeadEditView extends StatefulWidget {
  final String leadId;

  const LeadEditView({super.key, required this.leadId});

  @override
  State<LeadEditView> createState() => _LeadEditViewState();
}

class _LeadEditViewState extends State<LeadEditView> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _alternativePhoneController = TextEditingController();
  final _requirementController = TextEditingController();
  final _businessPhoneController = TextEditingController();
  final _companyPhoneController = TextEditingController();
  final _occupationController = TextEditingController();
  final _fieldOfWorkController = TextEditingController();
  final _addressController = TextEditingController();
  final _homeAddressController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _countryController = TextEditingController();
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _notesController = TextEditingController();
  final _currentProductController = TextEditingController();
  final _currentAlternativeEmailController = TextEditingController();
  final _valueController = TextEditingController();

  LeadSource? _selectedSource;
  LeadStatus _selectedStatus = LeadStatus.needFollowUp;
  List<String> _selectedCategoryIds = [];
  List<String> _products = [];
  List<String> _alternativeEmails = [];
  String? _selectedAssignedTo;

  bool _submitting = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
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

    await leadController.loadLeadById(widget.leadId);

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
      final parsed = parseLeadNotes(lead.notes);
      setState(() {
        _phoneController.text = lead.phone ?? '';
        _companyController.text = lead.company ?? '';
        _nameController.text = lead.name;
        _emailController.text = lead.email ?? '';
        _whatsappController.text = lead.whatsapp ?? '';
        _alternativePhoneController.text = lead.alternativePhone ?? '';
        _requirementController.text = parsed.requirement;
        _notesController.text = parsed.additionalNotes;
        _businessPhoneController.text = lead.businessPhone ?? '';
        _companyPhoneController.text = lead.companyPhone ?? '';
        _occupationController.text = lead.occupation ?? '';
        _fieldOfWorkController.text = lead.fieldOfWork ?? '';
        _addressController.text = lead.address ?? '';
        _homeAddressController.text = lead.homeAddress ?? '';
        _businessAddressController.text = lead.businessAddress ?? '';
        _countryController.text = lead.country ?? '';
        _stateController.text = lead.state ?? '';
        _cityController.text = lead.city ?? '';
        _districtController.text = lead.district ?? '';
        _valueController.text = lead.value?.toString() ?? '';
        _products = List<String>.from(lead.products ?? []);
        _alternativeEmails = List<String>.from(lead.alternativeEmails ?? []);
        _selectedSource = lead.source;
        _selectedStatus = lead.status;
        _selectedAssignedTo = lead.assignedTo;
        _selectedCategoryIds = lead.categories.map((c) => c.id).toList();
        _loading = false;
      });
    } else {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _companyController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _whatsappController.dispose();
    _alternativePhoneController.dispose();
    _requirementController.dispose();
    _businessPhoneController.dispose();
    _companyPhoneController.dispose();
    _occupationController.dispose();
    _fieldOfWorkController.dispose();
    _addressController.dispose();
    _homeAddressController.dispose();
    _businessAddressController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _notesController.dispose();
    _currentProductController.dispose();
    _currentAlternativeEmailController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _addProduct() {
    final p = _currentProductController.text.trim();
    if (p.isNotEmpty && !_products.contains(p)) {
      setState(() {
        _products.add(p);
        _currentProductController.clear();
      });
    }
  }

  void _removeProduct(String p) {
    setState(() => _products.remove(p));
  }

  void _addAlternativeEmail() {
    final e = _currentAlternativeEmailController.text.trim();
    if (e.isNotEmpty && !_alternativeEmails.contains(e)) {
      final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
      if (emailRegex.hasMatch(e)) {
        setState(() {
          _alternativeEmails.add(e);
          _currentAlternativeEmailController.clear();
        });
      }
    }
  }

  void _removeAlternativeEmail(String e) {
    setState(() => _alternativeEmails.remove(e));
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final company = _companyController.text.trim();
    if (name.isEmpty && company.isEmpty) {
      Get.snackbar(
        'Validation',
        'Provide at least Company name or Owner/Contact name',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
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

    final effectiveName = name.isNotEmpty ? name : company;

    final notes = buildLeadNotes(
      _requirementController.text.trim().isNotEmpty
          ? _requirementController.text.trim()
          : null,
      _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    final valueText = _valueController.text.trim();
    final value = valueText.isEmpty ? null : (double.tryParse(valueText));

    final input = CreateLeadInput(
      name: effectiveName,
      phone: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
      whatsapp: _whatsappController.text.trim().isNotEmpty
          ? _whatsappController.text.trim()
          : null,
      company: company.isNotEmpty ? company : null,
      alternativePhone: _alternativePhoneController.text.trim().isNotEmpty
          ? _alternativePhoneController.text.trim()
          : null,
      businessPhone: _businessPhoneController.text.trim().isNotEmpty
          ? _businessPhoneController.text.trim()
          : null,
      companyPhone: _companyPhoneController.text.trim().isNotEmpty
          ? _companyPhoneController.text.trim()
          : null,
      alternativeEmails: _alternativeEmails.isNotEmpty
          ? _alternativeEmails
          : null,
      occupation: _occupationController.text.trim().isNotEmpty
          ? _occupationController.text.trim()
          : null,
      fieldOfWork: _fieldOfWorkController.text.trim().isNotEmpty
          ? _fieldOfWorkController.text.trim()
          : null,
      address: _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : null,
      homeAddress: _homeAddressController.text.trim().isNotEmpty
          ? _homeAddressController.text.trim()
          : null,
      businessAddress: _businessAddressController.text.trim().isNotEmpty
          ? _businessAddressController.text.trim()
          : null,
      country: _countryController.text.trim().isNotEmpty
          ? _countryController.text.trim()
          : null,
      state: _stateController.text.trim().isNotEmpty
          ? _stateController.text.trim()
          : null,
      city: _cityController.text.trim().isNotEmpty
          ? _cityController.text.trim()
          : null,
      district: _districtController.text.trim().isNotEmpty
          ? _districtController.text.trim()
          : null,
      source: _selectedSource,
      notes: notes.isNotEmpty ? notes : null,
      status: _selectedStatus,
      assignedTo: _selectedAssignedTo,
      categoryIds: _selectedCategoryIds.isNotEmpty
          ? _selectedCategoryIds
          : null,
      products: _products.isNotEmpty ? _products : null,
      value: value,
    );

    final ok = await leadController.updateLead(widget.leadId, input);

    setState(() => _submitting = false);

    if (ok) {
      Get.back();
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
    final authController = Get.find<AuthController>();
    final isAdmin =
        authController.user?.role == UserRole.shopOwner ||
        authController.user?.role == UserRole.admin ||
        authController.user?.role == UserRole.marketingManager;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Lead'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Get.back(),
          ),
        ),
        body: const LoadingWidget(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Lead'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (categoryController.isLoading &&
            categoryController.categories.isEmpty) {
          return const LoadingWidget();
        }

        final categories = categoryController.categories;
        final staffList = isAdmin
            ? Get.find<StaffController>().staffList
            : <dynamic>[];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Contact Information
                _buildCard(
                  context,
                  title: 'Contact Information',
                  description: 'Basic contact details for the lead',
                  children: [
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number *',
                        hintText: '+1 234 567 8900',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Phone is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _companyController,
                            decoration: const InputDecoration(
                              labelText: 'Company name',
                              hintText: 'Optional if owner name is given',
                              prefixIcon: Icon(Icons.business_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Owner / Contact name',
                              hintText: 'Optional if company name is given',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'At least one of Company name or Owner/Contact name is required.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'john.doe@example.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _whatsappController,
                      decoration: const InputDecoration(
                        labelText: 'WhatsApp Number',
                        hintText: '+1 234 567 8900',
                        prefixIcon: Icon(Icons.chat_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _alternativePhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Alternative Phone',
                        hintText: '+1 234 567 8900',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _buildChipInput(
                      context,
                      label: 'Alternative Emails',
                      hint: 'alternative@example.com',
                      controller: _currentAlternativeEmailController,
                      chips: _alternativeEmails,
                      onAdd: _addAlternativeEmail,
                      onRemove: _removeAlternativeEmail,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. Requirement
                _buildCard(
                  context,
                  title: 'Requirement',
                  description: 'Optional. What is the lead looking for?',
                  children: [
                    TextFormField(
                      controller: _requirementController,
                      decoration: const InputDecoration(
                        hintText:
                            "Describe the lead's requirement or need in detail (optional)...",
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. Professional Information
                _buildExpandableCard(
                  context,
                  title: 'Professional Information',
                  description: 'Optional professional details',
                  initiallyExpanded: false,
                  children: [
                    TextFormField(
                      controller: _businessPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Business Phone',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _companyPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Company Phone',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _occupationController,
                      decoration: const InputDecoration(
                        labelText: 'Occupation',
                        hintText: 'Job title',
                        prefixIcon: Icon(Icons.work_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _fieldOfWorkController,
                      decoration: const InputDecoration(
                        labelText: 'Field of Work',
                        hintText: 'Industry or field',
                        prefixIcon: Icon(Icons.engineering_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Primary Address',
                        hintText: 'Full address',
                        prefixIcon: Icon(Icons.location_on_outlined),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _homeAddressController,
                      decoration: const InputDecoration(
                        labelText: 'Home Address',
                        prefixIcon: Icon(Icons.home_outlined),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _businessAddressController,
                      decoration: const InputDecoration(
                        labelText: 'Business Address',
                        prefixIcon: Icon(Icons.business_outlined),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 4. Location Details
                _buildExpandableCard(
                  context,
                  title: 'Location Details',
                  description: 'Location information for this lead',
                  initiallyExpanded: false,
                  children: [
                    TextFormField(
                      controller: _countryController,
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        prefixIcon: Icon(Icons.public_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(
                        labelText: 'State',
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _districtController,
                      decoration: const InputDecoration(
                        labelText: 'District',
                        prefixIcon: Icon(Icons.place_outlined),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 5. Source & Category
                _buildExpandableCard(
                  context,
                  title: 'Source & Category',
                  description: 'Lead source and categorization',
                  initiallyExpanded: false,
                  children: [
                    DropdownButtonFormField<LeadSource>(
                      initialValue: _selectedSource,
                      decoration: const InputDecoration(
                        labelText: 'Source',
                        prefixIcon: Icon(Icons.filter_alt_outlined),
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<LeadSource>(
                          value: null,
                          child: Text('None'),
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _valueController,
                      decoration: const InputDecoration(
                        labelText: 'Potential value (₹)',
                        hintText: '0',
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'How valuable this lead is. Optional.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<LeadStatus>(
                      initialValue: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
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
                        if (val != null) setState(() => _selectedStatus = val);
                      },
                    ),
                    if (isAdmin && staffList.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String?>(
                        initialValue: _selectedAssignedTo,
                        decoration: const InputDecoration(
                          labelText: 'Assigned To',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Unassigned'),
                          ),
                          ...staffList.map(
                            (s) => DropdownMenuItem<String?>(
                              value: s.id,
                              child: Text(s.name),
                            ),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => _selectedAssignedTo = val),
                      ),
                    ],
                    if (categories.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Categories',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories.map((CategoryModel cat) {
                          final isSelected = _selectedCategoryIds.contains(
                            cat.id,
                          );
                          final theme = Theme.of(context);
                          return FilterChip(
                            label: Text(
                              cat.name,
                              style: TextStyle(
                                color: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedCategoryIds.add(cat.id);
                                } else {
                                  _selectedCategoryIds.remove(cat.id);
                                }
                              });
                            },
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            selectedColor: theme.colorScheme.primary,
                            checkmarkColor: theme.colorScheme.onPrimary,
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // 6. Products & Additional Notes
                _buildExpandableCard(
                  context,
                  title: 'Products & Additional Notes',
                  description: 'Optional additional information',
                  initiallyExpanded: false,
                  children: [
                    _buildChipInput(
                      context,
                      label: 'Products',
                      hint: 'Product name',
                      controller: _currentProductController,
                      chips: _products,
                      onAdd: _addProduct,
                      onRemove: _removeProduct,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Additional Notes',
                        hintText: 'Any additional notes or information...',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

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

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String description,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableCard(
    BuildContext context, {
    required String title,
    required String description,
    required bool initiallyExpanded,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: const Icon(Icons.expand_more),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipInput(
    BuildContext context, {
    required String label,
    required String hint,
    required TextEditingController controller,
    required List<String> chips,
    required VoidCallback onAdd,
    required void Function(String) onRemove,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hint,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                keyboardType: keyboardType,
                onFieldSubmitted: (_) => onAdd(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(icon: const Icon(Icons.add), onPressed: onAdd),
          ],
        ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips
                .map(
                  (c) => Chip(
                    label: Text(c),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => onRemove(c),
                  ),
                )
                .toList(),
          ),
        ],
      ],
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
      case LeadStatus.willContact:
        return 'Will Contact';
      case LeadStatus.needFollowUp:
        return 'Need Follow-Up';
      case LeadStatus.appointmentScheduled:
        return 'Appointment Scheduled';
      case LeadStatus.proposalSent:
        return 'Proposal Sent';
      case LeadStatus.alreadyHas:
        return 'Already Has';
      case LeadStatus.noNeedNow:
        return 'No Need Now';
      case LeadStatus.closedWon:
        return 'Closed – Won';
      case LeadStatus.closedLost:
        return 'Closed – Lost';
    }
  }
}

import 'package:get/get.dart';
import '../../viewmodels/staff_viewmodel.dart';
import '../../data/models/staff_model.dart';
import '../../data/models/user_model.dart';
import '../../core/utils/helpers.dart';
import '../../core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StaffController extends GetxController {
  final StaffViewModel _viewModel = StaffViewModel();

  // Observables
  final _isLoading = false.obs;
  final _errorMessage = ''.obs;
  final _staffList = <StaffWithPermissionsModel>[].obs;
  final _selectedStaff = Rxn<StaffWithPermissionsModel>();

  // Getters
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  List<StaffWithPermissionsModel> get staffList => _staffList;
  StaffWithPermissionsModel? get selectedStaff => _selectedStaff.value;

  // Load all staff
  Future<void> loadStaff(String shopId, {bool force = false}) async {
    if (!force && _isLoading.value) return; // Prevent duplicate loads unless forced
    
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final staff = await _viewModel.getStaff(shopId);
      _staffList.value = staff;
      print('Loaded ${staff.length} staff members'); // Debug
    } catch (e, stackTrace) {
      _errorMessage.value = Helpers.handleError(e);
      print('Error loading staff: ${_errorMessage.value}'); // Debug
      print('Error details: $e'); // Debug
      print('Stack trace: $stackTrace'); // Debug
    } finally {
      _isLoading.value = false;
    }
  }

  // Load staff with permissions
  Future<void> loadStaffWithPermissions(String userId) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final staff = await _viewModel.getStaffWithPermissions(userId);
      _selectedStaff.value = staff;
    } catch (e) {
      _errorMessage.value = Helpers.handleError(e);
    } finally {
      _isLoading.value = false;
    }
  }

  // Create staff member
  Future<bool> createStaff(
    String shopId,
    CreateStaffInput input,
  ) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      // Normalize and validate email
      final normalizedEmail = input.email.trim().toLowerCase();
      
      if (!Helpers.isValidEmail(normalizedEmail)) {
        _errorMessage.value = 'Please enter a valid email address';
        return false;
      }

      // The website likely uses Admin API or a backend function
      // Since we can't use Admin API from client, we need to use signUp
      // But Supabase is rejecting the email validation
      // Try signUp with the email as-is (no normalization) first
      String? userId;
      AuthResponse? authResponse;
      
      // Try using Edge Function first (uses Admin API, bypasses email validation)
      bool edgeFunctionSucceeded = false;
      try {
        print('Attempting to create staff via Edge Function (Admin API)');
        
        final functionResult = await SupabaseService.invokeFunction(
          'create_staff',
          body: {
            'email': normalizedEmail,
            'password': input.password,
            'name': input.name,
            'role': input.role != null 
                ? UserModel.roleToString(input.role!)
                : 'office_staff',
            'shop_id': shopId,
            'phone': input.phone,
            'category_ids': input.categoryIds,
          },
        );
        
        if (functionResult['success'] == true && functionResult['auth_user_id'] != null) {
          userId = functionResult['auth_user_id'] as String;
          print('Successfully created staff via Edge Function with auth_user_id: $userId');
          
          // Staff record is already created by the Edge Function
          // Just reload the staff list
          await loadStaff(shopId, force: true);
          edgeFunctionSucceeded = true;
          return true;
        } else {
          // Edge Function returned an error, fall back to direct signUp
          final errorMsg = functionResult['error']?.toString() ?? 
              'Failed to create staff via Edge Function';
          print('Edge Function error: $errorMsg');
        }
      } catch (functionError) {
        // Edge Function doesn't exist or failed, fall back to direct signUp
        print('Edge Function not available or failed, falling back to direct signUp: $functionError');
      }
      
      // Fall back to direct signUp if Edge Function failed or doesn't exist
      if (!edgeFunctionSucceeded) {
        // Try creating auth user directly
        try {
          print('Attempting to create user with email: $normalizedEmail');
          authResponse = await SupabaseService.auth.signUp(
            email: normalizedEmail,
            password: input.password,
            data: {
              'name': input.name,
              'role': input.role != null 
                  ? UserModel.roleToString(input.role!)
                  : 'office_staff',
            },
          );
          
          if (authResponse.user == null) {
            // User might be created but email confirmation required
            if (authResponse.session == null) {
              _errorMessage.value = 'User creation may require email confirmation. Please check your email.';
            } else {
              _errorMessage.value = 'Failed to create authentication user';
            }
            return false;
          }
          
          userId = authResponse.user!.id;
          print('Successfully created auth user with ID: $userId');
        } catch (e) {
          final errorString = e.toString().toLowerCase();
          
          // Check if user already exists
          if (errorString.contains('user already registered') ||
              errorString.contains('already registered') ||
              errorString.contains('email already') ||
              errorString.contains('already exists')) {
            _errorMessage.value = 'A user with this email already exists. Please use a different email.';
            return false;
          }
          
          // Check for email validation errors
          if (errorString.contains('email_address_invalid') ||
              (errorString.contains('email address') && errorString.contains('invalid'))) {
            _errorMessage.value = 'Email validation failed: "${input.email}" is being rejected by Supabase\'s email validation. Please deploy the Edge Function to use Admin API, or use the website to create staff members.';
            print('Email validation error: $e');
            print('Email attempted: $normalizedEmail');
            return false;
          }
          
          // Re-throw other errors
          print('Auth error: $e');
          rethrow;
        }
        
        // Verify we have a valid user ID
        if (userId.isEmpty) {
          _errorMessage.value = 'Failed to get user ID from authentication response';
          return false;
        }

        // Create input with normalized email for staff record
        final normalizedInput = CreateStaffInput(
          name: input.name,
          email: normalizedEmail,
          password: input.password,
          role: input.role,
          categoryIds: input.categoryIds,
          phone: input.phone,
        );

        // Then create staff record
        try {
          await _viewModel.createStaff(
            shopId,
            normalizedInput,
            userId,
          );

          // Reload staff list to get the complete data with permissions
          await loadStaff(shopId, force: true);

          return true;
        } catch (staffError) {
          // If staff creation fails, log the error
          print('Staff record creation failed: $staffError');
          print('Auth user was created with ID: $userId');
          rethrow;
        }
      }
      
      // This should never be reached, but satisfies the analyzer
      // All code paths above should return true or false
      return false;
    } catch (e) {
      print('Error creating staff: $e'); // Debug log
      _errorMessage.value = Helpers.handleError(e);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Update staff member
  Future<bool> updateStaff(UpdateStaffInput input) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      await _viewModel.updateStaff(input);
      final index = _staffList.indexWhere((s) => s.id == input.id);
      if (index != -1) {
        // Reload staff with permissions to get updated data
        final withPermissions = await _viewModel.getStaffWithPermissions(input.id);
        if (withPermissions != null) {
          _staffList[index] = withPermissions;
        } else {
          // If reload fails, update locally
          final current = _staffList[index];
          _staffList[index] = StaffWithPermissionsModel(
            id: current.id,
            shopId: current.shopId,
            email: input.email ?? current.email,
            name: input.name ?? current.name,
            role: input.role ?? current.role,
            isActive: input.isActive ?? current.isActive,
            authUserId: current.authUserId,
            createdAt: current.createdAt,
            updatedAt: DateTime.now(),
            categoryPermissions: current.categoryPermissions,
          );
        }
      }
      return true;
    } catch (e) {
      _errorMessage.value = Helpers.handleError(e);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Deactivate staff member
  Future<bool> deactivateStaff(String userId) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      await _viewModel.deactivateStaff(userId);
      final index = _staffList.indexWhere((s) => s.id == userId);
      if (index != -1) {
        _staffList[index] = StaffWithPermissionsModel(
          id: _staffList[index].id,
          shopId: _staffList[index].shopId,
          email: _staffList[index].email,
          name: _staffList[index].name,
          role: _staffList[index].role,
          isActive: false,
          authUserId: _staffList[index].authUserId,
          createdAt: _staffList[index].createdAt,
          updatedAt: _staffList[index].updatedAt,
          categoryPermissions: _staffList[index].categoryPermissions,
        );
      }
      return true;
    } catch (e) {
      _errorMessage.value = Helpers.handleError(e);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Delete staff member
  Future<bool> deleteStaff(String userId) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      await _viewModel.deleteStaff(userId);
      _staffList.removeWhere((s) => s.id == userId);
      if (_selectedStaff.value?.id == userId) {
        _selectedStaff.value = null;
      }
      return true;
    } catch (e) {
      _errorMessage.value = Helpers.handleError(e);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Assign categories to staff
  Future<bool> assignCategories(
    String staffId,
    String shopId,
    List<String> categoryIds,
  ) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      await _viewModel.assignCategories(staffId, shopId, categoryIds);
      // Reload staff with permissions
      final withPermissions = await _viewModel.getStaffWithPermissions(staffId);
      if (withPermissions != null) {
        final index = _staffList.indexWhere((s) => s.id == staffId);
        if (index != -1) {
          _staffList[index] = withPermissions;
        }
        if (_selectedStaff.value?.id == staffId) {
          _selectedStaff.value = withPermissions;
        }
      }
      return true;
    } catch (e) {
      _errorMessage.value = Helpers.handleError(e);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Set selected staff
  void setSelectedStaff(StaffWithPermissionsModel? staff) {
    _selectedStaff.value = staff;
  }
}


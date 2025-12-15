import 'package:get/get.dart';
import '../../viewmodels/staff_viewmodel.dart';
import '../../data/models/staff_model.dart';
import '../../core/utils/helpers.dart';
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
  Future<void> loadStaff(String shopId) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final staff = await _viewModel.getStaff(shopId);
      _staffList.value = staff;
    } catch (e) {
      _errorMessage.value = Helpers.handleError(e);
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
      // First create auth user
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: input.email,
        password: input.password,
      );

      if (authResponse.user == null) {
        _errorMessage.value = 'Failed to create authentication user';
        return false;
      }

      // Then create staff record
      final staff = await _viewModel.createStaff(
        shopId,
        input,
        authResponse.user!.id,
      );

      _staffList.add(StaffWithPermissionsModel(
        id: staff.id,
        shopId: staff.shopId,
        email: staff.email,
        name: staff.name,
        role: staff.role,
        isActive: staff.isActive,
        authUserId: staff.authUserId,
        createdAt: staff.createdAt,
        updatedAt: staff.updatedAt,
        categoryPermissions: [],
      ));

      return true;
    } catch (e) {
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
        // Reload staff with permissions to get updated category permissions
        final withPermissions = await _viewModel.getStaffWithPermissions(input.id);
        if (withPermissions != null) {
          _staffList[index] = withPermissions;
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


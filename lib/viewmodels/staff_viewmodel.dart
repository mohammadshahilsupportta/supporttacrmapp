import '../data/repositories/staff_repository.dart';
import '../data/models/staff_model.dart';

class StaffViewModel {
  final StaffRepository _repository = StaffRepository();

  // Get all staff members
  Future<List<StaffWithPermissionsModel>> getStaff(String shopId) async {
    return await _repository.findAll(shopId);
  }

  // Get staff by ID
  Future<StaffModel?> getStaffById(String userId) async {
    return await _repository.findById(userId);
  }

  // Get staff with permissions
  Future<StaffWithPermissionsModel?> getStaffWithPermissions(
      String userId) async {
    return await _repository.findWithPermissions(userId);
  }

  // Create staff member
  Future<StaffModel> createStaff(
    String shopId,
    CreateStaffInput input,
    String authUserId,
  ) async {
    return await _repository.create(shopId, input, authUserId);
  }

  // Update staff member
  Future<StaffModel> updateStaff(UpdateStaffInput input) async {
    return await _repository.update(input);
  }

  // Deactivate staff member
  Future<void> deactivateStaff(String userId) async {
    await _repository.deactivate(userId);
  }

  // Delete staff member
  Future<void> deleteStaff(String userId) async {
    await _repository.delete(userId);
  }

  // Get category IDs for staff
  Future<List<String>> getStaffCategoryIds(String staffId) async {
    return await _repository.getCategoryIds(staffId);
  }

  // Assign categories to staff
  Future<void> assignCategories(
    String staffId,
    String shopId,
    List<String> categoryIds,
  ) async {
    await _repository.assignCategories(staffId, shopId, categoryIds);
  }
}


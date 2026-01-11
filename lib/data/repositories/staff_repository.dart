import '../models/staff_model.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/helpers.dart';

class StaffRepository {
  // Check if staff table exists by trying to query it
  Future<bool> _staffTableExists() async {
    try {
      await SupabaseService.from('staff').select('id').limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get all staff members in a shop
  Future<List<StaffWithPermissionsModel>> findAll(String shopId) async {
    try {
      final hasStaffTable = await _staffTableExists();
      List<dynamic> data;

      if (hasStaffTable) {
        // Use staff table (new schema)
        data =
            await SupabaseService.from('staff')
                    .select('''
              *,
              staff_category_permissions(
                category:categories(*)
              )
            ''')
                    .eq('shop_id', shopId)
                    .order('created_at', ascending: false)
                as List<dynamic>? ??
            [];
      } else {
        // Fallback to users table (old schema)
        data =
            await SupabaseService.from('users')
                    .select('''
              *,
              staff_category_permissions(
                category:categories(*)
              )
            ''')
                    .eq('shop_id', shopId)
                    .neq('role', 'shop_owner')
                    .order('created_at', ascending: false)
                as List<dynamic>? ??
            [];
      }

      return data.map((json) {
        try {
          return StaffWithPermissionsModel.fromJson(
            json as Map<String, dynamic>,
          );
        } catch (e) {
          print('Error parsing staff member: $e');
          print('JSON data: $json');
          rethrow;
        }
      }).toList();
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }

  // Get a single staff member by ID
  Future<StaffModel?> findById(String userId) async {
    try {
      final hasStaffTable = await _staffTableExists();
      Map<String, dynamic>? data;

      if (hasStaffTable) {
        data = await SupabaseService.from(
          'staff',
        ).select('*').eq('id', userId).maybeSingle();
      } else {
        data = await SupabaseService.from(
          'users',
        ).select('*').eq('id', userId).maybeSingle();
      }

      if (data == null) return null;
      return StaffModel.fromJson(data);
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }

  // Get staff member with their category permissions
  Future<StaffWithPermissionsModel?> findWithPermissions(String userId) async {
    try {
      final hasStaffTable = await _staffTableExists();
      Map<String, dynamic>? data;

      if (hasStaffTable) {
        data = await SupabaseService.from('staff')
            .select('''
              *,
              staff_category_permissions(
                category:categories(*)
              )
            ''')
            .eq('id', userId)
            .maybeSingle();
      } else {
        data = await SupabaseService.from('users')
            .select('''
              *,
              staff_category_permissions(
                category:categories(*)
              )
            ''')
            .eq('id', userId)
            .maybeSingle();
      }

      if (data == null) return null;
      return StaffWithPermissionsModel.fromJson(data);
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }

  // Create a new staff member
  // Note: Auth user should be created via Supabase Auth first
  Future<StaffModel> create(
    String shopId,
    CreateStaffInput input,
    String authUserId,
  ) async {
    try {
      final hasStaffTable = await _staffTableExists();
      final userData = input.toJson();
      userData.remove('password'); // Remove password from user data
      userData.remove('category_ids'); // Remove category_ids

      Map<String, dynamic> data;
      if (hasStaffTable) {
        data = await SupabaseService.from('staff')
            .insert({
              ...userData,
              'shop_id': shopId,
              'auth_user_id': authUserId,
              'is_active': true,
            })
            .select()
            .single();
      } else {
        data = await SupabaseService.from('users')
            .insert({
              ...userData,
              'shop_id': shopId,
              'auth_user_id': authUserId,
              'is_active': true,
            })
            .select()
            .single();
      }

      final staff = StaffModel.fromJson(data);

      // Assign category permissions if provided
      if (input.categoryIds != null && input.categoryIds!.isNotEmpty) {
        await assignCategories(staff.id, shopId, input.categoryIds!);
      }

      return staff;
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }

  // Update a staff member
  Future<StaffModel> update(UpdateStaffInput input) async {
    try {
      final hasStaffTable = await _staffTableExists();
      // Get the staff's shop_id for permission assignment
      final existingStaff = await findById(input.id);
      if (existingStaff == null) {
        throw Exception('Staff not found');
      }

      final updateData = input.toJson();
      updateData.remove('category_ids'); // Remove category_ids from update

      Map<String, dynamic> data;
      if (hasStaffTable) {
        data = await SupabaseService.from('staff')
            .update({
              ...updateData,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', input.id)
            .select()
            .single();
      } else {
        data = await SupabaseService.from('users')
            .update({
              ...updateData,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', input.id)
            .select()
            .single();
      }

      final staff = StaffModel.fromJson(data);

      // Update category permissions if provided
      if (input.categoryIds != null) {
        await assignCategories(
          staff.id,
          existingStaff.shopId,
          input.categoryIds!,
        );
      }

      return staff;
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }

  // Deactivate a staff member (soft delete)
  Future<void> deactivate(String userId) async {
    try {
      final hasStaffTable = await _staffTableExists();
      if (hasStaffTable) {
        await SupabaseService.from('staff')
            .update({
              'is_active': false,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', userId);
      } else {
        await SupabaseService.from('users')
            .update({
              'is_active': false,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', userId);
      }
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }

  // Hard delete a staff member
  Future<void> delete(String userId) async {
    try {
      final hasStaffTable = await _staffTableExists();
      // First remove all category permissions
      await SupabaseService.from(
        'staff_category_permissions',
      ).delete().eq(hasStaffTable ? 'staff_id' : 'user_id', userId);

      // Then delete the staff/user
      if (hasStaffTable) {
        await SupabaseService.from('staff').delete().eq('id', userId);
      } else {
        await SupabaseService.from('users').delete().eq('id', userId);
      }
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }

  // Assign categories to a staff member
  // This replaces all existing category permissions
  Future<void> assignCategories(
    String staffId,
    String shopId,
    List<String> categoryIds,
  ) async {
    try {
      final hasStaffTable = await _staffTableExists();
      // Remove existing permissions
      await SupabaseService.from(
        'staff_category_permissions',
      ).delete().eq(hasStaffTable ? 'staff_id' : 'user_id', staffId);

      // Add new permissions
      if (categoryIds.isNotEmpty) {
        final permissions = categoryIds
            .map(
              (categoryId) => hasStaffTable
                  ? {
                      'staff_id': staffId,
                      'category_id': categoryId,
                      'shop_id': shopId,
                    }
                  : {
                      'user_id': staffId,
                      'category_id': categoryId,
                      'shop_id': shopId,
                    },
            )
            .toList();

        await SupabaseService.from(
          'staff_category_permissions',
        ).insert(permissions);
      }
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }

  // Get category IDs assigned to a staff member
  Future<List<String>> getCategoryIds(String staffId) async {
    try {
      final hasStaffTable = await _staffTableExists();
      final data =
          await SupabaseService.from('staff_category_permissions')
                  .select('category_id')
                  .eq(hasStaffTable ? 'staff_id' : 'user_id', staffId)
              as List<dynamic>? ??
          [];
      return data.map((p) => p['category_id'] as String).toList();
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }
}

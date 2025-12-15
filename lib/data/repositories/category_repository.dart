import '../models/category_model.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/helpers.dart';

class CategoryRepository {
  // Get all categories for a shop
  Future<List<CategoryModel>> findAll(String shopId) async {
    try {
      final data = await SupabaseService.from('categories')
          .select()
          .eq('shop_id', shopId)
          .order('name', ascending: true) as List<dynamic>? ?? [];
      return data
          .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }

  // Get category by ID
  Future<CategoryModel?> findById(String categoryId) async {
    try {
      final data = await SupabaseService.from(
        'categories',
      ).select().eq('id', categoryId).maybeSingle();

      if (data == null) return null;
      return CategoryModel.fromJson(data);
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }

  // Create category
  Future<CategoryModel> create(String shopId, CreateCategoryInput input) async {
    try {
      final data = await SupabaseService.from(
        'categories',
      ).insert({...input.toJson(), 'shop_id': shopId}).select().single();

      return CategoryModel.fromJson(data);
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }

  // Update category
  Future<CategoryModel> update(UpdateCategoryInput input) async {
    try {
      final data = await SupabaseService.from('categories')
          .update({
            ...input.toJson(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', input.id)
          .select()
          .single();

      return CategoryModel.fromJson(data);
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }

  // Delete category
  Future<void> delete(String categoryId) async {
    try {
      await SupabaseService.from('categories').delete().eq('id', categoryId);
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }
}

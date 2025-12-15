import '../models/shop_model.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/helpers.dart';

class ShopRepository {
  // Get shop by ID
  Future<ShopModel?> getById(String shopId) async {
    try {
      final data = await SupabaseService
          .from('shops')
          .select()
          .eq('id', shopId)
          .maybeSingle();
      
      if (data == null) return null;
      return ShopModel.fromJson(data);
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }

  // Get shop by auth user ID
  Future<ShopModel?> getByAuthUserId(String authUserId) async {
    try {
      final data = await SupabaseService
          .from('shops')
          .select()
          .eq('auth_user_id', authUserId)
          .maybeSingle();
      
      if (data == null) return null;
      return ShopModel.fromJson(data);
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }
}


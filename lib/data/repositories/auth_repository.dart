import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/helpers.dart';
import '../models/user_model.dart';
import 'shop_repository.dart';

class AuthRepository {
  final _auth = SupabaseService.auth;
  final _shopRepository = ShopRepository();

  // Sign in with email and password - enhanced with user and shop verification
  Future<Map<String, dynamic>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Sign in with Supabase Auth
      final authResponse = await _auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Authentication failed');
      }

      // 2. Try to get user data from users table first (shop owners/admins)
      var userData = await SupabaseService
          .from('users')
          .select()
          .eq('auth_user_id', authResponse.user!.id)
          .maybeSingle();

      UserModel? user;
      
      // 3. If not found in users table, check staff table
      if (userData == null) {
        final staffData = await SupabaseService
            .from('staff')
            .select()
            .eq('auth_user_id', authResponse.user!.id)
            .maybeSingle();
        
        if (staffData == null) {
          await _auth.signOut();
          throw Exception('User account not found in database');
        }
        
        // Verify staff is active
        if (staffData['is_active'] != true) {
          await _auth.signOut();
          throw Exception('Staff account is inactive');
        }
        
        // Convert staff to UserModel
        user = UserModel.fromJson(staffData);
        userData = staffData;
      } else {
        user = UserModel.fromJson(userData);
      }

      // 4. Get shop data
      final shop = await _shopRepository.getById(user.shopId);
      
      if (shop == null) {
        await _auth.signOut();
        throw Exception('Shop data not found');
      }

      // 5. Verify shop is active
      if (!shop.isActive) {
        await _auth.signOut();
        throw Exception('Shop account is inactive');
      }

      // 6. Return user and shop data
      return {
        'user': user,
        'shop': shop,
        'authUser': authResponse.user!,
      };
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }

  // Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _auth.signUp(
        email: email,
        password: password,
        data: data,
      );
      return response;
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }

  // Get current authenticated user data (from users or staff table)
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final authUser = _auth.currentUser;
      if (authUser == null) return null;

      // Try to get user data from users table first (shop owners/admins)
      var userData = await SupabaseService
          .from('users')
          .select()
          .eq('auth_user_id', authUser.id)
          .maybeSingle();

      UserModel? user;
      
      // If not found in users table, check staff table
      if (userData == null) {
        final staffData = await SupabaseService
            .from('staff')
            .select()
            .eq('auth_user_id', authUser.id)
            .maybeSingle();
        
        if (staffData == null) return null;
        
        // Verify staff is active
        if (staffData['is_active'] != true) return null;
        
        // Convert staff to UserModel
        user = UserModel.fromJson(staffData);
        userData = staffData;
      } else {
        user = UserModel.fromJson(userData);
      }
      
      final shop = await _shopRepository.getById(user.shopId);
      if (shop == null) return null;

      return {
        'user': user,
        'shop': shop,
        'authUser': authUser,
      };
    } catch (e) {
      return null;
    }
  }

  // Get current user (Supabase auth user)
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Get current session
  Session? getCurrentSession() {
    return _auth.currentSession;
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }

  // Update user
  Future<UserResponse> updateUser({
    String? email,
    String? password,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _auth.updateUser(
        UserAttributes(
          email: email,
          password: password,
          data: data,
        ),
      );
      return response;
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }
}


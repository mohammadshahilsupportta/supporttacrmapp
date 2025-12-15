import '../data/repositories/auth_repository.dart';

class AuthViewModel {
  final AuthRepository _authRepository = AuthRepository();

  // Sign in - returns user and shop data
  Future<Map<String, dynamic>?> signIn(String email, String password) async {
    try {
      final result = await _authRepository.signInWithEmail(
        email: email,
        password: password,
      );
      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Get current user data (user + shop)
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      return await _authRepository.getCurrentUserData();
    } catch (e) {
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  // Sign up
  Future<void> signUp(String email, String password, String name) async {
    try {
      await _authRepository.signUpWithEmail(
        email: email,
        password: password,
        data: {'name': name},
      );
    } catch (e) {
      rethrow;
    }
  }

  // Check if user is authenticated
  bool isAuthenticated() {
    return _authRepository.getCurrentUser() != null;
  }
}

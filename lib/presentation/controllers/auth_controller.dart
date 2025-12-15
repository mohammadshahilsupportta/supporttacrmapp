import 'package:get/get.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../app/routes/app_routes.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/user_model.dart';
import '../../data/models/shop_model.dart';

class AuthController extends GetxController {
  final AuthViewModel _viewModel = AuthViewModel();

  // Observables
  final _isLoading = false.obs;
  final _isAuthenticated = false.obs;
  final _errorMessage = ''.obs;
  final _user = Rxn<UserModel>();
  final _shop = Rxn<ShopModel>();

  // Getters
  bool get isLoading => _isLoading.value;
  bool get isAuthenticated => _isAuthenticated.value;
  String get errorMessage => _errorMessage.value;
  UserModel? get user => _user.value;
  ShopModel? get shop => _shop.value;
  Rxn<ShopModel> get shopRx => _shop;

  @override
  void onInit() {
    super.onInit();
    checkAuthStatus();
  }

  // Check authentication status and load user data
  Future<void> checkAuthStatus() async {
    if (_viewModel.isAuthenticated()) {
      await loadUserData();
    } else {
      _isAuthenticated.value = false;
    }
  }

  // Load user and shop data
  Future<void> loadUserData() async {
    _isLoading.value = true;
    try {
      final data = await _viewModel.getCurrentUserData();
      if (data != null) {
        _user.value = data['user'] as UserModel;
        _shop.value = data['shop'] as ShopModel;
        _isAuthenticated.value = true;
      } else {
        _isAuthenticated.value = false;
      }
    } catch (e) {
      _isAuthenticated.value = false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Sign in
  Future<void> signIn(String email, String password) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      if (!Helpers.isValidEmail(email)) {
        _errorMessage.value = 'Please enter a valid email';
        return;
      }

      final result = await _viewModel.signIn(email, password);

      if (result != null) {
        _user.value = result['user'] as UserModel;
        _shop.value = result['shop'] as ShopModel;
        _isAuthenticated.value = true;
        Get.offAllNamed(AppRoutes.HOME);
      } else {
        _errorMessage.value = 'Sign in failed';
      }
    } catch (e) {
      _errorMessage.value = Helpers.handleError(e);
    } finally {
      _isLoading.value = false;
    }
  }

  // Sign up
  Future<void> signUp(String email, String password, String name) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      if (!Helpers.isValidEmail(email)) {
        _errorMessage.value = 'Please enter a valid email';
        return;
      }

      if (password.length < 6) {
        _errorMessage.value = 'Password must be at least 6 characters';
        return;
      }

      await _viewModel.signUp(email, password, name);
      _errorMessage.value =
          'Registration successful! Please check your email to verify your account.';

      // Navigate back to login after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        Get.offNamed(AppRoutes.LOGIN);
      });
    } catch (e) {
      _errorMessage.value = Helpers.handleError(e);
    } finally {
      _isLoading.value = false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    _isLoading.value = true;
    try {
      await _viewModel.signOut();
      _user.value = null;
      _shop.value = null;
      _isAuthenticated.value = false;
      Get.offAllNamed(AppRoutes.LOGIN);
    } catch (e) {
      _errorMessage.value = Helpers.handleError(e);
    } finally {
      _isLoading.value = false;
    }
  }
}

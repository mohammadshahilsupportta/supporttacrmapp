import 'package:get/get.dart';
import '../../core/services/supabase_service.dart';
import '../../app/routes/app_routes.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _checkAuthAndNavigate();
  }

  void _checkAuthAndNavigate() async {
    // Wait for splash screen animation
    await Future.delayed(const Duration(seconds: 2));

    // Check if user is authenticated
    if (SupabaseService.isAuthenticated) {
      Get.offAllNamed(AppRoutes.HOME);
    } else {
      Get.offAllNamed(AppRoutes.LOGIN);
    }
  }
}



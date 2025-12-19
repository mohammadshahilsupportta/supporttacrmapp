import 'package:get/get.dart';
import '../../presentation/controllers/dashboard_controller.dart';
import '../../presentation/controllers/auth_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure AuthController is registered (should already be from AuthBinding, but ensure it)
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController(), permanent: true);
    }
    // Use put for DashboardController to ensure it's available immediately
    if (!Get.isRegistered<DashboardController>()) {
      Get.put(DashboardController());
    }
  }
}



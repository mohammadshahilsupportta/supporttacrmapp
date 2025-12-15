import 'package:get/get.dart';
import '../../presentation/controllers/dashboard_controller.dart';
import '../../presentation/controllers/auth_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AuthController());
    Get.lazyPut(() => DashboardController());
  }
}



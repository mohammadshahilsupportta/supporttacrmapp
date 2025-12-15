import 'package:get/get.dart';
import '../../presentation/controllers/lead_controller.dart';
import '../../presentation/controllers/auth_controller.dart';

class LeadBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AuthController());
    Get.lazyPut(() => LeadController());
  }
}



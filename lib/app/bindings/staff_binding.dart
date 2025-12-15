import 'package:get/get.dart';
import '../../presentation/controllers/staff_controller.dart';

class StaffBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => StaffController());
  }
}


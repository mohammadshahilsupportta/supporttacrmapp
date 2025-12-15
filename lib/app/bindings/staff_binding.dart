import 'package:get/get.dart';
import '../../presentation/controllers/staff_controller.dart';
import '../../presentation/controllers/category_controller.dart';

class StaffBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => StaffController());
    Get.lazyPut(() => CategoryController());
  }
}


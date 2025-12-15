import 'package:get/get.dart';
import '../../presentation/controllers/category_controller.dart';
import '../../presentation/controllers/auth_controller.dart';

class CategoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AuthController());
    Get.lazyPut(() => CategoryController());
  }
}



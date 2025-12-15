import 'package:get/get.dart';
import '../../presentation/controllers/activity_controller.dart';

class ActivityBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ActivityController());
  }
}


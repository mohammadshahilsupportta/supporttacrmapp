import 'package:get/get.dart';
import '../../presentation/controllers/coordinator_leaderboard_controller.dart';

class CoordinatorLeaderboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CoordinatorLeaderboardController());
  }
}

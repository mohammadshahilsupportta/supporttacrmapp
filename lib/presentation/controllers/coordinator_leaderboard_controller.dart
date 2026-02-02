import 'package:get/get.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';

class CoordinatorLeaderboardController extends GetxController {
  final ReportRepository _repository = ReportRepository();

  final RxList<CoordinatorLeaderboardEntry> _leaderboard = <CoordinatorLeaderboardEntry>[].obs;
  final Rx<CoordinatorLeaderboardPeriod> _period = CoordinatorLeaderboardPeriod.monthly.obs;
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  List<CoordinatorLeaderboardEntry> get leaderboard => _leaderboard;
  CoordinatorLeaderboardPeriod get period => _period.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;

  void setPeriod(CoordinatorLeaderboardPeriod value) {
    _period.value = value;
  }

  /// Load coordinator leaderboard. Only for crm_coordinator.
  Future<void> loadLeaderboard(String shopId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final list = await _repository.getCoordinatorLeaderboard(
        shopId,
        period: _period.value,
      );
      _leaderboard.value = list;
    } catch (e) {
      _errorMessage.value = e.toString();
      _leaderboard.clear();
    } finally {
      _isLoading.value = false;
    }
  }
}

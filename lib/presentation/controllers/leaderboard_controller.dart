import 'package:get/get.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';

class LeaderboardController extends GetxController {
  final ReportRepository _repository = ReportRepository();

  final RxList<LeaderboardEntry> _leaderboard = <LeaderboardEntry>[].obs;
  final Rx<LeaderboardPeriod> _period = LeaderboardPeriod.allTime.obs;
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  List<LeaderboardEntry> get leaderboard => _leaderboard;
  LeaderboardPeriod get period => _period.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;

  void setPeriod(LeaderboardPeriod value) {
    _period.value = value;
  }

  /// Load conversion leaderboard (Closed Won). Visible to all roles.
  Future<void> loadLeaderboard(String shopId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final list = await _repository.getConversionLeaderboard(
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

  Future<void> refreshLeaderboard(String shopId) async {
    await loadLeaderboard(shopId);
  }
}

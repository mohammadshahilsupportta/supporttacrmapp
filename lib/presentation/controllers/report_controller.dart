import 'package:get/get.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';

class ReportController extends GetxController {
  final ReportRepository _repository = ReportRepository();

  final RxList<StaffPerformanceStats> _stats = <StaffPerformanceStats>[].obs;
  final Rxn<ReportSummary> _summary = Rxn<ReportSummary>();
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  List<StaffPerformanceStats> get stats => _stats;
  ReportSummary? get summary => _summary.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;

  /// Load staff performance statistics
  Future<void> loadStats(String shopId, {StaffPerformanceFilters? filters}) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final stats = await _repository.getStaffPerformanceStats(shopId, filters: filters);
      _stats.value = stats;

      // Also load summary
      final summary = await _repository.getReportSummary(shopId);
      _summary.value = summary;
    } catch (e) {
      _errorMessage.value = e.toString();
      _stats.clear();
      _summary.value = null;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Refresh stats
  Future<void> refreshStats(String shopId, {StaffPerformanceFilters? filters}) async {
    await loadStats(shopId, filters: filters);
  }
}


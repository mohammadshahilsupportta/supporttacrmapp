import 'package:get/get.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../viewmodels/staff_viewmodel.dart';
import '../../data/models/lead_model.dart';
import '../../data/models/user_model.dart';
import '../../data/models/report_model.dart';
import '../../data/repositories/report_repository.dart';
import '../../core/utils/helpers.dart';
import 'auth_controller.dart';

class DashboardController extends GetxController {
  final DashboardViewModel _viewModel = DashboardViewModel();
  final StaffViewModel _staffViewModel = StaffViewModel();
  final ReportRepository _reportRepository = ReportRepository();

  // Observables
  final _stats = Rxn<LeadStats>();
  final _coordinatorStats = Rxn<CoordinatorStats>();
  final _activeStaffCount = 0.obs;
  final _isLoading = false.obs;
  final _errorMessage = ''.obs;

  // Getters
  LeadStats? get stats => _stats.value;
  CoordinatorStats? get coordinatorStats => _coordinatorStats.value;
  int get activeStaffCount => _activeStaffCount.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;

  // Calculate conversion rate (proposal_sent is primary, closed_won fallback)
  double get conversionRate {
    if (_stats.value == null || _stats.value!.total == 0) return 0.0;
    final proposalSent = _stats.value!.byStatus[LeadStatus.proposalSent] ?? 0;
    final closedWon = _stats.value!.byStatus[LeadStatus.closedWon] ?? 0;
    final conversionCount = proposalSent > 0 ? proposalSent : closedWon;
    return (conversionCount / _stats.value!.total * 100);
  }

  @override
  void onInit() {
    super.onInit();
    // Don't load stats here - wait for shop to be available
  }

  // Load dashboard statistics
  Future<void> loadStats() async {
    try {
      final authController = Get.find<AuthController>();
      final shop = authController.shop;

      if (shop == null) {
        // Wait a bit and try again if shop is not available
        await Future.delayed(const Duration(milliseconds: 500));
        final retryShop = authController.shop;
        if (retryShop == null) {
          _errorMessage.value = 'Shop information not available';
          return;
        }
        // Use retryShop instead
        await _loadStatsForShop(retryShop.id);
        return;
      }

      await _loadStatsForShop(shop.id);
    } catch (e) {
      _errorMessage.value = Helpers.handleError(e);
      _isLoading.value = false;
    }
  }

  Future<void> _loadStatsForShop(String shopId) async {
    _isLoading.value = true;
    _errorMessage.value = '';
    _coordinatorStats.value = null;

    try {
      final authController = Get.find<AuthController>();
      final user = authController.user;

      // Coordinator: load coordinator stats only (goals, points, star points)
      if (user != null && user.role == UserRole.crmCoordinator) {
        final coordinatorStats = await _reportRepository.getCoordinatorStats(shopId, user.id);
        _coordinatorStats.value = coordinatorStats;
        _stats.value = null;
        _activeStaffCount.value = 0;
        return;
      }

      // Determine if user is staff role (not shopOwner or admin)
      final isStaffRole = user != null &&
          user.role != UserRole.shopOwner &&
          user.role != UserRole.admin;

      // For staff roles, pass userId to filter their own leads (user is non-null when isStaffRole)
      final userId = isStaffRole ? user.id : null;

      // Load lead stats with optional user filter
      final result = await _viewModel.getLeadStats(shopId, userId: userId);
      _stats.value = result;

      // Load active staff count (only for admin/owner)
      if (!isStaffRole) {
        final staffList = await _staffViewModel.getStaff(shopId);
        _activeStaffCount.value = staffList.where((s) => s.isActive).length;
      } else {
        _activeStaffCount.value = 0;
      }
    } catch (e) {
      _errorMessage.value = Helpers.handleError(e);
    } finally {
      _isLoading.value = false;
    }
  }
}



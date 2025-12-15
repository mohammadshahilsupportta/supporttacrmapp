import 'package:get/get.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../viewmodels/staff_viewmodel.dart';
import '../../data/models/lead_model.dart';
import '../../core/utils/helpers.dart';
import 'auth_controller.dart';

class DashboardController extends GetxController {
  final DashboardViewModel _viewModel = DashboardViewModel();
  final StaffViewModel _staffViewModel = StaffViewModel();

  // Observables
  final _stats = Rxn<LeadStats>();
  final _activeStaffCount = 0.obs;
  final _isLoading = false.obs;
  final _errorMessage = ''.obs;

  // Getters
  LeadStats? get stats => _stats.value;
  int get activeStaffCount => _activeStaffCount.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;

  // Calculate conversion rate
  double get conversionRate {
    if (_stats.value == null || _stats.value!.total == 0) return 0.0;
    final converted = _stats.value!.byStatus[LeadStatus.converted] ?? 0;
    return (converted / _stats.value!.total * 100);
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

    try {
      // Load lead stats
      final result = await _viewModel.getLeadStats(shopId);
      _stats.value = result;

      // Load active staff count
      final staffList = await _staffViewModel.getStaff(shopId);
      _activeStaffCount.value = staffList.where((s) => s.isActive).length;
    } catch (e) {
      _errorMessage.value = Helpers.handleError(e);
    } finally {
      _isLoading.value = false;
    }
  }
}



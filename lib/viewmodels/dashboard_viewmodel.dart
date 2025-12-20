import '../data/repositories/lead_repository.dart';
import '../data/models/lead_model.dart' show LeadStats;

class DashboardViewModel {
  final LeadRepository _leadRepository = LeadRepository();

  // Get dashboard statistics
  Future<LeadStats> getLeadStats(String shopId, {String? userId}) async {
    return await _leadRepository.getStats(shopId, userId: userId);
  }
}

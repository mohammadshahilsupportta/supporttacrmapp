import '../data/repositories/lead_repository.dart';
import '../data/models/lead_model.dart'
    show
        LeadStats,
        LeadWithRelationsModel,
        LeadFilters,
        CreateLeadInput,
        LeadModel;

class LeadViewModel {
  final LeadRepository _repository = LeadRepository();

  // Get all leads. [visibility] applies website rules for staff (freelance/office_staff/coordinator).
  Future<List<LeadWithRelationsModel>> getLeads(
    String shopId, {
    LeadFilters? filters,
    LeadVisibilityContext? visibility,
  }) async {
    return await _repository.findAll(shopId, filters: filters, visibility: visibility);
  }

  // Get lead by ID. [visibility] enforces website rules for staff.
  Future<LeadWithRelationsModel?> getLeadById(
    String leadId, {
    LeadVisibilityContext? visibility,
  }) async {
    return await _repository.findById(leadId, visibility: visibility);
  }

  // Create lead
  Future<LeadModel> createLead(
    String shopId,
    CreateLeadInput input,
    String userId,
  ) async {
    return await _repository.create(shopId, input, userId);
  }

  // Update lead. [performer] for visibility and business rules (coordinator no self-assign, closed_won change).
  Future<LeadModel> updateLead(
    String leadId,
    CreateLeadInput input, {
    LeadVisibilityContext? performer,
  }) async {
    return await _repository.update(leadId, input, performer: performer);
  }

  // Delete lead. [currentUserId] and [isOwnerOrAdmin] for permission check (match website).
  Future<void> deleteLead(
    String leadId, {
    String? currentUserId,
    bool isOwnerOrAdmin = false,
  }) async {
    await _repository.delete(
      leadId,
      currentUserId: currentUserId,
      isOwnerOrAdmin: isOwnerOrAdmin,
    );
  }

  // Get lead statistics
  Future<LeadStats> getStats(String shopId) async {
    return await _repository.getStats(shopId);
  }

  // Get unique location values for filter dropdowns (country/state/city/district)
  Future<List<String>> getLocationValues(
    String shopId, {
    required String type,
    String? country,
    String? state,
    String? city,
  }) async {
    return await _repository.getLocationValues(
      shopId,
      type: type,
      country: country,
      state: state,
      city: city,
    );
  }
}

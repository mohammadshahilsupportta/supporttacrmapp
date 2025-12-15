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

  // Get all leads
  Future<List<LeadWithRelationsModel>> getLeads(
    String shopId, {
    LeadFilters? filters,
  }) async {
    return await _repository.findAll(shopId, filters: filters);
  }

  // Get lead by ID
  Future<LeadWithRelationsModel?> getLeadById(String leadId) async {
    return await _repository.findById(leadId);
  }

  // Create lead
  Future<LeadModel> createLead(
    String shopId,
    CreateLeadInput input,
    String userId,
  ) async {
    return await _repository.create(shopId, input, userId);
  }

  // Update lead
  Future<LeadModel> updateLead(String leadId, CreateLeadInput input) async {
    return await _repository.update(leadId, input);
  }

  // Delete lead
  Future<void> deleteLead(String leadId) async {
    await _repository.delete(leadId);
  }

  // Get lead statistics
  Future<LeadStats> getStats(String shopId) async {
    return await _repository.getStats(shopId);
  }
}

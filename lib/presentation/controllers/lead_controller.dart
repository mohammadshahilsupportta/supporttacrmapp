import 'package:get/get.dart';
import '../../viewmodels/lead_viewmodel.dart';
import '../../data/models/lead_model.dart';
import '../../core/utils/helpers.dart';

class LeadController extends GetxController {
  final LeadViewModel _viewModel = LeadViewModel();

  // Observables
  final _leads = <LeadWithRelationsModel>[].obs;
  final _isLoading = false.obs;
  final _errorMessage = ''.obs;
  final _selectedLead = Rxn<LeadWithRelationsModel>();
  final _filters = Rxn<LeadFilters>();
  final _stats = Rxn<LeadStats>();

  // Getters
  List<LeadWithRelationsModel> get leads => _leads;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  LeadWithRelationsModel? get selectedLead => _selectedLead.value;
  LeadFilters? get filters => _filters.value;
  LeadStats? get stats => _stats.value;

  // Set filters
  void setFilters(LeadFilters? filters) {
    _filters.value = filters;
  }

  // Load leads
  Future<void> loadLeads(String shopId) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final result = await _viewModel.getLeads(shopId, filters: _filters.value);
      // Apply client-side sorting if specified
      var sortedLeads = List<LeadWithRelationsModel>.from(result);
      if (_filters.value?.sortBy != null) {
        sortedLeads = _sortLeads(sortedLeads, _filters.value!.sortBy!, _filters.value!.sortOrder ?? LeadSortOrder.desc);
      }
      _leads.value = sortedLeads;
    } catch (e) {
      _errorMessage.value = Helpers.handleError(e);
    } finally {
      _isLoading.value = false;
    }
  }

  // Sort leads client-side
  List<LeadWithRelationsModel> _sortLeads(
    List<LeadWithRelationsModel> leads,
    LeadSortBy sortBy,
    LeadSortOrder order,
  ) {
    final sorted = List<LeadWithRelationsModel>.from(leads);
    sorted.sort((a, b) {
      int comparison = 0;
      switch (sortBy) {
        case LeadSortBy.name:
          comparison = a.name.compareTo(b.name);
          break;
        case LeadSortBy.createdAt:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case LeadSortBy.updatedAt:
          comparison = a.updatedAt.compareTo(b.updatedAt);
          break;
        case LeadSortBy.score:
          final scoreA = a.score ?? 0;
          final scoreB = b.score ?? 0;
          comparison = scoreA.compareTo(scoreB);
          break;
        case LeadSortBy.status:
          comparison = a.status.index.compareTo(b.status.index);
          break;
      }
      return order == LeadSortOrder.asc ? comparison : -comparison;
    });
    return sorted;
  }

  // Load lead by ID
  Future<void> loadLeadById(String leadId) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final result = await _viewModel.getLeadById(leadId);
      _selectedLead.value = result;
    } catch (e) {
      _errorMessage.value = Helpers.handleError(e);
    } finally {
      _isLoading.value = false;
    }
  }

  // Create lead
  Future<bool> createLead(
    String shopId,
    CreateLeadInput input,
    String userId,
  ) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      await _viewModel.createLead(shopId, input, userId);
      await loadLeads(shopId);
      return true;
    } catch (e) {
      _errorMessage.value = Helpers.handleError(e);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Update lead
  Future<bool> updateLead(String leadId, CreateLeadInput input) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      await _viewModel.updateLead(leadId, input);
      await loadLeadById(leadId);
      return true;
    } catch (e) {
      _errorMessage.value = Helpers.handleError(e);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Delete lead
  Future<bool> deleteLead(String leadId, String shopId) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      await _viewModel.deleteLead(leadId);
      await loadLeads(shopId);
      return true;
    } catch (e) {
      _errorMessage.value = Helpers.handleError(e);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Load statistics
  Future<void> loadStats(String shopId) async {
    try {
      final result = await _viewModel.getStats(shopId);
      _stats.value = result;
    } catch (e) {
      _errorMessage.value = Helpers.handleError(e);
    }
  }
}



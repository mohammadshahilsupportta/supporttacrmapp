import 'package:get/get.dart';
import '../../viewmodels/lead_viewmodel.dart';
import '../../data/models/lead_model.dart';
import '../../core/utils/helpers.dart';

class LeadController extends GetxController {
  final LeadViewModel _viewModel = LeadViewModel();

  // Observables
  final _leads = <LeadWithRelationsModel>[].obs;
  final _isLoading = false.obs;
  final _isLoadingMore = false.obs;
  final _errorMessage = ''.obs;
  final _selectedLead = Rxn<LeadWithRelationsModel>();
  final _filters = Rxn<LeadFilters>();
  final _stats = Rxn<LeadStats>();
  final _hasMore = true.obs;
  final _currentOffset = 0.obs;
  static const int _pageSize = 20;

  // Getters
  List<LeadWithRelationsModel> get leads => _leads;
  bool get isLoading => _isLoading.value;
  bool get isLoadingMore => _isLoadingMore.value;
  bool get hasMore => _hasMore.value;
  String get errorMessage => _errorMessage.value;
  LeadWithRelationsModel? get selectedLead => _selectedLead.value;
  LeadFilters? get filters => _filters.value;
  LeadStats? get stats => _stats.value;

  // Set filters (resets pagination)
  void setFilters(LeadFilters? filters) {
    _filters.value = filters;
    _currentOffset.value = 0;
    _hasMore.value = true;
    _leads.clear();
  }

  // Load leads (initial load or refresh)
  Future<void> loadLeads(String shopId, {bool reset = true, bool silent = false}) async {
    if (reset) {
      _currentOffset.value = 0;
      _hasMore.value = true;
      _leads.clear();
    }
    
    if (!silent) {
      _isLoading.value = true;
    }
    _errorMessage.value = '';

    try {
      final filtersWithPagination = LeadFilters(
        status: _filters.value?.status,
        categoryIds: _filters.value?.categoryIds,
        assignedTo: _filters.value?.assignedTo,
        createdBy: _filters.value?.createdBy,
        source: _filters.value?.source,
        search: _filters.value?.search,
        dateFrom: _filters.value?.dateFrom,
        dateTo: _filters.value?.dateTo,
        scoreCategories: _filters.value?.scoreCategories,
        sortBy: _filters.value?.sortBy,
        sortOrder: _filters.value?.sortOrder,
        limit: _pageSize,
        offset: _currentOffset.value,
      );

      final result = await _viewModel.getLeads(shopId, filters: filtersWithPagination);
      
      if (reset) {
        _leads.value = result;
      } else {
        _leads.addAll(result);
      }
      
      // Check if there are more results
      _hasMore.value = result.length >= _pageSize;
      _currentOffset.value = _leads.length;
    } catch (e) {
      _errorMessage.value = Helpers.handleError(e);
    } finally {
      if (!silent) {
        _isLoading.value = false;
      }
    }
  }

  // Load more leads (pagination)
  Future<void> loadMoreLeads(String shopId) async {
    if (_isLoadingMore.value || !_hasMore.value) return;

    _isLoadingMore.value = true;
    _errorMessage.value = '';

    try {
      final filtersWithPagination = LeadFilters(
        status: _filters.value?.status,
        categoryIds: _filters.value?.categoryIds,
        assignedTo: _filters.value?.assignedTo,
        createdBy: _filters.value?.createdBy,
        source: _filters.value?.source,
        search: _filters.value?.search,
        dateFrom: _filters.value?.dateFrom,
        dateTo: _filters.value?.dateTo,
        scoreCategories: _filters.value?.scoreCategories,
        sortBy: _filters.value?.sortBy,
        sortOrder: _filters.value?.sortOrder,
        limit: _pageSize,
        offset: _currentOffset.value,
      );

      final result = await _viewModel.getLeads(shopId, filters: filtersWithPagination);
      
      if (result.isEmpty) {
        _hasMore.value = false;
      } else {
        _leads.addAll(result);
        _currentOffset.value = _leads.length;
        _hasMore.value = result.length >= _pageSize;
      }
    } catch (e) {
      _errorMessage.value = Helpers.handleError(e);
    } finally {
      _isLoadingMore.value = false;
    }
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
      final updatedLead = await _viewModel.getLeadById(leadId);
      if (updatedLead != null) {
        _selectedLead.value = updatedLead;
        
        // Update the lead in the leads list if it exists
        final index = _leads.indexWhere((lead) => lead.id == leadId);
        if (index != -1) {
          _leads[index] = updatedLead;
        }
      }
      
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



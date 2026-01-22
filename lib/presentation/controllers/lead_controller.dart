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
  final _isFiltering = false.obs; // Track when filtering is happening
  final _errorMessage = ''.obs;
  final _selectedLead = Rxn<LeadWithRelationsModel>();
  final _filters = Rxn<LeadFilters>();
  final _stats = Rxn<LeadStats>();
  final _hasMore = true.obs;
  final _currentOffset = 0.obs;
  static const int _pageSize = 20;

  // Location dropdown values (fetched distinct from DB, like website)
  final _countries = <String>[].obs;
  final _states = <String>[].obs;
  final _cities = <String>[].obs;
  final _districts = <String>[].obs;
  final _isLoadingLocations = false.obs;

  // Getters
  List<LeadWithRelationsModel> get leads => _leads;
  bool get isLoading => _isLoading.value;
  bool get isLoadingMore => _isLoadingMore.value;
  bool get isFiltering => _isFiltering.value; // Getter for filtering state
  bool get hasMore => _hasMore.value;
  String get errorMessage => _errorMessage.value;
  LeadWithRelationsModel? get selectedLead => _selectedLead.value;
  LeadFilters? get filters => _filters.value;
  LeadStats? get stats => _stats.value;
  List<String> get countries => _countries;
  List<String> get states => _states;
  List<String> get cities => _cities;
  List<String> get districts => _districts;
  bool get isLoadingLocations => _isLoadingLocations.value;

  // Set filters (resets pagination)
  void setFilters(LeadFilters? filters) {
    print('🔍 [CONTROLLER] setFilters called:');
    print('  - Filters: $filters');
    print('  - Country: ${filters?.country}');
    print('  - State: ${filters?.state}');
    print('  - City: ${filters?.city}');
    print('  - District: ${filters?.district}');
    _filters.value = filters;
    _currentOffset.value = 0;
    _hasMore.value = true;
    _leads.clear();
  }

  // Load leads (initial load or refresh)
  Future<void> loadLeads(String shopId, {bool reset = true, bool silent = false}) async {
    // Set filtering state FIRST (before clearing) to ensure shimmer shows immediately
    if (!silent) {
      _isLoading.value = true;
    } else {
      // Show shimmer when filtering (silent mode)
      _isFiltering.value = true;
    }
    
    if (reset) {
      _currentOffset.value = 0;
      _hasMore.value = true;
      _leads.clear(); // Clear leads after setting isFiltering
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
        country: _filters.value?.country,
        state: _filters.value?.state,
        city: _filters.value?.city,
        district: _filters.value?.district,
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
      } else {
        _isFiltering.value = false;
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
        country: _filters.value?.country,
        state: _filters.value?.state,
        city: _filters.value?.city,
        district: _filters.value?.district,
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

  // Load distinct location values (like website)
  Future<void> loadCountries(String shopId) async {
    _isLoadingLocations.value = true;
    try {
      final result = await _viewModel.getLocationValues(shopId, type: 'country');
      _countries.assignAll(result);
    } finally {
      _isLoadingLocations.value = false;
    }
  }

  Future<void> loadStates(String shopId, {required String country}) async {
    _isLoadingLocations.value = true;
    try {
      final result = await _viewModel.getLocationValues(
        shopId,
        type: 'state',
        country: country,
      );
      _states.assignAll(result);
    } finally {
      _isLoadingLocations.value = false;
    }
  }

  Future<void> loadCities(String shopId, {required String country, required String state}) async {
    _isLoadingLocations.value = true;
    try {
      final result = await _viewModel.getLocationValues(
        shopId,
        type: 'city',
        country: country,
        state: state,
      );
      _cities.assignAll(result);
    } finally {
      _isLoadingLocations.value = false;
    }
  }

  Future<void> loadDistricts(String shopId, {required String country, required String state, required String city}) async {
    _isLoadingLocations.value = true;
    try {
      final result = await _viewModel.getLocationValues(
        shopId,
        type: 'district',
        country: country,
        state: state,
        city: city,
      );
      _districts.assignAll(result);
    } finally {
      _isLoadingLocations.value = false;
    }
  }

  void clearLocationOptionsBelowCountry() {
    _states.clear();
    _cities.clear();
    _districts.clear();
  }

  void clearLocationOptionsBelowState() {
    _cities.clear();
    _districts.clear();
  }

  void clearLocationOptionsBelowCity() {
    _districts.clear();
  }
}



import '../../core/services/supabase_service.dart';
import '../models/lead_model.dart';

class LeadRepositoryHelper {
  // Helper method to build query with filters
  static dynamic buildFilteredQuery(
    String shopId,
    LeadFilters? filters,
    String selectQuery,
  ) {
    var query = SupabaseService.from('leads')
        .select(selectQuery)
        .eq('shop_id', shopId)
        .isFilter('deleted_at', null);

    if (filters != null) {
      // Filter by status
      if (filters.status != null && filters.status!.isNotEmpty) {
        final statusStrings = filters.status!
            .map((s) {
              // Convert enum to database format: newLead -> 'new', contacted -> 'contacted', etc.
              switch (s) {
                case LeadStatus.newLead:
                  return 'new';
                case LeadStatus.contacted:
                  return 'contacted';
                case LeadStatus.qualified:
                  return 'qualified';
                case LeadStatus.converted:
                  return 'converted';
                case LeadStatus.lost:
                  return 'lost';
              }
            })
            .toList();
        query = query.inFilter('status', statusStrings);
      }

      // Filter by source
      if (filters.source != null) {
        // Convert enum to database format
        String sourceString;
        switch (filters.source!) {
          case LeadSource.website:
            sourceString = 'website';
            break;
          case LeadSource.phone:
            sourceString = 'phone';
            break;
          case LeadSource.walkIn:
            sourceString = 'walk-in';
            break;
          case LeadSource.referral:
            sourceString = 'referral';
            break;
          case LeadSource.socialMedia:
            sourceString = 'social-media';
            break;
          case LeadSource.email:
            sourceString = 'email';
            break;
          case LeadSource.other:
            sourceString = 'other';
            break;
        }
        query = query.eq('source', sourceString);
      }

      // Filter by assigned to
      if (filters.assignedTo != null) {
        query = query.eq('assigned_to', filters.assignedTo!);
      }

      // Filter by search
      if (filters.search != null && filters.search!.isNotEmpty) {
        final searchTerm = '%${filters.search!.trim()}%';
        query = query.or(
          'name.ilike.$searchTerm,email.ilike.$searchTerm,phone.ilike.$searchTerm,company.ilike.$searchTerm',
        );
      }

      // Filter by date range
      if (filters.dateFrom != null) {
        query = query.gte('created_at', filters.dateFrom!.toIso8601String());
      }
      if (filters.dateTo != null) {
        query = query.lte('created_at', filters.dateTo!.toIso8601String());
      }

      // Filter by score category
      if (filters.scoreCategories != null && filters.scoreCategories!.isNotEmpty) {
        if (filters.scoreCategories!.contains('unscored')) {
          query = query.isFilter('score_category', null);
        } else {
          final categories = filters.scoreCategories!
              .map((c) => c.toLowerCase())
              .toList();
          query = query.inFilter('score_category', categories);
        }
      }
    }

    return query;
  }

  // Helper method to apply sorting and pagination
  static dynamic applySortingAndPagination(
    dynamic query,
    LeadFilters? filters,
  ) {
    // Apply sorting
    String orderColumn = 'created_at';
    bool ascending = false;
    if (filters?.sortBy != null) {
      switch (filters!.sortBy!) {
        case LeadSortBy.name:
          orderColumn = 'name';
          break;
        case LeadSortBy.createdAt:
          orderColumn = 'created_at';
          break;
        case LeadSortBy.updatedAt:
          orderColumn = 'updated_at';
          break;
        case LeadSortBy.score:
          orderColumn = 'score';
          break;
        case LeadSortBy.status:
          orderColumn = 'status';
          break;
      }
      ascending = filters.sortOrder == LeadSortOrder.asc;
    }
    var orderedQuery = query.order(orderColumn, ascending: ascending);

    // Apply pagination
    final limit = filters?.limit ?? 20;
    final offset = filters?.offset ?? 0;
    return orderedQuery.range(offset, offset + limit - 1);
  }
}




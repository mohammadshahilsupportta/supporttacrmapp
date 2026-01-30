import 'package:flutter/foundation.dart';
import '../models/lead_model.dart';
import '../models/category_model.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/helpers.dart';
import 'lead_repository_helper.dart';

class LeadRepository {
  // Get unique location values (country, state, city, district) for dropdown filters
  // Mirrors the website logic (distinct values from DB with cascading filters).
  Future<List<String>> getLocationValues(
    String shopId, {
    required String type, // 'country' | 'state' | 'city' | 'district'
    String? country,
    String? state,
    String? city,
  }) async {
    try {
      if (!<String>['country', 'state', 'city', 'district'].contains(type)) {
        throw Exception('Invalid location type: $type');
      }

      dynamic query = SupabaseService.from('leads')
          .select(type)
          .eq('shop_id', shopId)
          .isFilter('deleted_at', null)
          .not(type, 'is', null);

      // Cascading filters (use ilike for case-insensitive partial matching like website filtering)
      // This ensures normalized values from UI can match database values with different formatting
      if (type == 'state' && country != null && country.trim().isNotEmpty) {
        query = query.ilike('country', '%${country.trim()}%');
      }
      if (type == 'city' && state != null && state.trim().isNotEmpty) {
        query = query.ilike('state', '%${state.trim()}%');
        if (country != null && country.trim().isNotEmpty) {
          query = query.ilike('country', '%${country.trim()}%');
        }
      }
      if (type == 'district' && city != null && city.trim().isNotEmpty) {
        query = query.ilike('city', '%${city.trim()}%');
        if (state != null && state.trim().isNotEmpty) {
          query = query.ilike('state', '%${state.trim()}%');
        }
        if (country != null && country.trim().isNotEmpty) {
          query = query.ilike('country', '%${country.trim()}%');
        }
      }

      query = query.order(type, ascending: true);
      final data = await query as List<dynamic>? ?? [];

      final set = <String>{};
      for (final row in data) {
        final map = row as Map<String, dynamic>;
        final v = map[type];
        if (v is String) {
          final trimmed = v.trim();
          if (trimmed.isNotEmpty) set.add(trimmed);
        }
      }
      final result = set.toList()..sort();
      return result;
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }

  // Get all leads with filters (server-side filtering and pagination)
  Future<List<LeadWithRelationsModel>> findAll(
    String shopId, {
    LeadFilters? filters,
  }) async {
    try {
      // DEBUG: Print filters received in repository
      debugPrint('🔍 [REPOSITORY] findAll called with filters:');
      debugPrint('  - Country: ${filters?.country}');
      debugPrint('  - State: ${filters?.state}');
      debugPrint('  - City: ${filters?.city}');
      debugPrint('  - District: ${filters?.district}');
      debugPrint('  - AssignedTo: ${filters?.assignedTo}');
      debugPrint('  - Status: ${filters?.status}');
      debugPrint('  - Source: ${filters?.source}');
      debugPrint('  - Filters is null: ${filters == null}');

      // Build query with server-side filters
      // Note: Don't join assigned_user or created_by_user here because they can reference either users or staff table
      // We'll fetch user data separately after getting leads (like website does)
      var queryBuilder = SupabaseService.from('leads')
          .select('''
            *,
            lead_categories(
              category:categories(*)
            )
          ''')
          .eq('shop_id', shopId)
          .isFilter('deleted_at', null);

      // Apply server-side filters
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
          queryBuilder = queryBuilder.inFilter('status', statusStrings);
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
          queryBuilder = queryBuilder.eq('source', sourceString);
        }

        // Filter by assigned to
        if (filters.assignedTo != null) {
          queryBuilder = queryBuilder.eq('assigned_to', filters.assignedTo!);
        }

        // Filter by created by
        if (filters.createdBy != null) {
          queryBuilder = queryBuilder.eq('created_by', filters.createdBy!);
        }

        // Filter by search (name, email, phone, company)
        if (filters.search != null && filters.search!.isNotEmpty) {
          final searchTerm = '%${filters.search!.trim()}%';
          // Use or() with proper syntax for multiple field search
          // Format: field1.operator.value,field2.operator.value
          queryBuilder = queryBuilder.or(
            'name.ilike.$searchTerm,email.ilike.$searchTerm,phone.ilike.$searchTerm,company.ilike.$searchTerm',
          );
        }

        // Filter by date range
        if (filters.dateFrom != null) {
          queryBuilder = queryBuilder.gte('created_at', filters.dateFrom!.toIso8601String());
        }
        if (filters.dateTo != null) {
          queryBuilder = queryBuilder.lte('created_at', filters.dateTo!.toIso8601String());
        }

        // Filter by score category
        if (filters.scoreCategories != null && filters.scoreCategories!.isNotEmpty) {
          if (filters.scoreCategories!.contains('unscored')) {
            queryBuilder = queryBuilder.isFilter('score_category', null);
          } else {
            final categories = filters.scoreCategories!
                .map((c) => c.toLowerCase())
                .toList();
            queryBuilder = queryBuilder.inFilter('score_category', categories);
          }
        }

        // Filter by location (using ilike for partial matching like website)
        if (filters.country != null && filters.country!.isNotEmpty) {
          final countryTerm = '%${filters.country!.trim()}%';
          debugPrint('🔍 [REPOSITORY] Applying country filter: $countryTerm');
          queryBuilder = queryBuilder.ilike('country', countryTerm);
        } else {
          debugPrint('🔍 [REPOSITORY] Country filter NOT applied (null or empty)');
        }
        if (filters.state != null && filters.state!.isNotEmpty) {
          final stateTerm = '%${filters.state!.trim()}%';
          debugPrint('🔍 [REPOSITORY] Applying state filter: $stateTerm');
          queryBuilder = queryBuilder.ilike('state', stateTerm);
        } else {
          debugPrint('🔍 [REPOSITORY] State filter NOT applied (null or empty)');
        }
        if (filters.city != null && filters.city!.isNotEmpty) {
          final cityTerm = '%${filters.city!.trim()}%';
          debugPrint('🔍 [REPOSITORY] Applying city filter: $cityTerm');
          queryBuilder = queryBuilder.ilike('city', cityTerm);
        } else {
          debugPrint('🔍 [REPOSITORY] City filter NOT applied (null or empty)');
        }
        if (filters.district != null && filters.district!.isNotEmpty) {
          final districtTerm = '%${filters.district!.trim()}%';
          debugPrint('🔍 [REPOSITORY] Applying district filter: $districtTerm');
          queryBuilder = queryBuilder.ilike('district', districtTerm);
        } else {
          debugPrint('🔍 [REPOSITORY] District filter NOT applied (null or empty)');
        }
      } else {
        debugPrint('🔍 [REPOSITORY] No filters provided (filters is null)');
      }

      // Apply sorting (must be after filters, before pagination)
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
      var orderedQuery = queryBuilder.order(orderColumn, ascending: ascending);

      // Apply pagination
      final limit = filters?.limit ?? 20;
      final offset = filters?.offset ?? 0;
      var paginatedQuery = orderedQuery.range(offset, offset + limit - 1);

      // Execute query (like website: don't join assigned_user, fetch separately)
      List<dynamic> data;
      try {
        debugPrint('🔍 [REPOSITORY] Executing query...');
        data = await paginatedQuery as List<dynamic>? ?? [];
        debugPrint('🔍 [REPOSITORY] Query executed successfully. Results: ${data.length} leads');
      } catch (e) {
        debugPrint('🔍 [REPOSITORY] Query execution error: $e');
        // Fallback: query without user relationships, but still apply filters
        var finalQuery = LeadRepositoryHelper.buildFilteredQuery(
          shopId,
          filters,
          '''
            *,
            lead_categories(
              category:categories(*)
            )
          ''',
        );
        finalQuery = LeadRepositoryHelper.applySortingAndPagination(finalQuery, filters);
        data = await finalQuery as List<dynamic>? ?? [];
      }
      
      // PARALLEL: Resolve assigned_user for all leads simultaneously (like website)
      // This is more efficient than sequential lookups
      final assignedToIds = data
          .map((l) => (l as Map<String, dynamic>)['assigned_to'] as String?)
          .whereType<String>()
          .toSet()
          .toList();
      final createdByIds = data
          .map((l) => (l as Map<String, dynamic>)['created_by'] as String?)
          .whereType<String>()
          .toSet()
          .toList();
      
      // Fetch all users and staff in parallel (like website)
      Map<String, Map<String, dynamic>> assignedUsersMap = {};
      Map<String, Map<String, dynamic>> createdByUsersMap = {};
      
      if (assignedToIds.isNotEmpty) {
        try {
          // Try fetching from both tables in parallel
          final staffResults = await SupabaseService.from('staff')
              .select('id, name, email')
              .inFilter('id', assignedToIds) as List<dynamic>? ?? [];
          
          final usersResults = await SupabaseService.from('users')
              .select('id, name, email')
              .inFilter('id', assignedToIds) as List<dynamic>? ?? [];
          
          // Create lookup maps (prefer staff over users if both exist)
          for (final user in staffResults) {
            final userMap = user as Map<String, dynamic>;
            assignedUsersMap[userMap['id'] as String] = userMap;
          }
          for (final user in usersResults) {
            final userMap = user as Map<String, dynamic>;
            final userId = userMap['id'] as String;
            // Only add if not already in map (staff takes precedence)
            if (!assignedUsersMap.containsKey(userId)) {
              assignedUsersMap[userId] = userMap;
            }
          }
        } catch (e) {
          debugPrint('🔍 [REPOSITORY] Error fetching assigned users: $e');
        }
      }
      
      // Fetch created by users
      if (createdByIds.isNotEmpty) {
        try {
          final usersResults = await SupabaseService.from('users')
              .select('id, name')
              .inFilter('id', createdByIds) as List<dynamic>? ?? [];
          
          for (final user in usersResults) {
            final userMap = user as Map<String, dynamic>;
            createdByUsersMap[userMap['id'] as String] = userMap;
          }
        } catch (e) {
          debugPrint('🔍 [REPOSITORY] Error fetching created_by users: $e');
        }
      }
      
      // Merge user data into leads (like website)
      for (var lead in data) {
        final leadMap = lead as Map<String, dynamic>;
        final assignedTo = leadMap['assigned_to'] as String?;
        final createdBy = leadMap['created_by'] as String?;
        
        if (assignedTo != null && assignedUsersMap.containsKey(assignedTo)) {
          leadMap['assigned_user'] = assignedUsersMap[assignedTo];
        }
        if (createdBy != null && createdByUsersMap.containsKey(createdBy)) {
          leadMap['created_by_user'] = createdByUsersMap[createdBy];
        }
      }

      // Transform the nested structure
      List<LeadWithRelationsModel> leads = data.map((leadJson) {
        final lead = leadJson as Map<String, dynamic>;
        final categories =
            (lead['lead_categories'] as List<dynamic>?)
                ?.map((lc) {
                  final lcMap = lc as Map<String, dynamic>;
                  final cat = lcMap['category'] as Map<String, dynamic>?;
                  return cat != null ? CategoryModel.fromJson(cat) : null;
                })
                .whereType<CategoryModel>()
                .toList() ??
            [];

        return LeadWithRelationsModel.fromJson({
          ...lead,
          'categories': categories.map((c) => c.toJson()).toList(),
        });
      }).toList();

      // Filter by categories server-side (if categoryIds filter is provided)
      // Note: This requires a join, so we filter client-side after fetching
      if (filters != null && filters.categoryIds != null && filters.categoryIds!.isNotEmpty) {
        leads = leads.where((lead) {
          return lead.categories.any(
            (cat) => filters.categoryIds!.contains(cat.id),
          );
        }).toList();
      }

      return leads;
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }

  // Get lead by ID
  Future<LeadWithRelationsModel?> findById(String leadId) async {
    try {
      Map<String, dynamic>? lead;
      try {
        // First try: Join with staff table
        lead = await SupabaseService.from('leads')
            .select('''
              *,
              assigned_user:staff!assigned_to(id, name, email),
              created_by_user:users!created_by(id, name),
              lead_categories(
                category:categories(*)
              )
            ''')
            .eq('id', leadId)
            .isFilter('deleted_at', null)
            .maybeSingle();
      } catch (e) {
        try {
          // Second try: Join with users table
          lead = await SupabaseService.from('leads')
              .select('''
                *,
                assigned_user:users!assigned_to(id, name, email),
                created_by_user:users!created_by(id, name),
                lead_categories(
                  category:categories(*)
                )
              ''')
              .eq('id', leadId)
              .isFilter('deleted_at', null)
              .maybeSingle();
        } catch (e2) {
          // Fallback: query without user relationships
          lead = await SupabaseService.from('leads')
              .select('''
                *,
                lead_categories(
                  category:categories(*)
                )
              ''')
              .eq('id', leadId)
              .isFilter('deleted_at', null)
              .maybeSingle();
          
          // Fetch user data separately if needed
          if (lead != null) {
            final assignedTo = lead['assigned_to'] as String?;
            final createdBy = lead['created_by'] as String?;
            
            if (assignedTo != null) {
              // Try staff table first, then fallback to users table
              var assignedUser = await SupabaseService.from('staff')
                  .select('id, name, email')
                  .eq('id', assignedTo)
                  .maybeSingle();
              if (assignedUser == null) {
                assignedUser = await SupabaseService.from('users')
                    .select('id, name, email')
                    .eq('id', assignedTo)
                    .maybeSingle();
              }
              if (assignedUser != null) {
                lead['assigned_user'] = assignedUser;
              }
            }
            
            if (createdBy != null) {
              final createdByUser = await SupabaseService.from('users')
                  .select('id, name')
                  .eq('id', createdBy)
                  .maybeSingle();
              if (createdByUser != null) {
                lead['created_by_user'] = createdByUser;
              }
            }
          }
        }
      }

      if (lead == null) return null;
      final categories =
          (lead['lead_categories'] as List<dynamic>?)
              ?.map((lc) {
                final lcMap = lc as Map<String, dynamic>;
                final cat = lcMap['category'] as Map<String, dynamic>?;
                return cat != null ? CategoryModel.fromJson(cat) : null;
              })
              .whereType<CategoryModel>()
              .toList() ??
          [];

      return LeadWithRelationsModel.fromJson({
        ...lead,
        'categories': categories.map((c) => c.toJson()).toList(),
      });
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }

  // Create lead
  Future<LeadModel> create(
    String shopId,
    CreateLeadInput input,
    String userId,
  ) async {
    try {
      final categoryIds = input.categoryIds;
      final leadData = input.toJson();

      // Insert lead
      final data = await SupabaseService.from('leads')
          .insert({
            ...leadData,
            'shop_id': shopId,
            'created_by': userId,
            'status': input.status != null
                ? LeadModel.statusToString(input.status!)
                : 'new',
          })
          .select()
          .single();

      final lead = LeadModel.fromJson(data);

      // Assign categories if provided
      if (categoryIds != null && categoryIds.isNotEmpty) {
        await _assignCategories(lead.id, categoryIds);
      }

      return lead;
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }

  // Update lead
  Future<LeadModel> update(String leadId, CreateLeadInput input) async {
    try {
      final categoryIds = input.categoryIds;
      final updateData = input.toJson();
      // Remove categoryIds from updateData as it's not a column in leads table
      updateData.remove('category_ids');

      final data = await SupabaseService.from('leads')
          .update({
            ...updateData,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', leadId)
          .select()
          .single();

      final lead = LeadModel.fromJson(data);

      // Update categories if provided
      if (categoryIds != null) {
        await _assignCategories(lead.id, categoryIds);
      }

      return lead;
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }

  // Delete lead (soft delete)
  Future<void> delete(String leadId) async {
    try {
      await SupabaseService.from('leads')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', leadId);
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }

  // Assign categories to a lead
  Future<void> _assignCategories(
    String leadId,
    List<String> categoryIds,
  ) async {
    // Remove existing categories
    await SupabaseService.from('lead_categories')
        .delete()
        .eq('lead_id', leadId);

    // Add new categories
    if (categoryIds.isNotEmpty) {
      final inserts = categoryIds
          .map((categoryId) => {'lead_id': leadId, 'category_id': categoryId})
          .toList();

      await SupabaseService.from('lead_categories').insert(inserts);
    }
  }

  // Get lead statistics
  Future<LeadStats> getStats(String shopId, {String? userId}) async {
    try {
      // Build query for all leads
      var allLeadsQuery = SupabaseService.from('leads')
          .select('id, status')
          .eq('shop_id', shopId)
          .isFilter('deleted_at', null);
      
      // For staff roles, filter by assigned_to OR created_by
      if (userId != null) {
        allLeadsQuery = allLeadsQuery.or('assigned_to.eq.$userId,created_by.eq.$userId');
      }
      
      final allLeads = await allLeadsQuery as List<dynamic>? ?? [];

      final total = allLeads.length;

      // Count by status (raw string for dashboard 8-status overview + enum for backward compat)
      final statusData = allLeads;
      final byStatus = <LeadStatus, int>{};
      final byStatusString = <String, int>{};

      for (final item in statusData) {
        final statusStr = ((item as Map<String, dynamic>)['status'] as String?) ?? 'new';
        // Raw count for dashboard (matches website: will_contact, need_follow_up, etc.)
        byStatusString[statusStr] = (byStatusString[statusStr] ?? 0) + 1;
        // Parse to enum for backward compat (conversion rate, etc.)
        LeadStatus status;
        switch (statusStr) {
          case 'contacted':
            status = LeadStatus.contacted;
            break;
          case 'qualified':
            status = LeadStatus.qualified;
            break;
          case 'converted':
          case 'closed_won':
            status = LeadStatus.converted;
            break;
          case 'lost':
          case 'closed_lost':
          case 'already_has':
          case 'no_need_now':
            status = LeadStatus.lost;
            break;
          case 'will_contact':
          case 'need_follow_up':
          case 'appointment_scheduled':
          case 'proposal_sent':
            status = LeadStatus.contacted;
            break;
          default:
            status = LeadStatus.newLead;
        }
        byStatus[status] = (byStatus[status] ?? 0) + 1;
      }

      // Get recent count (last 7 days) with same filters
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      var recentLeadsQuery = SupabaseService.from('leads')
          .select('id')
          .eq('shop_id', shopId)
          .isFilter('deleted_at', null)
          .gte('created_at', sevenDaysAgo.toIso8601String());
      
      // Apply same user filter for recent leads
      if (userId != null) {
        recentLeadsQuery = recentLeadsQuery.or('assigned_to.eq.$userId,created_by.eq.$userId');
      }
      
      final recentLeads = await recentLeadsQuery as List<dynamic>? ?? [];

      final recentCount = recentLeads.length;

      // For staff roles, get count of leads assigned to them (not created by them)
      int assignedCount = 0;
      if (userId != null) {
        final assignedLeads = await SupabaseService.from('leads')
            .select('id')
            .eq('shop_id', shopId)
            .eq('assigned_to', userId)
            .isFilter('deleted_at', null) as List<dynamic>? ?? [];
        assignedCount = assignedLeads.length;
      }

      // Category counts would require a more complex query
      // For now, return empty list
      final byCategory = <CategoryCount>[];

      return LeadStats(
        total: total,
        byStatus: byStatus,
        byStatusString: byStatusString,
        byCategory: byCategory,
        recentCount: recentCount,
        assignedCount: assignedCount,
      );
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }
}

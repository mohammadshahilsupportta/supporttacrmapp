import '../models/lead_model.dart';
import '../models/category_model.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/helpers.dart';

class LeadRepository {
  // Get all leads with filters
  Future<List<LeadWithRelationsModel>> findAll(
    String shopId, {
    LeadFilters? filters,
  }) async {
    try {
      // Fetch all leads for the shop (filter client-side to avoid API method issues)
      // Try multiple approaches to fetch assigned user data
      List<dynamic> data;
      try {
        // First try: Join with staff table (most likely scenario)
        data = await SupabaseService.from('leads')
            .select('''
              *,
              assigned_user:staff!assigned_to(id, name, email),
              created_by_user:users!created_by(id, name),
              lead_categories(
                category:categories(*)
              )
            ''')
            .eq('shop_id', shopId)
            .isFilter('deleted_at', null)
            .order('created_at', ascending: false) as List<dynamic>? ?? [];
      } catch (e) {
        try {
          // Second try: Join with users table
          data = await SupabaseService.from('leads')
              .select('''
                *,
                assigned_user:users!assigned_to(id, name, email),
                created_by_user:users!created_by(id, name),
                lead_categories(
                  category:categories(*)
                )
              ''')
              .eq('shop_id', shopId)
              .isFilter('deleted_at', null)
              .order('created_at', ascending: false) as List<dynamic>? ?? [];
        } catch (e2) {
          // Fallback: query without user relationships, fetch them separately
          data = await SupabaseService.from('leads')
              .select('''
                *,
                lead_categories(
                  category:categories(*)
                )
              ''')
              .eq('shop_id', shopId)
              .isFilter('deleted_at', null)
              .order('created_at', ascending: false) as List<dynamic>? ?? [];
          
          // Fetch user data separately for assigned_to and created_by
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
          
          Map<String, Map<String, dynamic>> assignedUsersMap = {};
          Map<String, Map<String, dynamic>> createdByUsersMap = {};
          
          // Try fetching from staff table first, then fallback to users table
          for (final userId in assignedToIds) {
            try {
              // Try staff table first
              var user = await SupabaseService.from('staff')
                  .select('id, name, email')
                  .eq('id', userId)
                  .maybeSingle();
              if (user == null) {
                // Fallback to users table
                user = await SupabaseService.from('users')
                    .select('id, name, email')
                    .eq('id', userId)
                    .maybeSingle();
              }
              if (user != null) {
                assignedUsersMap[userId] = Map<String, dynamic>.from(user);
              }
            } catch (e3) {
              // Skip if user not found
              continue;
            }
          }
          
          // Fetch created by users
          for (final userId in createdByIds) {
            try {
              final user = await SupabaseService.from('users')
                  .select('id, name')
                  .eq('id', userId)
                  .maybeSingle();
              if (user != null) {
                createdByUsersMap[userId] = Map<String, dynamic>.from(user);
              }
            } catch (e4) {
              // Skip if user not found
              continue;
            }
          }
          
          // Merge user data into leads
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

      // Apply client-side filters (status, categories, search fallback)
      if (filters != null) {
        // Filter by status client-side
        if (filters.status != null && filters.status!.isNotEmpty) {
          leads = leads.where((lead) {
            return filters.status!.contains(lead.status);
          }).toList();
        }

        // Filter by categories client-side
        if (filters.categoryIds != null && filters.categoryIds!.isNotEmpty) {
          leads = leads.where((lead) {
            return lead.categories.any(
              (cat) => filters.categoryIds!.contains(cat.id),
            );
          }).toList();
        }

        // Filter by search client-side if or() didn't work
        if (filters.search != null && filters.search!.isNotEmpty) {
          final searchLower = filters.search!.toLowerCase();
          leads = leads.where((lead) {
            return (lead.name.toLowerCase().contains(searchLower)) ||
                (lead.email?.toLowerCase().contains(searchLower) ?? false) ||
                (lead.phone?.toLowerCase().contains(searchLower) ?? false) ||
                (lead.company?.toLowerCase().contains(searchLower) ?? false);
          }).toList();
        }

        // Filter by score category client-side
        if (filters.scoreCategories != null && filters.scoreCategories!.isNotEmpty) {
          leads = leads.where((lead) {
            if (lead.scoreCategory == null) {
              return filters.scoreCategories!.contains('unscored');
            }
            return filters.scoreCategories!.contains(lead.scoreCategory!.toLowerCase());
          }).toList();
        }
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
  Future<LeadStats> getStats(String shopId) async {
    try {
      // Get all leads for counting
      final allLeads = await SupabaseService.from('leads')
          .select('id, status')
          .eq('shop_id', shopId)
          .isFilter('deleted_at', null) as List<dynamic>? ?? [];

      final total = allLeads.length;

      // Count by status
      final statusData = allLeads;
      final byStatus = <LeadStatus, int>{};

      for (final item in statusData) {
        final statusStr = (item as Map<String, dynamic>)['status'] as String;
        // Parse status string to enum
        LeadStatus status;
        switch (statusStr) {
          case 'contacted':
            status = LeadStatus.contacted;
            break;
          case 'qualified':
            status = LeadStatus.qualified;
            break;
          case 'converted':
            status = LeadStatus.converted;
            break;
          case 'lost':
            status = LeadStatus.lost;
            break;
          default:
            status = LeadStatus.newLead;
        }
        byStatus[status] = (byStatus[status] ?? 0) + 1;
      }

      // Get recent count (last 7 days)
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final recentLeads = await SupabaseService.from('leads')
          .select('id')
          .eq('shop_id', shopId)
          .isFilter('deleted_at', null)
          .gte('created_at', sevenDaysAgo.toIso8601String()) as List<dynamic>? ?? [];

      final recentCount = recentLeads.length;

      // Category counts would require a more complex query
      // For now, return empty list
      final byCategory = <CategoryCount>[];

      return LeadStats(
        total: total,
        byStatus: byStatus,
        byCategory: byCategory,
        recentCount: recentCount,
      );
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }
}

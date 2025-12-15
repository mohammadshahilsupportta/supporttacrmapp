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
      final data = await SupabaseService.from('leads')
          .select('''
            *,
            assigned_user:users!leads_assigned_to_fkey(id, name, email),
            created_by_user:users!leads_created_by_fkey(id, name),
            lead_categories(
              category:categories(*)
            )
          ''')
          .eq('shop_id', shopId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false) as List<dynamic>? ?? [];

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
      }

      return leads;
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }

  // Get lead by ID
  Future<LeadWithRelationsModel?> findById(String leadId) async {
    try {
      final lead = await SupabaseService.from('leads')
          .select('''
            *,
            assigned_user:users!leads_assigned_to_fkey(id, name, email),
            created_by_user:users!leads_created_by_fkey(id, name),
            lead_categories(
              category:categories(*)
            )
          ''')
          .eq('id', leadId)
          .isFilter('deleted_at', null)
          .maybeSingle();

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

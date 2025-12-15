import '../../core/services/supabase_service.dart';
import '../../core/utils/helpers.dart';

abstract class BaseRepository {
  // Generic CRUD operations using Supabase
  // Note: After running 'flutter pub get', if there are type errors with execute(),
  // you may need to adjust based on your Supabase Flutter package version

  // Get all records
  Future<List<Map<String, dynamic>>> getAll(String table) async {
    try {
      final response = await (SupabaseService.from(table).select() as dynamic).execute();
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }

  // Get record by ID
  Future<Map<String, dynamic>?> getById(String table, String id) async {
    try {
      final data = await SupabaseService
          .from(table)
          .select()
          .eq('id', id)
          .maybeSingle();
      return data;
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }

  // Create record
  Future<Map<String, dynamic>> create(
    String table,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await SupabaseService
          .from(table)
          .insert(data)
          .select()
          .single();
      return result;
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }

  // Update record
  Future<Map<String, dynamic>> update(
    String table,
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await SupabaseService
          .from(table)
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return result;
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }

  // Delete record
  Future<void> delete(String table, String id) async {
    try {
      await (SupabaseService.from(table).delete().eq('id', id) as dynamic).execute();
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }

  // Query with filters
  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? select,
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = true,
    int? limit,
    int? offset,
  }) async {
    try {
      // Start with select
      var queryBuilder = SupabaseService.from(table).select(select ?? '*');

      // Apply filters
      if (filters != null) {
        for (var entry in filters.entries) {
          queryBuilder = queryBuilder.eq(entry.key, entry.value);
        }
      }

      // Apply ordering and pagination
      dynamic transformBuilder = queryBuilder;
      if (orderBy != null) {
        transformBuilder = transformBuilder.order(orderBy, ascending: ascending);
      }

      if (offset != null && limit != null) {
        transformBuilder = transformBuilder.range(offset, offset + limit - 1);
      } else if (limit != null) {
        transformBuilder = transformBuilder.limit(limit);
      }

      // Execute query
      final response = await (transformBuilder as dynamic).execute();
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      throw Helpers.handleError(e);
    }
  }
}

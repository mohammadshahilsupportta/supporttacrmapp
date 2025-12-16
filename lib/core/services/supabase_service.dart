import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Get Supabase client
  static SupabaseClient get client => _client;

  // Auth methods
  static GoTrueClient get auth => _client.auth;

  // Database methods
  static PostgrestQueryBuilder from(String table) {
    return _client.from(table);
  }

  // Storage methods
  static SupabaseStorageClient get storage => _client.storage;

  // Realtime methods
  static RealtimeChannel channel(String name) {
    return _client.channel(name);
  }

  // RPC methods
  static PostgrestFilterBuilder rpc(String functionName, {Map<String, dynamic>? params}) {
    return _client.rpc(functionName, params: params);
  }

  // Edge Function methods
  static Future<Map<String, dynamic>> invokeFunction(
    String functionName, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await _client.functions.invoke(
        functionName,
        body: body,
      );
      
      if (response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      
      // If no data, return empty map (function might have succeeded without returning data)
      return {};
    } catch (e) {
      // Re-throw with better error message
      throw Exception('Failed to invoke Edge Function $functionName: $e');
    }
  }

  // Check if user is authenticated
  static bool get isAuthenticated => _client.auth.currentUser != null;

  // Get current user
  static User? get currentUser => _client.auth.currentUser;

  // Get current session
  static Session? get currentSession => _client.auth.currentSession;
}



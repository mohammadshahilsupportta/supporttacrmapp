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

  // Check if user is authenticated
  static bool get isAuthenticated => _client.auth.currentUser != null;

  // Get current user
  static User? get currentUser => _client.auth.currentUser;

  // Get current session
  static Session? get currentSession => _client.auth.currentSession;
}



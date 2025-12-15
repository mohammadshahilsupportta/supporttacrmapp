class AppConstants {
  // App Info
  static const String appName = 'Supporta CRM';

  // Supabase Configuration
  // IMPORTANT: Verify these credentials in your Supabase dashboard
  // If you get "No address associated with hostname" error:
  // 1. Check if your Supabase project is paused (free tier pauses after inactivity)
  // 2. Go to https://supabase.com/dashboard and unpause/reactivate your project
  // 3. Verify the URL and anon key are correct
  // 4. Check your internet connection
  static const String supabaseUrl = 'https://nprkkrillxhgedgiajtc.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5wcmtrcmlsbHhoZ2VkZ2lhanRjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU3MTA2MjIsImV4cCI6MjA4MTI4NjYyMn0.d0YsbmJb1fPXJffSbxm0BM8PvCpuaaJ0Z1hcIFb5JPE';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String sessionKey = 'supabase_session';

  // Timeouts
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Pagination
  static const int defaultPageSize = 20;
}

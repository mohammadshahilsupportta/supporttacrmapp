class Helpers {
  // Handle and format errors
  static String handleError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Network error handling
    if (errorString.contains('no address associated with hostname') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('network is unreachable') ||
        errorString.contains('connection refused') ||
        errorString.contains('socketexception')) {
      return 'Network error: Please check your internet connection and try again';
    }
    
    // Supabase specific error handling
    if (errorString.contains('invalid login credentials') ||
        errorString.contains('invalid credentials')) {
      return 'Invalid email or password';
    }
    if (errorString.contains('user already registered') ||
        errorString.contains('already registered')) {
      return 'This email is already registered';
    }
    if (errorString.contains('email not confirmed') ||
        errorString.contains('email not verified')) {
      return 'Please verify your email address';
    }
    if (errorString.contains('jwt expired') ||
        errorString.contains('session expired')) {
      return 'Session expired. Please login again';
    }
    if (errorString.contains('user account not found')) {
      return 'User account not found in database';
    }
    if (errorString.contains('shop data not found')) {
      return 'Shop data not found';
    }
    if (errorString.contains('shop account is inactive')) {
      return 'Shop account is inactive. Please contact support';
    }
    
    // Extract meaningful error message
    if (error is Exception) {
      final match = RegExp(r'Error: (.+)', caseSensitive: false).firstMatch(error.toString());
      if (match != null) {
        return match.group(1) ?? 'An error occurred';
      }
    }
    
    // Return user-friendly message
    final message = error.toString().replaceAll('Exception: ', '');
    if (message.isEmpty || message == 'null') {
      return 'An unexpected error occurred. Please try again';
    }
    
    return message;
  }

  // Format date
  static String formatDate(DateTime date, {String format = 'yyyy-MM-dd'}) {
    return date.toString().substring(0, 10);
  }

  // Validate email
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validate phone number
  static bool isValidPhone(String phone) {
    return RegExp(r'^\+?[\d\s-()]+$').hasMatch(phone);
  }

  // Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}



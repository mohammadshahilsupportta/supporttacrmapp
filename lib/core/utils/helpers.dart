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
    if (errorString.contains('email_address_invalid') ||
        errorString.contains('email address') && errorString.contains('invalid')) {
      return 'Please enter a valid email address';
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

  // Validate email (basic validation, Supabase will do final validation)
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    
    // Trim whitespace
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) return false;
    
    // Basic structure check: must contain exactly one @
    final atIndex = trimmedEmail.indexOf('@');
    if (atIndex <= 0 || atIndex >= trimmedEmail.length - 1) return false;
    
    // Split by @
    final parts = trimmedEmail.split('@');
    if (parts.length != 2) return false;
    
    final localPart = parts[0].trim();
    final domainPart = parts[1].trim();
    
    // Local part checks
    if (localPart.isEmpty) return false;
    
    // Domain part checks
    if (domainPart.isEmpty) return false;
    if (!domainPart.contains('.')) return false;
    
    // Domain must have TLD (at least 2 chars after last dot)
    final lastDotIndex = domainPart.lastIndexOf('.');
    if (lastDotIndex < 0 || lastDotIndex >= domainPart.length - 2) return false;
    
    // Basic character check - allow common email characters
    // This is permissive - let Supabase do the strict validation
    final hasValidChars = RegExp(r'^[a-zA-Z0-9@._+\-]+$').hasMatch(trimmedEmail);
    if (!hasValidChars) return false;
    
    return true;
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

  /// Returns a string safe for display in Text/TextSpan (well-formed UTF-16).
  /// Replaces unpaired surrogates with U+FFFD to avoid "string is not well-formed UTF-16" errors.
  static String safeDisplayString(String? s) {
    if (s == null || s.isEmpty) return s ?? '';
    final codes = s.codeUnits;
    final buffer = <int>[];
    for (var i = 0; i < codes.length; i++) {
      final c = codes[i];
      if (c < 0xD800 || c > 0xDFFF) {
        buffer.add(c);
      } else if (c >= 0xD800 && c <= 0xDBFF && i + 1 < codes.length) {
        final next = codes[i + 1];
        if (next >= 0xDC00 && next <= 0xDFFF) {
          buffer.add(c);
          buffer.add(next);
          i++;
        } else {
          buffer.add(0xFFFD);
        }
      } else {
        buffer.add(0xFFFD);
      }
    }
    return String.fromCharCodes(buffer);
  }
}



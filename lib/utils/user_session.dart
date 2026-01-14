/// Utility class for managing user session
class UserSession {
  static String? _userId;
  static String? _userEmail;
  static String? _userName;

  /// Get current user ID
  static String? get userId => _userId;

  /// Get current user email
  static String? get userEmail => _userEmail;

  /// Get current user name
  static String? get userName => _userName;

  /// Set user session
  static void setSession({
    required String userId,
    String? email,
    String? name,
  }) {
    _userId = userId;
    _userEmail = email;
    _userName = name;
  }

  /// Clear user session
  static void clearSession() {
    _userId = null;
    _userEmail = null;
    _userName = null;
  }

  /// Check if user is logged in
  static bool get isLoggedIn => _userId != null;
}

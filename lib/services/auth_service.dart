import "package:logger/logger.dart";
import "package:shared_preferences/shared_preferences.dart";

class GuestUser {
  final String id;
  final String displayName;
  
  GuestUser({required this.id, required this.displayName});
}

class AuthService {
  factory AuthService() => _instance;
  AuthService._internal();

  static final AuthService _instance = AuthService._internal();
  
  final Logger _logger = Logger();
  GuestUser? _currentUser;
  
  Future<void> signIn() async {
    try {
      // Create a guest user with a unique ID
      final String guestId = DateTime.now().millisecondsSinceEpoch.toString();
      _currentUser = GuestUser(
        id: guestId,
        displayName: "Guest User",
      );
      
      // Save the guest user info to shared preferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('guest_user_id', guestId);
      await prefs.setString('guest_user_name', "Guest User");
      
    } catch (e, s) {
      _logger.e("Failed to sign in as guest", error: e, stackTrace: s);
      rethrow;
    }
  }

  bool isAuthenticated() {
    try {
      return _currentUser != null;
    } catch (e, s) {
      _logger.e("Failed to check authentication status", error: e, stackTrace: s);
      rethrow;
    }
  }

  GuestUser? getUser() {
    try {
      return _currentUser;
    } catch (e, s) {
      _logger.e("Failed to get current user", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> loadUserFromPrefs() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? guestId = prefs.getString('guest_user_id');
      final String? guestName = prefs.getString('guest_user_name');
      
      if (guestId != null && guestName != null) {
        _currentUser = GuestUser(
          id: guestId,
          displayName: guestName,
        );
      }
    } catch (e, s) {
      _logger.e("Failed to load user from preferences", error: e, stackTrace: s);
    }
  }

  Future<void> signOut() async {
    try {
      _currentUser = null;
      
      // Clear the guest user info from shared preferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('guest_user_id');
      await prefs.remove('guest_user_name');
    } catch (e, s) {
      _logger.e("Failed to sign out", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    try {
      await signOut();
    } catch (e, s) {
      _logger.e("Failed to delete account", error: e, stackTrace: s);
      rethrow;
    }
  }
}
import "package:firebase_auth/firebase_auth.dart";
import "package:google_sign_in/google_sign_in.dart";
import "package:logger/logger.dart";

class AuthService {
  factory AuthService() => _instance;
  AuthService._internal();

  static final AuthService _instance = AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final Logger _logger = Logger();

  Future<OAuthCredential?> _getOAuthCredential() async {
    try {
      final GoogleSignInAccount user = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication auth = user.authentication;
      return GoogleAuthProvider.credential(idToken: auth.idToken);
    } catch (e, s) {
      _logger.e("Failed to get OAuth Credential", error: e, stackTrace: s);
    }

    return null;
  }

  Future<UserCredential?> signIn() async {
    try {
      final OAuthCredential? credential = await _getOAuthCredential();

      if (credential == null) {
        throw Exception("OAuth Credential is null");
      }

      return await _auth.signInWithCredential(credential);
    } catch (e, s) {
      _logger.e("Failed to authenticate", error: e, stackTrace: s);
    }

    return null;
  }

  bool isAuthenticated() {
    try {
      User? user = getUser();
      return user != null;
    } catch (e, s) {
      _logger.e("Failed to check authentication status", error: e, stackTrace: s);
    }

    return false;
  }

  User? getUser() {
    try {
      return _auth.currentUser;
    } catch (e, s) {
      _logger.e("Failed to get current user", error: e, stackTrace: s);
    }

    return null;
  }

  Future<UserCredential?> reAuthenticate() async {
    try {
      if (_auth.currentUser == null) {
        throw Exception("User is null");
      }

      final OAuthCredential? credential = await _getOAuthCredential();

      if (credential == null) {
        throw Exception("OAuth Credential is null");
      }

      return await _auth.currentUser?.reauthenticateWithCredential(credential);
    } catch (e, s) {
      _logger.e("Failed to re-authenticate", error: e, stackTrace: s);
    }

    return null;
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e, s) {
      _logger.e("Failed to sign out", error: e, stackTrace: s);
    }
  }

  Future<void> deleteAccount() async {
    try {
      if (_auth.currentUser == null) {
        throw Exception("User is null");
      }

      await _auth.currentUser?.delete();
    } catch (e, s) {
      _logger.e("Failed to delete account", error: e, stackTrace: s);
    }
  }
}
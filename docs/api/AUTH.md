**Auth Service**

- **Location:** `lib/services/auth_service.dart`
- **Auth Provider:** Google Sign-In via `google_sign_in` + `firebase_auth`.
- **Pattern:** Singleton (`AuthService()` returns a single shared instance).
- **Logging:** Errors are logged with `logger`; methods return `null` on failure.

**Prerequisites**

- **Firebase setup:** App must be configured with Firebase (see `firebase_options.dart`).
- **Google Sign-In init:** Initialize Google Sign-In early in `main.dart`:
  - `await GoogleSignIn.instance.initialize();`
- **Platform config:** Ensure Google credentials are configured for each platform (Android SHA-1/SHA-256, iOS reversed client ID, Web OAuth client).

**Common Usage**

- **Sign In:** Triggers Google auth and signs in to Firebase with the returned credential.
  - `final UserCredential? cred = await AuthService().signIn();`
  - Returns `null` if the user cancels or an error occurs.

- **Check Authenticated:** Quick boolean for routing and guards.
  - `final bool isAuthed = AuthService().isAuthenticated();`

- **Get Current User:** Direct access to the `FirebaseAuth.currentUser`.
  - `final User? user = AuthService().getUser();`

- **Re‑Authenticate:** Use before sensitive operations (e.g., delete account) to avoid `requires-recent-login`.
  - `final UserCredential? cred = await AuthService().reAuthenticate();`

- **Sign Out:** Signs out of both Google and Firebase.
  - `await AuthService().signOut();`

- **Delete Account:** Deletes the currently signed-in user. Re-auth may be required.
  - `await AuthService().deleteAccount();`

**Examples**

- **Landing/Sign-in Button:**
  - `final creds = await AuthService().signIn(); if (creds != null) { /* navigate */ }`
  - Example in repo: `lib/screens/landing_screen.dart` uses `AuthService().signIn()`.

- **Splash Routing:**
  - `if (AuthService().isAuthenticated()) { /* go to app */ } else { /* go to landing */ }`
  - Example in repo: `lib/screens/splash_screen.dart`.

- **Settings – Sign Out:**
  - `await AuthService().signOut();`
  - Example in repo: `lib/screens/settings_screen.dart` (`_signOut`).

- **Sensitive Action (Delete Account):**
  - `await AuthService().reAuthenticate(); await AuthService().deleteAccount();`

**Auth Flow Details**

- **Google → Firebase:**
  - The service performs a lightweight Google auth if possible, then falls back to full auth.
  - It builds a `GoogleAuthProvider.credential` from the Google ID token and calls `FirebaseAuth.signInWithCredential`.

- **State:**
  - `isAuthenticated()` and `getUser()` read from `FirebaseAuth.instance`.
  - For reactive UI, listen to `FirebaseAuth.instance.authStateChanges()` directly.

**Error Handling**

- Methods catch and log errors internally and typically return `null` (or `false` for boolean checks).
- In UI, treat `null` results as a non-success (canceled or failed) and surface a message/snack bar as needed.

**Testing**

TBD

**Quick Reference**

- `Future<UserCredential?> signIn()`
- `bool isAuthenticated()`
- `User? getUser()`
- `Future<UserCredential?> reAuthenticate()`
- `Future<void> signOut()`
- `Future<void> deleteAccount()`


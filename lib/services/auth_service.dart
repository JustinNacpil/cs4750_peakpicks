import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;

  // Current user stream
  static Stream<User?> get userStream => _auth.authStateChanges();

  // Current user (sync)
  static User? get currentUser => _auth.currentUser;

  // ── Sign Up ─────────────────────────────────────
  static Future<UserCredential> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (displayName != null && displayName.trim().isNotEmpty) {
      await cred.user?.updateDisplayName(displayName.trim());
      await cred.user?.reload();
    }
    return cred;
  }

  // ── Sign In ─────────────────────────────────────
  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // ── Guest (Anonymous) Sign In ────────────────────
  static Future<UserCredential> signInAsGuest() =>
      _auth.signInAnonymously();

  // ── Upgrade guest to real account ───────────────
  static Future<UserCredential> linkGuestToEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = EmailAuthProvider.credential(
      email: email.trim(),
      password: password,
    );
    final cred = await _auth.currentUser!.linkWithCredential(credential);
    if (displayName != null && displayName.trim().isNotEmpty) {
      await cred.user?.updateDisplayName(displayName.trim());
      await cred.user?.reload();
    }
    return cred;
  }

  // ── Sign Out ─────────────────────────────────────
  static Future<void> signOut() => _auth.signOut();

  // ── Update Display Name ──────────────────────────
  static Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name.trim());
    await _auth.currentUser?.reload();
  }

  // ── User-friendly error messages ─────────────────
  static String friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
        return 'Incorrect password. Try again.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }
}

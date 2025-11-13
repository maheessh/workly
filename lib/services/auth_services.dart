import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Regular GoogleSignIn instance for mobile
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '499488421543-dqpsq3vag3cus0hme6lohd7vj5cjes5i.apps.googleusercontent.com'
        : null,
    scopes: ['email', 'profile'],
  );

  // Current Firebase user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check sign-in status
  bool get isSignedIn => _auth.currentUser != null;

  // -------------------------------------------------------------
  // 🔐 Updated Google Sign-In (Web-compatible, post-2024 changes)
  // -------------------------------------------------------------
  Future<UserModel?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // --- Web flow ---
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        // Use signInWithPopup (new method)
        final userCredential =
            await _auth.signInWithPopup(googleProvider);

        final user = userCredential.user;
        if (user == null) return null;

        return UserModel(
          userId: user.uid,
          name: user.displayName ?? '',
          email: user.email ?? '',
          isGuest: false,
          authProvider: 'google',
          photoUrl: user.photoURL,
        );
      } else {
        // --- Android / iOS flow ---
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null; // cancelled

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);
        final user = userCredential.user;

        if (user == null) return null;

        return UserModel(
          userId: user.uid,
          name: user.displayName ?? '',
          email: user.email ?? '',
          isGuest: false,
          authProvider: 'google',
          photoUrl: user.photoURL,
        );
      }
    } catch (e) {
      debugPrint('Google sign-in failed: $e');
      return null;
    }
  }

  // -------------------------------------------------------------
  // 👤 Guest User
  // -------------------------------------------------------------
  UserModel createGuestUser() {
    return UserModel(
      userId: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Guest User',
      email: '',
      isGuest: true,
      authProvider: 'guest',
    );
  }

  // -------------------------------------------------------------
  // 🚪 Sign out
  // -------------------------------------------------------------
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      debugPrint('Sign out failed: $e');
    }
  }

  // -------------------------------------------------------------
  // 🗑 Delete account
  // -------------------------------------------------------------
  Future<bool> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
        if (!kIsWeb) await _googleSignIn.signOut();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Delete account failed: $e');
      return false;
    }
  }

  // -------------------------------------------------------------
  // ✏️ Update user profile
  // -------------------------------------------------------------
  Future<bool> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.updatePhotoURL(photoURL);
        await user.reload();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Profile update failed: $e');
      return false;
    }
  }
}

// lib/providers/auth_provider.dart

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:job_tinder/services/auth_services.dart';
import '../models/user_model.dart';
import '../services/user_storage_service.dart'; // ⬅️ Your upgraded service

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _currentUser;
  bool _isLoading = true; // ⬅️ Start as true on app load
  bool _isSigningIn = false;
  String? _errorMessage;
  DateTime? _lastAuthStateChange;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSignedIn => _currentUser != null && !_currentUser!.isGuest;
  bool get isGuest => _currentUser?.isGuest ?? false;
  bool get hasUser => _currentUser != null;

  AuthProvider() {
    _initializeAuth();
  }

  // 💡 --- HEAVILY MODIFIED METHOD --- 💡
  // Initialize authentication state
  void _initializeAuth() {
    _authService.authStateChanges.listen((User? firebaseUser) async {
      // Debounce logic
      final now = DateTime.now();
      if (_lastAuthStateChange != null && 
          now.difference(_lastAuthStateChange!).inMilliseconds < 500) {
        return;
      }
      _lastAuthStateChange = now;
      _setLoading(true); // Show loading spinner
      
      if (firebaseUser != null) {
        // --- User is LOGGED IN with Firebase ---

        // 1. Try to load their profile from Firestore
        UserModel? firestoreUser =
            await UserStorageService.loadUserProfileFromFirestore(firebaseUser.uid);

        if (firestoreUser != null) {
          // Found them! They are a returning user.
          _currentUser = firestoreUser;
          // Save locally as a cache
          await UserStorageService.saveUserProfileLocally(_currentUser!);
        } else {
          // 2. Not in Firestore. This is a NEW user or
          //    a GUEST who is logging in.
          
          // Try to load a local profile to see if they were a guest
          UserModel? localGuestUser = await UserStorageService.loadUserProfileLocally();
          
          _currentUser = UserModel(
            userId: firebaseUser.uid,
            name: firebaseUser.displayName ?? localGuestUser?.name ?? '',
            email: firebaseUser.email ?? localGuestUser?.email ?? '',
            photoUrl: firebaseUser.photoURL,
            isGuest: false,
            authProvider: 'google',

            // 💡 MERGE GUEST DATA 💡
            // This brings their resume data over!
            phoneNumber: localGuestUser?.phoneNumber ?? '',
            location: localGuestUser?.location ?? '',
            summary: localGuestUser?.summary ?? '',
            skills: localGuestUser?.skills ?? <String>{},
            workExperience: localGuestUser?.workExperience ?? <String>[],
            education: localGuestUser?.education ?? <String>[],
            resumeFileName: localGuestUser?.resumeFileName ?? '',
            resumeFilePath: localGuestUser?.resumeFilePath ?? '',
            portfolioUrl: localGuestUser?.portfolioUrl ?? '',
            githubUrl: localGuestUser?.githubUrl ?? '',
            linkedinUrl: localGuestUser?.linkedinUrl ?? '',
          );

          // 3. Save this new/merged profile TO FIRESTORE
          await UserStorageService.saveUserProfileToFirestore(_currentUser!);
          // And save locally, overwriting the old guest profile
          await UserStorageService.saveUserProfileLocally(_currentUser!);
        }
      } else {
        // --- User is LOGGED OUT of Firebase ---
        
        // 1. Try to load a local profile. If it's a guest, log them in as guest.
        UserModel? localUser = await UserStorageService.loadUserProfileLocally();
        if (localUser != null && localUser.isGuest) {
          _currentUser = localUser;
        } else {
          // No Firebase user and no local guest = truly logged out.
          _currentUser = null;
          // Clear any non-guest local data
          await UserStorageService.clearUserProfileLocally();
        }
      }
      _setLoading(false); // Hide loading spinner
      notifyListeners();
    });
  }

  // 💡 --- SLIGHTLY MODIFIED METHOD --- 💡
  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _isSigningIn = true; 
    _clearError();

    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        // The auth state listener (_initializeAuth) will handle the rest
        // We just wait a moment for it to complete
        await Future.delayed(const Duration(milliseconds: 1000));
        return true;
      } else {
        _setError('Sign-in was cancelled');
        return false;
      }
    } catch (e) {
      _setError('Failed to sign in with Google: ${e.toString()}');
      return false;
    } finally {
      // Don't set loading to false, _initializeAuth will
      Future.delayed(const Duration(milliseconds: 1000), () {
        _isSigningIn = false;
      });
    }
  }

  // 💡 --- MODIFIED METHOD --- 💡
  // Sign in as guest
  void signInAsGuest() async {
    _setLoading(true);
    _currentUser = _authService.createGuestUser();
    // 💡 Save this guest user locally
    await UserStorageService.saveUserProfileLocally(_currentUser!);
    _setLoading(false);
    notifyListeners();
  }

  // 💡 --- MODIFIED METHOD --- 💡
  // Sign out
  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      // 💡 Clear the local profile on sign out
      await UserStorageService.clearUserProfileLocally();
      
      _currentUser = null;
      notifyListeners();
      
      // Then sign out from services
      await _authService.signOut();
      
    } catch (e) {
      _setError('Failed to sign out: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // 💡 --- MODIFIED METHOD --- 💡
  // Delete account
  Future<bool> deleteAccount() async {
    _setLoading(true);
    _clearError();

    try {
      // Clear stored profile data when deleting account
      await UserStorageService.clearUserProfileLocally();
      
      final success = await _authService.deleteAccount();
      if (success) {
        _currentUser = null;
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Failed to delete account: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    if (_currentUser == null || _currentUser!.isGuest) {
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final success = await _authService.updateUserProfile(
        displayName: displayName,
        photoURL: photoURL,
      );
      
      if (success && _currentUser != null) {
        // Use copyWith to update the user
        _currentUser = _currentUser!.copyWith(
          name: displayName,
          photoUrl: photoURL,
        );
        // Save the update to both places
        await saveCurrentProfile();
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      _setError('Failed to update profile: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 💡 --- THIS IS THE KEY METHOD YOUR PROFILE SCREEN WILL CALL --- 💡
  // Update local user data (for profile editing)
  Future<void> updateLocalUser(UserModel updatedUser) async {
    _currentUser = updatedUser;
    // This method is called from ProfileScreen, so we save here.
    await saveCurrentProfile();
    notifyListeners();
  }

  /// Helper method to save the current user to the correct location
  Future<void> saveCurrentProfile() async {
    if (_currentUser == null) return;
    
    if (_currentUser!.isGuest) {
      await UserStorageService.saveUserProfileLocally(_currentUser!);
    } else {
      await UserStorageService.saveUserProfileToFirestore(_currentUser!);
      // also save locally as a cache
      await UserStorageService.saveUserProfileLocally(_currentUser!);
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    if (_isLoading == loading) return; // Avoid unnecessary rebuilds
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear error manually
  void clearError() {
    _clearError();
  }
}
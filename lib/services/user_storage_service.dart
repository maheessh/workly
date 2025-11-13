// lib/services/user_storage_service.dart

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class UserStorageService {
  static const String _userKey = 'user_profile_data';
  
  // ⬅️ ADD THIS
  static final _firestore = FirebaseFirestore.instance;

  // =======================================================================
  // == LOCAL (GUEST) STORAGE (Your existing code, renamed for clarity) ==
  // =======================================================================

  /// Save user profile data locally (for guests or caching)
  static Future<void> saveUserProfileLocally(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 💡 Use your model's built-in toJson() for cleaner code
      final userJson = jsonEncode(user.toJson()); 
      
      await prefs.setString(_userKey, userJson);
    } catch (e) {
      // It's better to print errors during development
      debugPrint('Error saving user locally: $e'); 
    }
  }

  /// Load user profile data from local storage
  static Future<UserModel?> loadUserProfileLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);

      if (userJson != null) {
        final userData = jsonDecode(userJson) as Map<String, dynamic>;
        
        // 💡 Use your model's built-in fromJson()
        return UserModel.fromJson(userData);
      }
    } catch (e) {
      debugPrint('Error loading user locally: $e');
    }
    return null;
  }

  /// Clear user profile data
  static Future<void> clearUserProfileLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
    } catch (e) {
      debugPrint('Error clearing user locally: $e');
    }
  }
  
  // =======================================================================
  // ==  NEW: FIRESTORE (LOGGED-IN) STORAGE                             ==
  // =======================================================================

  /// ⬅️ NEW METHOD: Save a user profile to Firestore
  static Future<void> saveUserProfileToFirestore(UserModel user) async {
    // Safety check: Don't save guests or users without an ID to Firestore
    if (user.isGuest || user.userId.isEmpty) return;

    try {
      final userDocRef = _firestore.collection('users').doc(user.userId);
      // Use SetOptions(merge: true) to update fields without overwriting
      await userDocRef.set(user.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving user to Firestore: $e');
    }
  }

  /// ⬅️ NEW METHOD: Load a user profile from Firestore
  static Future<UserModel?> loadUserProfileFromFirestore(String userId) async {
    if (userId.isEmpty) return null;

    try {
      final userDocRef = _firestore.collection('users').doc(userId);
      final docSnap = await userDocRef.get();

      if (docSnap.exists) {
        // Use your model's factory to create the user
        return UserModel.fromJson(docSnap.data()!);
      }
    } catch (e) {
      debugPrint('Error loading user from Firestore: $e');
    }
    return null;
  }
}
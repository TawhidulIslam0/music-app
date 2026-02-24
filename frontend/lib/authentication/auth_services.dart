import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirebaseAuthServices {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance; // Add Firestore

  /// Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint("Sign up failed: ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("Unexpected Error during Sign Up: $e");
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint("Sign in failed: ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("Unexpected Error during Sign in: $e");
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      debugPrint("Password reset failed: ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("Unexpected error during password reset: $e");
      rethrow;
    }
  }

  /// Listen for authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// NEW METHOD: Get current user's ID token
  Future<String?> getIdToken() async {
    final user = _auth.currentUser;
    if (user != null) {
      return await user.getIdToken();
    }
    return null; // user not signed in
  }

  /// NEW METHOD: Get the user's selected genres from Firestore
  Future<List<String>?> getUserGenres(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null || !data.containsKey('genres')) return null;

      // Ensure we return a List<String>
      final genres = List<String>.from(data['genres']);
      return genres;
    } catch (e) {
      debugPrint("Error fetching genres: $e");
      return null;
    }
  }
}

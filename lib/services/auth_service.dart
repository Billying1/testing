import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import 'preference_service.dart';

class AuthService {
  /// Human-readable message from the last failed operation, so the UI can
  /// show *why* something failed (wrong password, email in use, etc.)
  /// instead of a generic "Failed" message.
  static String? lastError;

  static bool get _firebaseAvailable => Firebase.apps.isNotEmpty;

  static FirebaseAuth get _auth => FirebaseAuth.instance;

  static const String _usersCollection = 'users';

  /// ============================
  /// REGISTER
  /// ============================
  static Future<bool> register(UserModel user) async {
    lastError = null;

    if (_firebaseAvailable) {
      try {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: user.email,
          password: user.password,
        );

        final uid = credential.user!.uid;

        await credential.user!.updateDisplayName(user.fullName);

        // Store the profile fields in Firestore (password is never stored
        // here - Firebase Auth already manages that securely).
        await FirebaseFirestore.instance
            .collection(_usersCollection)
            .doc(uid)
            .set({
              'fullName': user.fullName,
              'email': user.email,
              'phone': user.phone,
              'avatar': user.avatar,
              'gender': user.gender,
              'city': user.city,
            });

        // Cache locally too, so profile/history screens keep working
        // even offline.
        await PreferenceService.saveUser(user);

        return true;
      } on FirebaseAuthException catch (e) {
        lastError = _friendlyAuthError(e);
        debugPrint('Firebase register error: ${e.code} ${e.message}');
        return false;
      } catch (e) {
        lastError = 'Register Error: $e';
        debugPrint(lastError);
        return false;
      }
    }

    // Fallback: Firebase not configured, keep the previous local behaviour.
    try {
      await PreferenceService.saveUser(user);
      return true;
    } catch (e) {
      lastError = 'Register Error: $e';
      debugPrint(lastError);
      return false;
    }
  }

  /// ============================
  /// LOGIN
  /// ============================
  static Future<bool> login({
    required String email,
    required String password,
  }) async {
    lastError = null;

    if (_firebaseAvailable) {
      try {
        final credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        final uid = credential.user!.uid;

        // Pull the profile back from Firestore and cache it locally so the
        // rest of the app (profile page, etc.) keeps working unchanged.
        final doc = await FirebaseFirestore.instance
            .collection(_usersCollection)
            .doc(uid)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          final user = UserModel(
            fullName: data['fullName'] ?? '',
            email: data['email'] ?? email,
            phone: data['phone'] ?? '',
            password: password,
            avatar: data['avatar'] ?? '',
            gender: data['gender'] ?? '',
            city: data['city'] ?? '',
          );
          await PreferenceService.saveUser(user);
        }

        await PreferenceService.setLogin(true);
        await PreferenceService.addHistory(email);

        return true;
      } on FirebaseAuthException catch (e) {
        lastError = _friendlyAuthError(e);
        debugPrint('Firebase login error: ${e.code} ${e.message}');
        return false;
      } catch (e) {
        lastError = 'Login Error: $e';
        debugPrint(lastError);
        return false;
      }
    }

    // Fallback: Firebase not configured, keep the previous local behaviour.
    try {
      UserModel? user = await PreferenceService.getUser();

      if (user == null) {
        return false;
      }

      if (user.email == email && user.password == password) {
        await PreferenceService.setLogin(true);
        await PreferenceService.addHistory(email);
        return true;
      }

      return false;
    } catch (e) {
      lastError = 'Login Error: $e';
      debugPrint(lastError);
      return false;
    }
  }

  /// ============================
  /// RESET PASSWORD
  /// ============================
  static Future<bool> resetPassword({required String email}) async {
    lastError = null;

    if (_firebaseAvailable) {
      try {
        await _auth.sendPasswordResetEmail(email: email);
        return true;
      } on FirebaseAuthException catch (e) {
        lastError = _friendlyAuthError(e);
        debugPrint('Firebase resetPassword error: ${e.code} ${e.message}');
        return false;
      } catch (e) {
        lastError = 'Reset Password Error: $e';
        debugPrint(lastError);
        return false;
      }
    }

    // Fallback: Firebase not configured, so there's nowhere to send the
    // reset link. Let the caller know this feature isn't available offline.
    lastError = 'Password reset requires an internet connection.';
    return false;
  }

  /// ============================
  /// USER HIỆN TẠI
  /// ============================
  static Future<UserModel?> currentUser() async {
    return await PreferenceService.getUser();
  }

  /// ============================
  /// KIỂM TRA ĐĂNG NHẬP
  /// ============================
  static Future<bool> isLogin() async {
    if (_firebaseAvailable && _auth.currentUser != null) {
      return true;
    }
    return await PreferenceService.isLogin();
  }

  /// ============================
  /// LOGOUT
  /// ============================
  static Future<void> logout() async {
    if (_firebaseAvailable) {
      try {
        await _auth.signOut();
      } catch (e) {
        debugPrint('Firebase signOut error: $e');
      }
    }
    await PreferenceService.logout();
  }

  /// ============================
  /// LỊCH SỬ ĐĂNG NHẬP
  /// ============================
  static Future<List<String>> getHistory() async {
    return await PreferenceService.getHistory();
  }



  static String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email already exists';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'user-not-found':
      case 'invalid-credential':
        return 'No account found for that email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'network-request-failed':
        return 'Network error. Check your connection';
      default:
        return e.message ?? 'Authentication failed';
    }
  }
}
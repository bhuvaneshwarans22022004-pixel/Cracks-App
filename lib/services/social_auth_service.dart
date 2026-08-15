import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SocialAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '734262498360-kaa955ci39o54d2nopts87m4m1i2d3ok.apps.googleusercontent.com'
        : null,
  );

  // 1. Google Sign-In
  Future<String?> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled the sign-in

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        return await firebaseUser.getIdToken();
      }
    } catch (e) {
      print('Google Sign-In Error: $e');
      rethrow;
    }
    return null;
  }

  // 2. Phone Number OTP Verification (Trigger SMS code)
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
  }) async {
    try {
      // Clean phone number format (ensure +91 is added if not present)
      String cleanPhone = phoneNumber.trim();
      if (!cleanPhone.startsWith('+')) {
        if (cleanPhone.startsWith('91') && cleanPhone.length == 12) {
          cleanPhone = '+$cleanPhone';
        } else {
          cleanPhone = '+91$cleanPhone';
        }
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: cleanPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          onVerificationCompleted(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onVerificationFailed(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      print('Phone verification error: $e');
      rethrow;
    }
  }

  // 3. Complete Phone OTP Verification (Sign-in with SMS OTP code)
  Future<String?> verifyOTPAndGetToken({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        return await firebaseUser.getIdToken();
      }
    } catch (e) {
      print('OTP Verification Error: $e');
      rethrow;
    }
    return null;
  }

  // Native linking: Link Phone number credential to the currently logged in Firebase User
  Future<String?> linkPhoneWithCurrentAccount({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final User? firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        throw Exception("No user is currently signed in to Firebase.");
      }

      final AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );

      // Link credential to the current Firebase User instead of signing in separately
      final UserCredential userCredential = await firebaseUser.linkWithCredential(credential);
      final User? updatedUser = userCredential.user;
      if (updatedUser != null) {
        return await updatedUser.getIdToken(true); // Force token refresh
      }
    } catch (e) {
      print('Native Phone Linking Error: $e');
      rethrow;
    }
    return null;
  }

  // Native linking: Link Google account credential to the currently logged in Firebase User
  Future<String?> linkGoogleWithCurrentAccount() async {
    try {
      final User? firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        throw Exception("No user is currently signed in to Firebase.");
      }

      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      try {
        // Link credential to the current Firebase User
        final UserCredential userCredential = await firebaseUser.linkWithCredential(credential);
        final User? updatedUser = userCredential.user;
        if (updatedUser != null) {
          return await updatedUser.getIdToken(true); // Force token refresh
        }
      } catch (linkError) {
        // If Firebase Auth linking fails (e.g. account already in use), return ID token for backend merge
        print('Firebase linking failed: $linkError. Proceeding with Google ID Token for backend merge.');
        if (googleAuth.idToken != null) {
          return googleAuth.idToken;
        }
        rethrow;
      }
    } catch (e) {
      print('Native Google Linking Error: $e');
      rethrow;
    }
    return null;
  }

  // 4. Get active token (useful for profile linking)
  Future<String?> getCurrentUserToken() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      return await user.getIdToken(true); // Force refresh
    }
    return null;
  }

  // 5. Sign out of Firebase Auth
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
}

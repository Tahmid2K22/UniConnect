import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

Future<UserCredential?> signInWithGoogle() async {
  try {
    if (kIsWeb) {
      return await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
    }

    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      debugPrint('Google sign-in cancelled by user');
      return null;
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await FirebaseAuth.instance.signInWithCredential(credential);
  } on FirebaseAuthException catch (e) {
    debugPrint('Firebase auth error: ${e.code} - ${e.message}');
    return null;
  } catch (e) {
    debugPrint('Sign in error: $e');
    return null;
  }
}

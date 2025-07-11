import 'package:firebase_auth/firebase_auth.dart';

Future<UserCredential?> signInWithGoogle() async {
  try {
    final auth = FirebaseAuth.instance;

    // Web-only Google sign-in using popup
    final GoogleAuthProvider googleProvider = GoogleAuthProvider();

    return await auth.signInWithPopup(googleProvider);
  } catch (e) {
    print("Google Sign-In Error: $e");
    return null;
  }
}

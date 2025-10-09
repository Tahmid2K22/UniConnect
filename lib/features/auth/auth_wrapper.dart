import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:uni_connect/features/auth/login_page.dart';
import 'package:uni_connect/features/frontpage/front_page.dart';
import 'package:uni_connect/features/splashscreen/splash_screen.dart';
import 'package:uni_connect/utils/splash_toggle.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final showSplash = context.watch<SplashToggleProvider>().showSplash;

    if (showSplash) {
      return const SplashScreen();
    } else {
      return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (snapshot.hasData) {
            return FrontPage();
          } else {
            return const LoginPage();
          }
        },
      );
    }
  }
}

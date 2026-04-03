import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:uni_connect/features/auth/login_page.dart';
import 'package:uni_connect/features/frontpage/front_page.dart';
import 'package:uni_connect/features/splashscreen/splash_screen.dart';
import 'package:uni_connect/utils/splash_toggle.dart';
import 'package:flutter/foundation.dart';
import 'package:uni_connect/features/web/web_front_page.dart';
import 'package:uni_connect/features/web/web_login_page.dart';
import 'package:uni_connect/utils/guest_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final showSplash = context.watch<SplashToggleProvider>().showSplash;

    if (showSplash) {
      return const SplashScreen();
    } else if (GuestService.isGuestUser) {
      return kIsWeb ? const WebFrontPage() : const FrontPage();
    } else {
      return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color.fromARGB(255, 11, 11, 34),
              body: Center(
                child: CircularProgressIndicator(color: Colors.tealAccent),
              ),
            );
          } else if (snapshot.hasError) {
            return Scaffold(
              backgroundColor: const Color.fromARGB(255, 11, 11, 34),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Authentication Error',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          } else if (snapshot.hasData) {
            return kIsWeb ? const WebFrontPage() : const FrontPage();
          } else {
            return kIsWeb ? const WebLoginPage() : const LoginPage();
          }
        },
      );
    }
  }
}

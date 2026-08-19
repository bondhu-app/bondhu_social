import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'services/data_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const BondhuSocialApp());
}

class BondhuSocialApp extends StatelessWidget {
  const BondhuSocialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'বন্ধু সোশ্যাল',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        scaffoldBackgroundColor:
            const Color(0xFFF0F2F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

// ============================================================
// AUTH GATE
// ============================================================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ----------------------------------------------------
        // LOADING
        // ----------------------------------------------------

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const SplashScreen();
        }

        // ----------------------------------------------------
        // ERROR
        // ----------------------------------------------------

        if (snapshot.hasError) {
          return const LoginScreen();
        }

        // ----------------------------------------------------
        // USER NOT LOGGED IN
        // ----------------------------------------------------

        if (!snapshot.hasData ||
            snapshot.data == null) {
          return const LoginScreen();
        }

        // ----------------------------------------------------
        // USER LOGGED IN
        // ----------------------------------------------------

        return const RoleGate();
      },
    );
  }
}

// ============================================================
// ROLE GATE
// ============================================================

class RoleGate extends StatelessWidget {
  const RoleGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: DataService.instance.isAdmin(),
      builder: (context, snapshot) {
        // ----------------------------------------------------
        // CHECKING ROLE
        // ----------------------------------------------------

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const SplashScreen(
            message: 'Account যাচাই করা হচ্ছে...',
          );
        }

        // ----------------------------------------------------
        // ADMIN
        // ----------------------------------------------------

        if (snapshot.data == true) {
          return const AdminDashboardScreen();
        }

        // ----------------------------------------------------
        // NORMAL USER
        // ----------------------------------------------------

        return const HomeScreen();
      },
    );
  }
}

// ============================================================
// SPLASH SCREEN
// ============================================================

class SplashScreen extends StatelessWidget {
  final String message;

  const SplashScreen({
    super.key,
    this.message = 'লোড হচ্ছে...',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_alt_rounded,
              size: 85,
              color: Colors.blue,
            ),

            const SizedBox(height: 20),

            const Text(
              'বন্ধু সোশ্যাল',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            const CircularProgressIndicator(),

            const SizedBox(height: 15),

            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'firebase_options.dart';
import 'services/ad_service.dart';

import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // FIREBASE INITIALIZE
  // ============================================================

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ============================================================
  // ADMOB INITIALIZE
  // ============================================================

  await MobileAds.instance.initialize();

  // ============================================================
  // LOAD ADS
  // ============================================================

  AdService.instance.preloadAds();

  // ============================================================
  // START APP
  // ============================================================

  runApp(const BondhuSocialApp());
}

// ================================================================
// APP
// ================================================================

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

// ================================================================
// AUTH GATE
// ================================================================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),

      builder: (
        context,
        snapshot,
      ) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const SplashScreen();
        }

        final user = snapshot.data;

        if (user == null) {
          return const LoginScreen();
        }

        return const UserRoleGate();
      },
    );
  }
}

// ================================================================
// USER ROLE GATE
// ================================================================

class UserRoleGate extends StatelessWidget {
  const UserRoleGate({super.key});

  static const String adminEmail =
      'md.mojidul.haque.1234@gmail.com';

  // ============================================================
  // CHECK ADMIN
  // ============================================================

  Future<bool> _isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return false;
    }

    final email = user.email?.trim().toLowerCase();

    if (email == adminEmail.toLowerCase()) {
      return true;
    }

    try {
      final document = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!document.exists) {
        return false;
      }

      final data = document.data();

      final role = data?['role']
          ?.toString()
          .trim()
          .toLowerCase();

      return role == 'admin';
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAdmin(),

      builder: (
        context,
        snapshot,
      ) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const SplashScreen();
        }

        if (snapshot.data == true) {
          return const AdminDashboardScreen();
        }

        return const HomeScreen();
      },
    );
  }
}

// ================================================================
// SPLASH SCREEN
// ================================================================

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,

      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Icon(
              Icons.people_alt_rounded,
              size: 85,
              color: Colors.blue,
            ),

            SizedBox(height: 20),

            Text(
              'বন্ধু সোশ্যাল',

              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 25),

            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

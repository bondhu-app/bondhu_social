import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const BondhuApp());
}

class BondhuApp extends StatelessWidget {
  const BondhuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bondhu Social',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const PhoneLoginPage(),
    );
  }
}

class PhoneLoginPage extends StatefulWidget {
  const PhoneLoginPage({super.key});

  @override
  State<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends State<PhoneLoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController phoneController =
      TextEditingController(text: '+8801790090435');

  final TextEditingController otpController =
      TextEditingController();

  String verificationId = '';
  bool otpSent = false;
  bool loading = false;
  String message = '';

  Future<void> sendOTP() async {
    final phone = phoneController.text.trim();

    if (phone.isEmpty) {
      setState(() {
        message = 'মোবাইল নাম্বার দিন।';
      });
      return;
    }

    setState(() {
      loading = true;
      message = '';
    });

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);

          if (!mounted) return;

          setState(() {
            loading = false;
            message = 'Phone verification সফল হয়েছে।';
          });
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;

          setState(() {
            loading = false;
            message = e.message ?? 'OTP পাঠানো যায়নি।';
          });
        },
        codeSent: (String id, int? resendToken) {
          if (!mounted) return;

          setState(() {
            verificationId = id;
            otpSent = true;
            loading = false;
            message = 'OTP আপনার মোবাইলে পাঠানো হয়েছে।';
          });
        },
        codeAutoRetrievalTimeout: (String id) {
          verificationId = id;
        },
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        message = 'সমস্যা হয়েছে: $e';
      });
    }
  }

  Future<void> verifyOTP() async {
    final otp = otpController.text.trim();

    if (otp.isEmpty) {
      setState(() {
        message = 'OTP দিন।';
      });
      return;
    }

    if (verificationId.isEmpty) {
      setState(() {
        message = 'আগে OTP পাঠান।';
      });
      return;
    }

    setState(() {
      loading = true;
      message = '';
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      await _auth.signInWithCredential(credential);

      if (!mounted) return;

      setState(() {
        loading = false;
        message = 'Login সফল হয়েছে।';
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        message = e.message ?? 'OTP সঠিক নয়।';
      });
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bondhu Social'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(
                  Icons.phone_android,
                  size: 80,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Bondhu Social',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'মোবাইল নাম্বার দিয়ে Login করুন',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'মোবাইল নাম্বার',
                    hintText: '+8801XXXXXXXXX',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: loading ? null : sendOTP,
                    child: loading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(),
                          )
                        : const Text(
                            'OTP পাঠান',
                            style: TextStyle(fontSize: 17),
                          ),
                  ),
                ),
                if (otpSent) ...[
                  const SizedBox(height: 24),
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'OTP',
                      hintText: '৬ সংখ্যার OTP দিন',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: loading ? null : verifyOTP,
                      child: loading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(),
                            )
                          : const Text(
                              'OTP Verify করুন',
                              style: TextStyle(fontSize: 17),
                            ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (message.isNotEmpty)
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

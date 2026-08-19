import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'revenue_service.dart';

class WalletService {
  WalletService._();

  static final WalletService instance =
      WalletService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // COLLECTION
  // ============================================================

  CollectionReference<Map<String, dynamic>>
      get _users {
    return _firestore.collection('users');
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get currentUser {
    return _auth.currentUser;
  }

  // ============================================================
  // USER WALLET STREAM
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      walletStream() {
    final user = _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _users
        .doc(user.uid)
        .snapshots();
  }

  // ============================================================
  // GET USER WALLET
  // ============================================================

  Future<double> getWalletBalance() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'প্রথমে Login করুন।',
      );
    }

    final document =
        await _users.doc(user.uid).get();

    final data =
        document.data() ?? {};

    return _toDouble(
      data['wallet'],
    );
  }

  // ============================================================
  // GET TOTAL EARNED
  // ============================================================

  Future<double> getTotalEarned() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'প্রথমে Login করুন।',
      );
    }

    final document =
        await _users.doc(user.uid).get();

    final data =
        document.data() ?? {};

    return _toDouble(
      data['totalEarned'],
    );
  }

  // ============================================================
  // ADD USER EARNING
  //
  // Example:
  //
  // Total earning = ৳100
  //
  // User gets 80%
  // Admin gets 20%
  //
  // User Wallet = ৳80
  // Owner Wallet = ৳20
  // ============================================================

  Future<void> addEarning({
    required double amount,
    required String source,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Earning পাওয়ার জন্য Login করুন।',
      );
    }

    if (amount <= 0) {
      throw Exception(
        'Earning amount অবশ্যই 0-এর বেশি হতে হবে।',
      );
    }

    await RevenueService.instance.addRevenue(
      totalAmount: amount,
      source: source,
    );
  }

  // ============================================================
  // INITIALIZE WALLET
  //
  // User-এর wallet না থাকলে 0 দিয়ে তৈরি করবে।
  // ============================================================

  Future<void> initializeWallet() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'প্রথমে Login করুন।',
      );
    }

    final userRef =
        _users.doc(user.uid);

    final document =
        await userRef.get();

    if (!document.exists) {
      await userRef.set(
        {
          'wallet': 0.0,
          'totalEarned': 0.0,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      return;
    }

    final data =
        document.data() ?? {};

    final updateData =
        <String, dynamic>{};

    if (!data.containsKey('wallet')) {
      updateData['wallet'] = 0.0;
    }

    if (!data.containsKey('totalEarned')) {
      updateData['totalEarned'] = 0.0;
    }

    if (updateData.isNotEmpty) {
      updateData['updatedAt'] =
          FieldValue.serverTimestamp();

      await userRef.update(
        updateData,
      );
    }
  }

  // ============================================================
  // NUMBER CONVERTER
  // ============================================================

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }
}

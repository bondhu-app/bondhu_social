import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RevenueService {
  RevenueService._();

  static final RevenueService instance =
      RevenueService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // ADMIN REVENUE SETTINGS
  // ============================================================

  static const double adminRevenuePercent = 20.0;

  // ============================================================
  // OWNER WALLET
  // ============================================================

  DocumentReference<Map<String, dynamic>>
      get _ownerWalletRef {
    return _firestore
        .collection('settings')
        .doc('owner_wallet');
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get currentUser =>
      _auth.currentUser;

  // ============================================================
  // CALCULATE ADMIN REVENUE
  // ============================================================

  double calculateAdminRevenue(
    double totalAmount,
  ) {
    if (totalAmount <= 0) {
      return 0;
    }

    return totalAmount *
        (adminRevenuePercent / 100);
  }

  // ============================================================
  // CALCULATE USER EARNING
  // ============================================================

  double calculateUserEarning(
    double totalAmount,
  ) {
    if (totalAmount <= 0) {
      return 0;
    }

    final adminRevenue =
        calculateAdminRevenue(
      totalAmount,
    );

    return totalAmount - adminRevenue;
  }

  // ============================================================
  // ADD REVENUE
  //
  // Example:
  // totalAmount = 100
  //
  // Admin = 20
  // User  = 80
  // ============================================================

  Future<void> addRevenue({
    required double totalAmount,
    required String source,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'প্রথমে User Login করুন।',
      );
    }

    if (totalAmount <= 0) {
      throw Exception(
        'Amount অবশ্যই 0-এর বেশি হতে হবে।',
      );
    }

    final adminRevenue =
        calculateAdminRevenue(
      totalAmount,
    );

    final userEarning =
        calculateUserEarning(
      totalAmount,
    );

    final userRef = _firestore
        .collection('users')
        .doc(user.uid);

    final revenueRef = _firestore
        .collection('revenue_transactions')
        .doc();

    await _firestore.runTransaction(
      (transaction) async {
        // ------------------------------------------------------
        // READ USER
        // ------------------------------------------------------

        final userSnapshot =
            await transaction.get(
          userRef,
        );

        final userData =
            userSnapshot.data() ?? {};

        final currentWallet =
            _toDouble(
          userData['wallet'],
        );

        final currentTotalEarned =
            _toDouble(
          userData['totalEarned'],
        );

        // ------------------------------------------------------
        // READ OWNER WALLET
        // ------------------------------------------------------

        final ownerSnapshot =
            await transaction.get(
          _ownerWalletRef,
        );

        final ownerData =
            ownerSnapshot.data() ?? {};

        final currentBalance =
            _toDouble(
          ownerData['balance'],
        );

        final currentTotalEarned =
            _toDouble(
          ownerData['totalEarned'],
        );

        // ------------------------------------------------------
        // NEW USER WALLET
        // ------------------------------------------------------

        final newUserWallet =
            currentWallet +
                userEarning;

        final newUserTotalEarned =
            currentTotalEarned +
                userEarning;

        // ------------------------------------------------------
        // NEW OWNER WALLET
        // ------------------------------------------------------

        final newOwnerBalance =
            currentBalance +
                adminRevenue;

        final newOwnerTotalEarned =
            currentTotalEarned +
                adminRevenue;

        // ------------------------------------------------------
        // UPDATE USER
        // ------------------------------------------------------

        transaction.set(
          userRef,
          {
            'wallet': newUserWallet,
            'totalEarned':
                newUserTotalEarned,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );

        // ------------------------------------------------------
        // UPDATE OWNER WALLET
        // ------------------------------------------------------

        transaction.set(
          _ownerWalletRef,
          {
            'balance':
                newOwnerBalance,
            'totalEarned':
                newOwnerTotalEarned,
            'totalPaidToUsers':
                _toDouble(
              ownerData[
                  'totalPaidToUsers'],
            ),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );

        // ------------------------------------------------------
        // REVENUE TRANSACTION
        // ------------------------------------------------------

        transaction.set(
          revenueRef,
          {
            'userId': user.uid,
            'totalAmount':
                totalAmount,
            'userAmount':
                userEarning,
            'adminAmount':
                adminRevenue,
            'adminPercent':
                adminRevenuePercent,
            'source': source,
            'createdAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }

  // ============================================================
  // ADMIN REVENUE STREAM
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      ownerWalletStream() {
    return _ownerWalletRef.snapshots();
  }

  // ============================================================
  // REVENUE TRANSACTIONS
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      revenueTransactionsStream() {
    return _firestore
        .collection(
          'revenue_transactions',
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots();
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

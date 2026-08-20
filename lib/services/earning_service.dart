import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EarningService {
  EarningService._();

  static final EarningService instance =
      EarningService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // REVENUE SPLIT
  // ============================================================

  // User পাবে 80%
  static const double userPercentage = 0.80;

  // Admin পাবে 20%
  static const double adminPercentage = 0.20;

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get currentUser =>
      _auth.currentUser;

  // ============================================================
  // MONEY
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

  // ============================================================
  // RECORD EARNING
  // ============================================================

  Future<void> recordEarning({
    required double amount,
    required String source,
    String? description,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Earning পেতে প্রথমে Login করুন।',
      );
    }

    if (amount <= 0) {
      throw Exception(
        'Earning amount 0-এর বেশি হতে হবে।',
      );
    }

    final cleanSource =
        source.trim().isEmpty
            ? 'unknown'
            : source.trim();

    final userRef = _firestore
        .collection('users')
        .doc(user.uid);

    final ownerWalletRef = _firestore
        .collection('settings')
        .doc('owner_wallet');

    final earningRef = _firestore
        .collection('earning_transactions')
        .doc();

    await _firestore.runTransaction(
      (transaction) async {
        // ------------------------------------------------------
        // READ USER
        // ------------------------------------------------------

        final userSnapshot =
            await transaction.get(userRef);

        final userData =
            userSnapshot.data() ?? {};

        // ------------------------------------------------------
        // READ OWNER WALLET
        // ------------------------------------------------------

        final ownerSnapshot =
            await transaction.get(
          ownerWalletRef,
        );

        final ownerData =
            ownerSnapshot.data() ?? {};

        // ------------------------------------------------------
        // CALCULATE
        // ------------------------------------------------------

        final userAmount =
            double.parse(
          (amount * userPercentage)
              .toStringAsFixed(2),
        );

        final adminAmount =
            double.parse(
          (amount * adminPercentage)
              .toStringAsFixed(2),
        );

        // ------------------------------------------------------
        // OLD USER WALLET
        // ------------------------------------------------------

        final oldUserWallet =
            _toDouble(
          userData['wallet'],
        );

        final oldUserTotalEarned =
            _toDouble(
          userData['totalEarned'],
        );

        // ------------------------------------------------------
        // OLD OWNER WALLET
        // ------------------------------------------------------

        final oldOwnerBalance =
            _toDouble(
          ownerData['balance'],
        );

        final oldOwnerTotalEarned =
            _toDouble(
          ownerData['totalEarned'],
        );

        // ------------------------------------------------------
        // NEW VALUES
        // ------------------------------------------------------

        final newUserWallet =
            oldUserWallet +
                userAmount;

        final newUserTotalEarned =
            oldUserTotalEarned +
                userAmount;

        final newOwnerBalance =
            oldOwnerBalance +
                adminAmount;

        final newOwnerTotalEarned =
            oldOwnerTotalEarned +
                adminAmount;

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
          ownerWalletRef,
          {
            'balance': newOwnerBalance,
            'totalEarned':
                newOwnerTotalEarned,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );

        // ------------------------------------------------------
        // EARNING TRANSACTION
        // ------------------------------------------------------

        transaction.set(
          earningRef,
          {
            'userId': user.uid,
            'source': cleanSource,
            'description':
                description?.trim(),

            'grossAmount': amount,

            'userAmount':
                userAmount,

            'adminAmount':
                adminAmount,

            'userPercentage':
                userPercentage,

            'adminPercentage':
                adminPercentage,

            'status': 'completed',

            'createdAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }

  // ============================================================
  // OWNER WALLET STREAM
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      ownerWalletStream() {
    return _firestore
        .collection('settings')
        .doc('owner_wallet')
        .snapshots();
  }

  // ============================================================
  // EARNING TRANSACTIONS
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      earningTransactionsStream() {
    return _firestore
        .collection(
          'earning_transactions',
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .limit(100)
        .snapshots();
  }

  // ============================================================
  // USER EARNING TRANSACTIONS
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      currentUserEarningsStream() {
    final user = _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection(
          'earning_transactions',
        )
        .where(
          'userId',
          isEqualTo: user.uid,
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .limit(100)
        .snapshots();
  }
}

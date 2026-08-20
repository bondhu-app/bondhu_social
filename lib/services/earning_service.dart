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
  // SETTINGS
  // ============================================================

  // User-এর earning-এর কত শতাংশ Admin পাবে।
  // 20.0 = 20%
  static const double adminCommissionPercent = 20.0;

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get currentUser =>
      _auth.currentUser;

  // ============================================================
  // USER EARNING
  // ============================================================

  Future<void> addUserEarning({
    required double amount,
    String source = 'earning',
    String? description,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Earning পাওয়ার জন্য User Login করতে হবে।',
      );
    }

    if (amount <= 0) {
      throw Exception(
        'Earning amount 0-এর বেশি হতে হবে।',
      );
    }

    final userRef = _firestore
        .collection('users')
        .doc(user.uid);

    final ownerWalletRef = _firestore
        .collection('settings')
        .doc('owner_wallet');

    final earningRef = _firestore
        .collection('earnings')
        .doc();

    final userShare =
        amount *
        ((100 - adminCommissionPercent) / 100);

    final adminShare =
        amount *
        (adminCommissionPercent / 100);

    await _firestore.runTransaction(
      (transaction) async {
        // --------------------------------------------------------
        // READ USER
        // --------------------------------------------------------

        final userSnapshot =
            await transaction.get(userRef);

        final userData =
            userSnapshot.data() ?? {};

        final currentWallet =
            _toDouble(
          userData['wallet'],
        );

        // --------------------------------------------------------
        // READ OWNER WALLET
        // --------------------------------------------------------

        final ownerSnapshot =
            await transaction.get(
          ownerWalletRef,
        );

        final ownerData =
            ownerSnapshot.data() ?? {};

        final currentOwnerBalance =
            _toDouble(
          ownerData['balance'],
        );

        final currentTotalEarned =
            _toDouble(
          ownerData['totalEarned'],
        );

        // --------------------------------------------------------
        // UPDATE USER WALLET
        // --------------------------------------------------------

        transaction.set(
          userRef,
          {
            'wallet':
                currentWallet + userShare,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );

        // --------------------------------------------------------
        // UPDATE ADMIN / OWNER WALLET
        // --------------------------------------------------------

        transaction.set(
          ownerWalletRef,
          {
            'balance':
                currentOwnerBalance +
                    adminShare,
            'totalEarned':
                currentTotalEarned +
                    adminShare,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );

        // --------------------------------------------------------
        // SAVE EARNING HISTORY
        // --------------------------------------------------------

        transaction.set(
          earningRef,
          {
            'userId': user.uid,
            'source': source,
            'description':
                description ?? '',
            'grossAmount': amount,
            'userAmount': userShare,
            'adminAmount': adminShare,
            'adminCommissionPercent':
                adminCommissionPercent,
            'createdAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }

  // ============================================================
  // USER EARNING HISTORY
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      userEarningsStream() {
    final user = _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('earnings')
        .where(
          'userId',
          isEqualTo: user.uid,
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots();
  }

  // ============================================================
  // ADMIN REVENUE HISTORY
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      adminRevenueStream() {
    return _firestore
        .collection('earnings')
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots();
  }

  // ============================================================
  // ADMIN REVENUE TOTAL
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      ownerWalletStream() {
    return _firestore
        .collection('settings')
        .doc('owner_wallet')
        .snapshots();
  }

  // ============================================================
  // MONEY CONVERTER
  // ============================================================

  static double _toDouble(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }
}

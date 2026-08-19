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
  // FIRESTORE REFERENCES
  // ============================================================

  CollectionReference<Map<String, dynamic>>
      get _users =>
          _firestore.collection('users');

  DocumentReference<Map<String, dynamic>>
      get _revenue =>
          _firestore
              .collection('settings')
              .doc('revenue');

  DocumentReference<Map<String, dynamic>>
      get _ownerWallet =>
          _firestore
              .collection('settings')
              .doc('owner_wallet');

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get currentUser =>
      _auth.currentUser;

  // ============================================================
  // EARNING SPLIT
  //
  // Example:
  //
  // Generated = ৳100
  // User = ৳80
  // Admin = ৳20
  //
  // Default:
  // User 80%
  // Admin 20%
  // ============================================================

  static const double defaultUserPercentage = 0.80;

  static const double defaultAdminPercentage = 0.20;

  // ============================================================
  // CALCULATE USER SHARE
  // ============================================================

  double calculateUserAmount(
    double generatedAmount,
  ) {
    if (generatedAmount <= 0) {
      return 0;
    }

    return generatedAmount *
        defaultUserPercentage;
  }

  // ============================================================
  // CALCULATE ADMIN REVENUE
  // ============================================================

  double calculateAdminRevenue(
    double generatedAmount,
  ) {
    if (generatedAmount <= 0) {
      return 0;
    }

    return generatedAmount *
        defaultAdminPercentage;
  }

  // ============================================================
  // ADD EARNING
  //
  // This method:
  //
  // 1. Calculates User amount
  // 2. Calculates Admin revenue
  // 3. Adds User amount to User wallet
  // 4. Adds Admin revenue to Admin revenue
  // 5. Updates generated amount
  //
  // Example:
  //
  // generatedAmount = 100
  //
  // User wallet +80
  // Admin revenue +20
  // ============================================================

  Future<void> addEarning({
    required double generatedAmount,
    String? source,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Earning পেতে প্রথমে Login করুন।',
      );
    }

    if (generatedAmount <= 0) {
      throw Exception(
        'Earning amount অবশ্যই 0-এর বেশি হতে হবে।',
      );
    }

    final userRef =
        _users.doc(user.uid);

    final userAmount =
        calculateUserAmount(
      generatedAmount,
    );

    final adminRevenue =
        calculateAdminRevenue(
      generatedAmount,
    );

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

        // ------------------------------------------------------
        // CURRENT USER WALLET
        // ------------------------------------------------------

        final currentWallet =
            _toDouble(
          userData['walletBalance'],
        );

        // ------------------------------------------------------
        // CURRENT USER TOTAL EARNING
        // ------------------------------------------------------

        final currentTotalEarned =
            _toDouble(
          userData['totalEarned'],
        );

        // ------------------------------------------------------
        // READ REVENUE DOCUMENT
        // ------------------------------------------------------

        final revenueSnapshot =
            await transaction.get(
          _revenue,
        );

        final revenueData =
            revenueSnapshot.data() ?? {};

        // ------------------------------------------------------
        // CURRENT ADMIN REVENUE
        // ------------------------------------------------------

        final currentAdminRevenue =
            _toDouble(
          revenueData['adminRevenue'],
        );

        // ------------------------------------------------------
        // CURRENT GENERATED
        // ------------------------------------------------------

        final currentGenerated =
            _toDouble(
          revenueData['totalGenerated'],
        );

        // ------------------------------------------------------
        // CURRENT USER SHARE TOTAL
        // ------------------------------------------------------

        final currentUserShare =
            _toDouble(
          revenueData['totalUserEarnings'],
        );

        // ------------------------------------------------------
        // NEW VALUES
        // ------------------------------------------------------

        final newWallet =
            currentWallet +
                userAmount;

        final newUserTotalEarned =
            currentTotalEarned +
                userAmount;

        final newAdminRevenue =
            currentAdminRevenue +
                adminRevenue;

        final newGenerated =
            currentGenerated +
                generatedAmount;

        final newUserShare =
            currentUserShare +
                userAmount;

        // ------------------------------------------------------
        // UPDATE USER
        // ------------------------------------------------------

        transaction.set(
          userRef,
          {
            'walletBalance':
                newWallet,
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
        // UPDATE REVENUE
        // ------------------------------------------------------

        transaction.set(
          _revenue,
          {
            'adminRevenue':
                newAdminRevenue,
            'totalGenerated':
                newGenerated,
            'totalUserEarnings':
                newUserShare,
            'userPercentage':
                defaultUserPercentage,
            'adminPercentage':
                defaultAdminPercentage,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );

        // ------------------------------------------------------
        // UPDATE OWNER WALLET
        //
        // Admin revenue is added to owner wallet.
        // ------------------------------------------------------

        final ownerSnapshot =
            await transaction.get(
          _ownerWallet,
        );

        final ownerData =
            ownerSnapshot.data() ?? {};

        final currentOwnerBalance =
            _toDouble(
          ownerData['balance'],
        );

        final currentOwnerEarned =
            _toDouble(
          ownerData['totalEarned'],
        );

        final newOwnerBalance =
            currentOwnerBalance +
                adminRevenue;

        final newOwnerEarned =
            currentOwnerEarned +
                adminRevenue;

        transaction.set(
          _ownerWallet,
          {
            'balance':
                newOwnerBalance,
            'totalEarned':
                newOwnerEarned,
            'totalPaidToUsers':
                _toDouble(
              ownerData[
                'totalPaidToUsers'
              ],
            ),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );

        // ------------------------------------------------------
        // EARNING HISTORY
        // ------------------------------------------------------

        final historyRef =
            _firestore
                .collection('earning_history')
                .doc();

        transaction.set(
          historyRef,
          {
            'userId':
                user.uid,
            'generatedAmount':
                generatedAmount,
            'userAmount':
                userAmount,
            'adminRevenue':
                adminRevenue,
            'source':
                source ?? 'app',
            'createdAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }

  // ============================================================
  // REVENUE STREAM
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      revenueStream() {
    return _revenue.snapshots();
  }

  // ============================================================
  // OWNER WALLET STREAM
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      ownerWalletStream() {
    return _ownerWallet.snapshots();
  }

  // ============================================================
  // USER WALLET STREAM
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      userWalletStream(
    String userId,
  ) {
    return _users
        .doc(userId)
        .snapshots();
  }

  // ============================================================
  // GET USER WALLET
  // ============================================================

  Future<double> getUserWallet(
    String userId,
  ) async {
    final doc =
        await _users.doc(userId).get();

    final data =
        doc.data() ?? {};

    return _toDouble(
      data['walletBalance'],
    );
  }

  // ============================================================
  // GET ADMIN REVENUE
  // ============================================================

  Future<double> getAdminRevenue() async {
    final doc =
        await _revenue.get();

    final data =
        doc.data() ?? {};

    return _toDouble(
      data['adminRevenue'],
    );
  }

  // ============================================================
  // GET OWNER WALLET
  // ============================================================

  Future<double> getOwnerWallet() async {
    final doc =
        await _ownerWallet.get();

    final data =
        doc.data() ?? {};

    return _toDouble(
      data['balance'],
    );
  }

  // ============================================================
  // NUMBER CONVERTER
  // ============================================================

  double _toDouble(
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

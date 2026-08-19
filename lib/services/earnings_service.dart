import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EarningsService {
  EarningsService._();

  static final EarningsService instance =
      EarningsService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // COLLECTIONS
  // ============================================================

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _transactions =>
      _firestore.collection('transactions');

  DocumentReference<Map<String, dynamic>> get _ownerWallet =>
      _firestore.collection('settings').doc('owner_wallet');

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get currentUser => _auth.currentUser;

  // ============================================================
  // USER WALLET
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>> walletStream() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.error(
        Exception('প্রথমে লগইন করুন।'),
      );
    }

    return _users.doc(user.uid).snapshots();
  }

  Future<Map<String, dynamic>> getWallet() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'প্রথমে লগইন করুন।',
      );
    }

    final snapshot =
        await _users.doc(user.uid).get();

    final data =
        snapshot.data() ?? {};

    return {
      'balance':
          (data['balance'] as num?)?.toDouble() ?? 0.0,
      'totalEarned':
          (data['totalEarned'] as num?)?.toDouble() ?? 0.0,
      'totalWithdrawn':
          (data['totalWithdrawn'] as num?)?.toDouble() ?? 0.0,
    };
  }

  // ============================================================
  // CREATE WALLET
  // ============================================================

  Future<void> createWalletIfNeeded() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'প্রথমে লগইন করুন।',
      );
    }

    final userRef =
        _users.doc(user.uid);

    final snapshot =
        await userRef.get();

    final data =
        snapshot.data();

    if (data == null) {
      await userRef.set(
        {
          'name':
              user.displayName ?? 'বন্ধু',
          'email':
              user.email ?? '',
          'balance': 0.0,
          'totalEarned': 0.0,
          'totalWithdrawn': 0.0,
          'createdAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return;
    }

    final updates =
        <String, dynamic>{};

    if (!data.containsKey('balance')) {
      updates['balance'] = 0.0;
    }

    if (!data.containsKey('totalEarned')) {
      updates['totalEarned'] = 0.0;
    }

    if (!data.containsKey('totalWithdrawn')) {
      updates['totalWithdrawn'] = 0.0;
    }

    if (updates.isNotEmpty) {
      updates['updatedAt'] =
          FieldValue.serverTimestamp();

      await userRef.update(updates);
    }
  }

  // ============================================================
  // OWNER WALLET
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      ownerWalletStream() {
    return _ownerWallet.snapshots();
  }

  Future<void> createOwnerWalletIfNeeded() async {
    final snapshot =
        await _ownerWallet.get();

    if (!snapshot.exists) {
      await _ownerWallet.set(
        {
          'balance': 0.0,
          'totalEarned': 0.0,
          'totalPaidToUsers': 0.0,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
      );

      return;
    }

    final data =
        snapshot.data() ?? {};

    final updates =
        <String, dynamic>{};

    if (!data.containsKey('balance')) {
      updates['balance'] = 0.0;
    }

    if (!data.containsKey('totalEarned')) {
      updates['totalEarned'] = 0.0;
    }

    if (!data.containsKey('totalPaidToUsers')) {
      updates['totalPaidToUsers'] = 0.0;
    }

    if (updates.isNotEmpty) {
      updates['updatedAt'] =
          FieldValue.serverTimestamp();

      await _ownerWallet.update(updates);
    }
  }

  // ============================================================
  // USER TRANSACTIONS
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      myTransactionsStream() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.error(
        Exception('প্রথমে লগইন করুন।'),
      );
    }

    return _transactions
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
  // ADD EARNING
  // ============================================================

  Future<void> addEarning({
    required double amount,
    required String type,
    String? description,
    String? referenceId,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'প্রথমে লগইন করুন।',
      );
    }

    if (amount <= 0) {
      throw Exception(
        'Amount অবশ্যই 0-এর বেশি হতে হবে।',
      );
    }

    final userRef =
        _users.doc(user.uid);

    final ownerRef =
        _ownerWallet;

    final transactionRef =
        _transactions.doc();

    await _firestore.runTransaction(
      (transaction) async {
        final userSnapshot =
            await transaction.get(userRef);

        final ownerSnapshot =
            await transaction.get(ownerRef);

        final userData =
            userSnapshot.data() ?? {};

        final ownerData =
            ownerSnapshot.data() ?? {};

        final currentBalance =
            (userData['balance'] as num?)
                    ?.toDouble() ??
                0.0;

        final currentTotalEarned =
            (userData['totalEarned'] as num?)
                    ?.toDouble() ??
                0.0;

        final ownerBalance =
            (ownerData['balance'] as num?)
                    ?.toDouble() ??
                0.0;

        final ownerTotalEarned =
            (ownerData['totalEarned'] as num?)
                    ?.toDouble() ??
                0.0;

        // User wallet
        transaction.set(
          userRef,
          {
            'balance':
                currentBalance + amount,
            'totalEarned':
                currentTotalEarned + amount,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        // Owner wallet
        transaction.set(
          ownerRef,
          {
            'balance':
                ownerBalance - amount,
            'totalEarned':
                ownerTotalEarned,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        // Transaction history
        transaction.set(
          transactionRef,
          {
            'userId': user.uid,
            'amount': amount,
            'type': type,
            'description':
                description ?? '',
            'referenceId':
                referenceId,
            'status': 'completed',
            'createdAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }

  // ============================================================
  // OWNER REVENUE
  // ============================================================

  Future<void> addOwnerRevenue({
    required double amount,
    required String type,
    String? description,
    String? referenceId,
  }) async {
    if (amount <= 0) {
      throw Exception(
        'Amount অবশ্যই 0-এর বেশি হতে হবে।',
      );
    }

    final ownerRef =
        _ownerWallet;

    final transactionRef =
        _transactions.doc();

    await _firestore.runTransaction(
      (transaction) async {
        final ownerSnapshot =
            await transaction.get(ownerRef);

        final ownerData =
            ownerSnapshot.data() ?? {};

        final currentBalance =
            (ownerData['balance'] as num?)
                    ?.toDouble() ??
                0.0;

        final currentTotalEarned =
            (ownerData['totalEarned'] as num?)
                    ?.toDouble() ??
                0.0;

        transaction.set(
          ownerRef,
          {
            'balance':
                currentBalance + amount,
            'totalEarned':
                currentTotalEarned + amount,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        transaction.set(
          transactionRef,
          {
            'userId': null,
            'amount': amount,
            'type': type,
            'description':
                description ?? '',
            'referenceId':
                referenceId,
            'status': 'completed',
            'ownerTransaction': true,
            'createdAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }

  // ============================================================
  // WITHDRAW REQUEST
  // ============================================================

  Future<void> createWithdrawRequest({
    required double amount,
    required String method,
    required String account,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'প্রথমে লগইন করুন।',
      );
    }

    if (amount <= 0) {
      throw Exception(
        'Withdraw amount সঠিক নয়।',
      );
    }

    if (method.trim().isEmpty) {
      throw Exception(
        'Payment method নির্বাচন করুন।',
      );
    }

    if (account.trim().isEmpty) {
      throw Exception(
        'Payment account দিন।',
      );
    }

    final userRef =
        _users.doc(user.uid);

    final withdrawRef =
        _firestore
            .collection('withdraw_requests')
            .doc();

    await _firestore.runTransaction(
      (transaction) async {
        final userSnapshot =
            await transaction.get(userRef);

        final userData =
            userSnapshot.data() ?? {};

        final balance =
            (userData['balance'] as num?)
                    ?.toDouble() ??
                0.0;

        if (balance < amount) {
          throw Exception(
            'আপনার Wallet-এ পর্যাপ্ত টাকা নেই।',
          );
        }

        final totalWithdrawn =
            (userData['totalWithdrawn'] as num?)
                    ?.toDouble() ??
                0.0;

        transaction.update(
          userRef,
          {
            'balance':
                balance - amount,
            'totalWithdrawn':
                totalWithdrawn + amount,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );

        transaction.set(
          withdrawRef,
          {
            'userId': user.uid,
            'amount': amount,
            'method': method.trim(),
            'account': account.trim(),
            'status': 'pending',
            'createdAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }

  // ============================================================
  // WITHDRAW REQUESTS
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      myWithdrawRequestsStream() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.error(
        Exception('প্রথমে লগইন করুন।'),
      );
    }

    return _firestore
        .collection('withdraw_requests')
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
}

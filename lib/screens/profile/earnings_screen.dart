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

  CollectionReference<Map<String, dynamic>>
      get _withdrawRequests =>
          _firestore.collection('withdraw_requests');

  DocumentReference<Map<String, dynamic>> get _ownerWallet =>
      _firestore
          .collection('settings')
          .doc('owner_wallet');

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get currentUser => _auth.currentUser;

  // ============================================================
  // USER WALLET STREAM
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      walletStream() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.error(
        Exception('প্রথমে লগইন করুন।'),
      );
    }

    return _users
        .doc(user.uid)
        .snapshots();
  }

  // ============================================================
  // GET WALLET
  // ============================================================

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
          _toDouble(data['balance']),
      'totalEarned':
          _toDouble(data['totalEarned']),
      'totalWithdrawn':
          _toDouble(data['totalWithdrawn']),
    };
  }

  // ============================================================
  // CREATE USER WALLET
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
  // OWNER WALLET STREAM
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      ownerWalletStream() {
    return _ownerWallet.snapshots();
  }

  // ============================================================
  // CREATE OWNER WALLET
  // ============================================================

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
  // MY TRANSACTIONS
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
            await transaction.get(
          userRef,
        );

        final ownerSnapshot =
            await transaction.get(
          ownerRef,
        );

        if (!userSnapshot.exists) {
          throw Exception(
            'User Profile পাওয়া যায়নি।',
          );
        }

        final userData =
            userSnapshot.data() ?? {};

        final ownerData =
            ownerSnapshot.data() ?? {};

        final currentBalance =
            _toDouble(
          userData['balance'],
        );

        final currentTotalEarned =
            _toDouble(
          userData['totalEarned'],
        );

        final ownerBalance =
            _toDouble(
          ownerData['balance'],
        );

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

        transaction.set(
          ownerRef,
          {
            'balance':
                ownerBalance - amount,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        transaction.set(
          transactionRef,
          {
            'userId':
                user.uid,
            'amount':
                amount,
            'type':
                type,
            'transactionType':
                'earning',
            'description':
                description ?? '',
            'referenceId':
                referenceId,
            'status':
                'completed',
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
            await transaction.get(
          ownerRef,
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
            'userId':
                null,
            'amount':
                amount,
            'type':
                type,
            'transactionType':
                'owner_revenue',
            'description':
                description ?? '',
            'referenceId':
                referenceId,
            'status':
                'completed',
            'ownerTransaction':
                true,
            'createdAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }

  // ============================================================
  // CREATE WITHDRAW REQUEST
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

    final cleanMethod =
        method.trim();

    final cleanAccount =
        account.trim();

    if (cleanMethod.isEmpty) {
      throw Exception(
        'Payment method নির্বাচন করুন।',
      );
    }

    if (cleanAccount.isEmpty) {
      throw Exception(
        'Payment account দিন।',
      );
    }

    final userRef =
        _users.doc(user.uid);

    final withdrawRef =
        _withdrawRequests.doc();

    final transactionRef =
        _transactions.doc();

    await _firestore.runTransaction(
      (transaction) async {
        final userSnapshot =
            await transaction.get(
          userRef,
        );

        if (!userSnapshot.exists) {
          throw Exception(
            'User Profile পাওয়া যায়নি।',
          );
        }

        final userData =
            userSnapshot.data() ?? {};

        final balance =
            _toDouble(
          userData['balance'],
        );

        if (balance < amount) {
          throw Exception(
            'আপনার Wallet-এ পর্যাপ্ত টাকা নেই।',
          );
        }

        final totalWithdrawn =
            _toDouble(
          userData['totalWithdrawn'],
        );

        // --------------------------------------------------------
        // Deduct wallet
        // --------------------------------------------------------

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

        // --------------------------------------------------------
        // Withdraw request
        // --------------------------------------------------------

        transaction.set(
          withdrawRef,
          {
            'userId':
                user.uid,
            'amount':
                amount,
            'method':
                cleanMethod,
            'account':
                cleanAccount,
            'status':
                'pending',
            'createdAt':
                FieldValue.serverTimestamp(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );

        // --------------------------------------------------------
        // Transaction history
        // --------------------------------------------------------

        transaction.set(
          transactionRef,
          {
            'userId':
                user.uid,
            'amount':
                amount,
            'type':
                'Withdraw',
            'transactionType':
                'withdrawal',
            'description':
                '$cleanMethod withdrawal request',
            'referenceId':
                withdrawRef.id,
            'status':
                'pending',
            'createdAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }

  // ============================================================
  // CANCEL WITHDRAW REQUEST
  // ============================================================

  Future<void> cancelWithdrawRequest(
    String requestId,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'প্রথমে লগইন করুন।',
      );
    }

    if (requestId.trim().isEmpty) {
      throw Exception(
        'Withdraw Request ID পাওয়া যায়নি।',
      );
    }

    final userRef =
        _users.doc(user.uid);

    final withdrawRef =
        _withdrawRequests.doc(
      requestId,
    );

    final transactionRef =
        _transactions.doc();

    await _firestore.runTransaction(
      (transaction) async {
        final userSnapshot =
            await transaction.get(
          userRef,
        );

        final withdrawSnapshot =
            await transaction.get(
          withdrawRef,
        );

        if (!withdrawSnapshot.exists) {
          throw Exception(
            'Withdraw Request পাওয়া যায়নি।',
          );
        }

        final withdrawData =
            withdrawSnapshot.data() ?? {};

        if (withdrawData['userId'] !=
            user.uid) {
          throw Exception(
            'এই Withdraw Request বাতিল করার অনুমতি নেই।',
          );
        }

        final status =
            withdrawData['status']
                ?.toString();

        if (status != 'pending') {
          throw Exception(
            'শুধু Pending Request বাতিল করা যাবে।',
          );
        }

        if (!userSnapshot.exists) {
          throw Exception(
            'User Profile পাওয়া যায়নি।',
          );
        }

        final userData =
            userSnapshot.data() ?? {};

        final currentBalance =
            _toDouble(
          userData['balance'],
        );

        final amount =
            _toDouble(
          withdrawData['amount'],
        );

        final currentTotalWithdrawn =
            _toDouble(
          userData['totalWithdrawn'],
        );

        final newTotalWithdrawn =
            currentTotalWithdrawn >= amount
                ? currentTotalWithdrawn - amount
                : 0.0;

        // --------------------------------------------------------
        // Return money to wallet
        // --------------------------------------------------------

        transaction.update(
          userRef,
          {
            'balance':
                currentBalance + amount,
            'totalWithdrawn':
                newTotalWithdrawn,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );

        // --------------------------------------------------------
        // Mark request cancelled
        // --------------------------------------------------------

        transaction.update(
          withdrawRef,
          {
            'status':
                'cancelled',
            'cancelledAt':
                FieldValue.serverTimestamp(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );

        // --------------------------------------------------------
        // Cancellation transaction
        // --------------------------------------------------------

        transaction.set(
          transactionRef,
          {
            'userId':
                user.uid,
            'amount':
                amount,
            'type':
                'Withdraw Cancelled',
            'transactionType':
                'withdrawal_cancelled',
            'description':
                'Withdraw request cancelled and money returned',
            'referenceId':
                requestId,
            'status':
                'completed',
            'createdAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }

  // ============================================================
  // MY WITHDRAW REQUESTS
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      myWithdrawRequestsStream() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.error(
        Exception(
          'প্রথমে লগইন করুন।',
        ),
      );
    }

    return _withdrawRequests
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
  // HELPER
  // ============================================================

  static double _toDouble(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }

    return 0.0;
  }
}

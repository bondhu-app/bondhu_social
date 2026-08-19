import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminEarningsService {
  AdminEarningsService._();

  static final AdminEarningsService instance =
      AdminEarningsService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _transactions =>
      _firestore.collection('transactions');

  CollectionReference<Map<String, dynamic>> get _withdrawRequests =>
      _firestore.collection('withdraw_requests');

  DocumentReference<Map<String, dynamic>> get _ownerWallet =>
      _firestore.collection('settings').doc('owner_wallet');

  User? get currentUser => _auth.currentUser;

  String? get currentUserId => _auth.currentUser?.uid;

  Future<bool> isAdmin() async {
    final user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    final snapshot =
        await _users.doc(user.uid).get();

    if (!snapshot.exists) {
      return false;
    }

    final data =
        snapshot.data() ?? {};

    return data['role'] == 'admin';
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>
      allWithdrawRequestsStream() {
    return _withdrawRequests
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>
      pendingWithdrawRequestsStream() {
    return _withdrawRequests
        .where(
          'status',
          isEqualTo: 'pending',
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>>
      getWithdrawRequest(
    String requestId,
  ) async {
    if (requestId.trim().isEmpty) {
      throw Exception(
        'Withdraw request ID পাওয়া যায়নি।',
      );
    }

    return _withdrawRequests
        .doc(requestId)
        .get();
  }

  Future<void> approveWithdraw(
    String requestId,
  ) async {
    final admin =
        _auth.currentUser;

    if (admin == null) {
      throw Exception(
        'প্রথমে Admin হিসেবে লগইন করুন।',
      );
    }

    final adminIsValid =
        await isAdmin();

    if (!adminIsValid) {
      throw Exception(
        'আপনার Admin permission নেই।',
      );
    }

    if (requestId.trim().isEmpty) {
      throw Exception(
        'Withdraw request ID দিন।',
      );
    }

    final withdrawRef =
        _withdrawRequests.doc(
      requestId,
    );

    await _firestore.runTransaction(
      (transaction) async {
        final withdrawSnapshot =
            await transaction.get(
          withdrawRef,
        );

        if (!withdrawSnapshot.exists) {
          throw Exception(
            'Withdraw request পাওয়া যায়নি।',
          );
        }

        final withdrawData =
            withdrawSnapshot.data() ?? {};

        final status =
            withdrawData['status']
                    ?.toString() ??
                '';

        if (status != 'pending') {
          throw Exception(
            'এই request আর pending নেই।',
          );
        }

        final userId =
            withdrawData['userId']
                    ?.toString() ??
                '';

        if (userId.isEmpty) {
          throw Exception(
            'Withdraw request-এর User ID পাওয়া যায়নি।',
          );
        }

        final amount =
            _toDouble(
          withdrawData['amount'],
        );

        if (amount <= 0) {
          throw Exception(
            'Withdraw amount সঠিক নয়।',
          );
        }

        final userRef =
            _users.doc(userId);

        final userSnapshot =
            await transaction.get(
          userRef,
        );

        if (!userSnapshot.exists) {
          throw Exception(
            'User profile পাওয়া যায়নি।',
          );
        }

        final ownerSnapshot =
            await transaction.get(
          _ownerWallet,
        );

        final ownerData =
            ownerSnapshot.data() ?? {};

        final ownerBalance =
            _toDouble(
          ownerData['balance'],
        );

        final totalPaidToUsers =
            _toDouble(
          ownerData['totalPaidToUsers'],
        );

        if (ownerBalance < amount) {
          throw Exception(
            'Owner Wallet-এ পর্যাপ্ত টাকা নেই।',
          );
        }

        transaction.set(
          _ownerWallet,
          {
            'balance':
                ownerBalance - amount,

            'totalPaidToUsers':
                totalPaidToUsers + amount,

            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );

        transaction.update(
          withdrawRef,
          {
            'status':
                'approved',

            'approvedBy':
                admin.uid,

            'approvedAt':
                FieldValue.serverTimestamp(),

            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );

        final transactionQuery =
            await _transactions
                .where(
                  'userId',
                  isEqualTo: userId,
                )
                .where(
                  'referenceId',
                  isEqualTo: requestId,
                )
                .limit(1)
                .get();

        if (transactionQuery.docs.isNotEmpty) {
          transaction.update(
            transactionQuery
                .docs
                .first
                .reference,
            {
              'status':
                  'approved',

              'approvedBy':
                  admin.uid,

              'approvedAt':
                  FieldValue.serverTimestamp(),

              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
          );
        }
      },
    );
  }

  Future<void> rejectWithdraw({
    required String requestId,
    String reason =
        'Withdraw request rejected',
  }) async {
    final admin =
        _auth.currentUser;

    if (admin == null) {
      throw Exception(
        'প্রথমে Admin হিসেবে লগইন করুন।',
      );
    }

    final adminIsValid =
        await isAdmin();

    if (!adminIsValid) {
      throw Exception(
        'আপনার Admin permission নেই।',
      );
    }

    if (requestId.trim().isEmpty) {
      throw Exception(
        'Withdraw request ID দিন।',
      );
    }

    final withdrawRef =
        _withdrawRequests.doc(
      requestId,
    );

    await _firestore.runTransaction(
      (transaction) async {
        final withdrawSnapshot =
            await transaction.get(
          withdrawRef,
        );

        if (!withdrawSnapshot.exists) {
          throw Exception(
            'Withdraw request পাওয়া যায়নি।',
          );
        }

        final withdrawData =
            withdrawSnapshot.data() ?? {};

        final status =
            withdrawData['status']
                    ?.toString() ??
                '';

        if (status != 'pending') {
          throw Exception(
            'এই request আর pending নেই।',
          );
        }

        final userId =
            withdrawData['userId']
                    ?.toString() ??
                '';

        if (userId.isEmpty) {
          throw Exception(
            'Withdraw request-এর User ID পাওয়া যায়নি।',
          );
        }

        final amount =
            _toDouble(
          withdrawData['amount'],
        );

        if (amount <= 0) {
          throw Exception(
            'Withdraw amount সঠিক নয়।',
          );
        }

        final userRef =
            _users.doc(userId);

        final userSnapshot =
            await transaction.get(
          userRef,
        );

        if (!userSnapshot.exists) {
          throw Exception(
            'User profile পাওয়া যায়নি।',
          );
        }

        final userData =
            userSnapshot.data() ?? {};

        final currentBalance =
            _toDouble(
          userData['balance'],
        );

        final currentTotalWithdrawn =
            _toDouble(
          userData['totalWithdrawn'],
        );

        final newTotalWithdrawn =
            currentTotalWithdrawn >= amount
                ? currentTotalWithdrawn - amount
                : 0.0;

        transaction.set(
          userRef,
          {
            'balance':
                currentBalance + amount,

            'totalWithdrawn':
                newTotalWithdrawn,

            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );

        final cleanReason =
            reason.trim().isEmpty
                ? 'Withdraw request rejected'
                : reason.trim();

        transaction.update(
          withdrawRef,
          {
            'status':
                'rejected',

            'rejectedBy':
                admin.uid,

            'rejectionReason':
                cleanReason,

            'rejectedAt':
                FieldValue.serverTimestamp(),

            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );

        final transactionQuery =
            await _transactions
                .where(
                  'userId',
                  isEqualTo: userId,
                )
                .where(
                  'referenceId',
                  isEqualTo: requestId,
                )
                .limit(1)
                .get();

        if (transactionQuery.docs.isNotEmpty) {
          transaction.update(
            transactionQuery
                .docs
                .first
                .reference,
            {
              'status':
                  'rejected',

              'rejectionReason':
                  cleanReason,

              'rejectedBy':
                  admin.uid,

              'rejectedAt':
                  FieldValue.serverTimestamp(),

              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
          );
        }
      },
    );
  }

  Future<void> deleteWithdrawRequest(
    String requestId,
  ) async {
    final admin =
        _auth.currentUser;

    if (admin == null) {
      throw Exception(
        'প্রথমে Admin হিসেবে লগইন করুন।',
      );
    }

    final adminIsValid =
        await isAdmin();

    if (!adminIsValid) {
      throw Exception(
        'আপনার Admin permission নেই।',
      );
    }

    if (requestId.trim().isEmpty) {
      throw Exception(
        'Withdraw request ID দিন।',
      );
    }

    final withdrawRef =
        _withdrawRequests.doc(
      requestId,
    );

    await _firestore.runTransaction(
      (transaction) async {
        final snapshot =
            await transaction.get(
          withdrawRef,
        );

        if (!snapshot.exists) {
          throw Exception(
            'Withdraw request পাওয়া যায়নি।',
          );
        }

        final data =
            snapshot.data() ?? {};

        final status =
            data['status']
                    ?.toString() ??
                '';

        if (status == 'pending') {
          throw Exception(
            'Pending request সরাসরি delete করা যাবে না। আগে Reject করুন।',
          );
        }

        transaction.delete(
          withdrawRef,
        );
      },
    );
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      ownerWalletStream() {
    return _ownerWallet.snapshots();
  }

  Future<Map<String, dynamic>>
      getOwnerWallet() async {
    final snapshot =
        await _ownerWallet.get();

    final data =
        snapshot.data() ?? {};

    return {
      'balance':
          _toDouble(
        data['balance'],
      ),
      'totalEarned':
          _toDouble(
        data['totalEarned'],
      ),
      'totalPaidToUsers':
          _toDouble(
        data['totalPaidToUsers'],
      ),
    };
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>
      allTransactionsStream() {
    return _transactions
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots();
  }

  Future<Map<String, dynamic>>
      getUserWallet(
    String userId,
  ) async {
    if (userId.trim().isEmpty) {
      throw Exception(
        'User ID পাওয়া যায়নি।',
      );
    }

    final snapshot =
        await _users.doc(userId).get();

    if (!snapshot.exists) {
      throw Exception(
        'User profile পাওয়া যায়নি।',
      );
    }

    final data =
        snapshot.data() ?? {};

    return {
      'balance':
          _toDouble(
        data['balance'],
      ),
      'totalEarned':
          _toDouble(
        data['totalEarned'],
      ),
      'totalWithdrawn':
          _toDouble(
        data['totalWithdrawn'],
      ),
    };
  }

  static double _toDouble(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(
            value,
          ) ??
          0.0;
    }

    return 0.0;
  }
}

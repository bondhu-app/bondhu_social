import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EarningsService {
  EarningsService._();

  static final EarningsService instance = EarningsService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static const double minimumWithdrawAmount = 100.0;
  static const double referralReward = 10.0;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _transactions =>
      _firestore.collection('transactions');

  CollectionReference<Map<String, dynamic>> get _withdrawRequests =>
      _firestore.collection('withdraw_requests');

  CollectionReference<Map<String, dynamic>> get _referralRewards =>
      _firestore.collection('referral_rewards');

  DocumentReference<Map<String, dynamic>> get _ownerWallet =>
      _firestore.collection('settings').doc('owner_wallet');

  User? get currentUser => _auth.currentUser;

  String? get currentUserId => _auth.currentUser?.uid;

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
      throw Exception('প্রথমে লগইন করুন।');
    }

    final snapshot = await _users.doc(user.uid).get();

    if (!snapshot.exists) {
      return {
        'balance': 0.0,
        'totalEarned': 0.0,
        'totalWithdrawn': 0.0,
      };
    }

    final data = snapshot.data() ?? {};

    return {
      'balance': _toDouble(data['balance']),
      'totalEarned': _toDouble(data['totalEarned']),
      'totalWithdrawn': _toDouble(data['totalWithdrawn']),
    };
  }

  Future<void> createWalletIfNeeded() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('প্রথমে লগইন করুন।');
    }

    final userRef = _users.doc(user.uid);

    final snapshot = await userRef.get();

    if (!snapshot.exists) {
      await userRef.set(
        {
          'name': user.displayName ?? 'বন্ধু',
          'email': user.email ?? '',
          'balance': 0.0,
          'totalEarned': 0.0,
          'totalWithdrawn': 0.0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return;
    }

    final data = snapshot.data() ?? {};
    final updates = <String, dynamic>{};

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

      await userRef.set(
        updates,
        SetOptions(merge: true),
      );
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      ownerWalletStream() {
    return _ownerWallet.snapshots();
  }

  Future<Map<String, dynamic>> getOwnerWallet() async {
    final snapshot = await _ownerWallet.get();

    final data = snapshot.data() ?? {};

    return {
      'balance': _toDouble(data['balance']),
      'totalEarned': _toDouble(data['totalEarned']),
      'totalPaidToUsers':
          _toDouble(data['totalPaidToUsers']),
    };
  }

  Future<void> createOwnerWalletIfNeeded() async {
    final snapshot = await _ownerWallet.get();

    if (!snapshot.exists) {
      await _ownerWallet.set(
        {
          'balance': 0.0,
          'totalEarned': 0.0,
          'totalPaidToUsers': 0.0,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      return;
    }

    final data = snapshot.data() ?? {};
    final updates = <String, dynamic>{};

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

      await _ownerWallet.set(
        updates,
        SetOptions(merge: true),
      );
    }
  }

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

  Future<void> addEarning({
    required double amount,
    required String type,
    String? description,
    String? referenceId,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('প্রথমে লগইন করুন।');
    }

    _validateAmount(amount);

    final cleanType = type.trim();

    if (cleanType.isEmpty) {
      throw Exception('Earning type দিন।');
    }

    throw Exception(
      'Earning যোগ করার জন্য Admin/System operation ব্যবহার করুন।',
    );
  }

  Future<void> addAdminReward({
    required String userId,
    required double amount,
    String description = 'Admin Reward',
    String? referenceId,
  }) async {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) {
      throw Exception('User ID পাওয়া যায়নি।');
    }

    _validateAmount(amount);

    final userRef = _users.doc(cleanUserId);
    final transactionRef = _transactions.doc();

    await _firestore.runTransaction(
      (transaction) async {
        final userSnapshot =
            await transaction.get(userRef);

        if (!userSnapshot.exists) {
          throw Exception(
            'User profile পাওয়া যায়নি।',
          );
        }

        final data =
            userSnapshot.data() ?? {};

        final balance =
            _toDouble(data['balance']);

        final totalEarned =
            _toDouble(data['totalEarned']);

        transaction.set(
          userRef,
          {
            'balance': balance + amount,
            'totalEarned':
                totalEarned + amount,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        transaction.set(
          transactionRef,
          {
            'userId': cleanUserId,
            'amount': amount,
            'type': 'admin_reward',
            'description':
                description.trim(),
            'referenceId': referenceId,
            'status': 'completed',
            'transactionType': 'earning',
            'createdAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }

  Future<void> processReferralReward({
    required String referralCode,
    required String newUserId,
  }) async {
    final code = referralCode.trim();
    final newUser = newUserId.trim();

    if (code.isEmpty) {
      return;
    }

    if (newUser.isEmpty) {
      throw Exception(
        'New User ID পাওয়া যায়নি।',
      );
    }

    final currentUser =
        _auth.currentUser;

    if (currentUser == null) {
      throw Exception(
        'প্রথমে লগইন করুন।',
      );
    }

    if (currentUser.uid != newUser) {
      throw Exception(
        'Referral reward শুধুমাত্র নতুন User-এর জন্য।',
      );
    }

    throw Exception(
      'Referral reward System/Admin operation দিয়ে process করতে হবে।',
    );
  }

  Future<void> addOwnerRevenue({
    required double amount,
    required String type,
    String? description,
    String? referenceId,
  }) async {
    _validateAmount(amount);

    final cleanType = type.trim();

    if (cleanType.isEmpty) {
      throw Exception(
        'Revenue type দিন।',
      );
    }

    throw Exception(
      'Owner revenue শুধুমাত্র Admin/System operation থেকে যোগ করা যাবে।',
    );
  }

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

    _validateAmount(amount);

    if (amount < minimumWithdrawAmount) {
      throw Exception(
        'Minimum Withdraw হলো ৳${minimumWithdrawAmount.toStringAsFixed(0)}।',
      );
    }

    final cleanMethod = method.trim();
    final cleanAccount = account.trim();

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

    const allowedMethods = [
      'bKash',
      'Nagad',
      'Rocket',
      'Bank',
    ];

    if (!allowedMethods.contains(cleanMethod)) {
      throw Exception(
        'Payment method সঠিক নয়।',
      );
    }

    if (cleanAccount.length < 5) {
      throw Exception(
        'Payment account সঠিক নয়।',
      );
    }

    final withdrawRef =
        _withdrawRequests.doc();

    await withdrawRef.set(
      {
        'userId': user.uid,
        'amount': amount,
        'method': cleanMethod,
        'account': cleanAccount,
        'status': 'pending',
        'createdAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
    );
  }

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

  Future<DocumentSnapshot<Map<String, dynamic>>>
      getWithdrawRequest(
    String requestId,
  ) async {
    final cleanId =
        requestId.trim();

    if (cleanId.isEmpty) {
      throw Exception(
        'Withdraw request ID পাওয়া যায়নি।',
      );
    }

    final snapshot =
        await _withdrawRequests
            .doc(cleanId)
            .get();

    if (!snapshot.exists) {
      throw Exception(
        'Withdraw request পাওয়া যায়নি।',
      );
    }

    final user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'প্রথমে লগইন করুন।',
      );
    }

    final data =
        snapshot.data() ?? {};

    if (data['userId'] != user.uid) {
      throw Exception(
        'এই request দেখার অনুমতি নেই।',
      );
    }

    return snapshot;
  }

  Future<void> cancelWithdrawRequest(
    String requestId,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'প্রথমে লগইন করুন।',
      );
    }

    final cleanId =
        requestId.trim();

    if (cleanId.isEmpty) {
      throw Exception(
        'Withdraw request ID দিন।',
      );
    }

    throw Exception(
      'Withdraw cancellation বর্তমানে Admin/System operation দিয়ে করতে হবে।',
    );
  }

  Future<bool> hasPendingWithdraw() async {
    final user =
        _auth.currentUser;

    if (user == null) {
      return false;
    }

    final snapshot =
        await _withdrawRequests
            .where(
              'userId',
              isEqualTo: user.uid,
            )
            .where(
              'status',
              isEqualTo: 'pending',
            )
            .limit(1)
            .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<double>
      getPendingWithdrawAmount() async {
    final user =
        _auth.currentUser;

    if (user == null) {
      return 0.0;
    }

    final snapshot =
        await _withdrawRequests
            .where(
              'userId',
              isEqualTo: user.uid,
            )
            .where(
              'status',
              isEqualTo: 'pending',
            )
            .get();

    double total = 0.0;

    for (final doc in snapshot.docs) {
      final data = doc.data();

      total += _toDouble(
        data['amount'],
      );
    }

    return total;
  }

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

  static void _validateAmount(
    double amount,
  ) {
    if (amount.isNaN ||
        amount.isInfinite) {
      throw Exception(
        'Amount সঠিক নয়।',
      );
    }

    if (amount <= 0) {
      throw Exception(
        'Amount অবশ্যই 0-এর বেশি হতে হবে।',
      );
    }
  }
}

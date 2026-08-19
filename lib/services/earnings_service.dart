import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EarningsService {
  EarningsService._();

  static final EarningsService instance = EarningsService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // SETTINGS
  // ============================================================

  static const double minimumWithdrawAmount = 100.0;

  static const double referralReward = 10.0;

  // ============================================================
  // COLLECTIONS
  // ============================================================

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

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get currentUser => _auth.currentUser;

  String? get currentUserId => _auth.currentUser?.uid;

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

    return _users.doc(user.uid).snapshots();
  }

  // ============================================================
  // GET USER WALLET
  // ============================================================

  Future<Map<String, dynamic>> getWallet() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('প্রথমে লগইন করুন।');
    }

    final snapshot = await _users.doc(user.uid).get();

    final data = snapshot.data() ?? {};

    return {
      'balance': _toDouble(data['balance']),
      'totalEarned': _toDouble(data['totalEarned']),
      'totalWithdrawn': _toDouble(data['totalWithdrawn']),
    };
  }

  // ============================================================
  // CREATE USER WALLET
  // ============================================================

  Future<void> createWalletIfNeeded() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('প্রথমে লগইন করুন।');
    }

    final userRef = _users.doc(user.uid);

    final snapshot = await userRef.get();

    if (!snapshot.exists) {
      await userRef.set({
        'name': user.displayName ?? 'বন্ধু',
        'email': user.email ?? '',
        'balance': 0.0,
        'totalEarned': 0.0,
        'totalWithdrawn': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

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
      updates['updatedAt'] = FieldValue.serverTimestamp();

      /*
       * IMPORTANT:
       *
       * Existing wallet fields are protected by Firestore Rules.
       * This method only attempts to add missing wallet fields.
       */
      await userRef.set(
        updates,
        SetOptions(merge: true),
      );
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
  // GET OWNER WALLET
  // ============================================================

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

  // ============================================================
  // CREATE OWNER WALLET
  // ============================================================

  Future<void> createOwnerWalletIfNeeded() async {
    final snapshot = await _ownerWallet.get();

    if (!snapshot.exists) {
      /*
       * Owner wallet is protected.
       * Only admin is allowed to create it.
       */
      await _ownerWallet.set({
        'balance': 0.0,
        'totalEarned': 0.0,
        'totalPaidToUsers': 0.0,
        'updatedAt': FieldValue.serverTimestamp(),
      });

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
  // ADD USER EARNING
  // ============================================================

  /*
   * SECURITY NOTE:
   *
   * এই function সাধারণ User-এর জন্য ব্যবহার করা যাবে না।
   *
   * Firestore Rules অনুযায়ী transaction এবং wallet পরিবর্তন
   * Admin / trusted backend থেকে করতে হবে।
   *
   * তাই normal client app থেকে কেউ নিজের balance বাড়াতে
   * পারবে না।
   */

  Future<void> addEarning({
    required double amount,
    required String type,
    String? description,
    String? referenceId,
  }) async {
    _validateAmount(amount);

    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('প্রথমে লগইন করুন।');
    }

    final cleanType = type.trim();

    if (cleanType.isEmpty) {
      throw Exception('Earning type দিন।');
    }

    /*
     * Intentionally blocked from normal client-side use.
     *
     * Wallet earning must be generated by a trusted backend
     * or Admin operation.
     */
    throw Exception(
      'Earning শুধুমাত্র Admin/Trusted Backend থেকে যোগ করা যাবে।',
    );
  }

  // ============================================================
  // ADMIN REWARD
  // ============================================================

  /*
   * এই method শুধু Admin-এর জন্য।
   *
   * Firestore Rules admin ছাড়া অন্য কাউকে wallet পরিবর্তন করতে
   * দেবে না।
   */

  Future<void> addAdminReward({
    required String userId,
    required double amount,
    String description = 'Admin Reward',
    String? referenceId,
  }) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('প্রথমে লগইন করুন।');
    }

    if (userId.trim().isEmpty) {
      throw Exception('User ID পাওয়া যায়নি।');
    }

    _validateAmount(amount);

    final userRef = _users.doc(userId);

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
            'totalEarned': totalEarned + amount,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        transaction.set(
          transactionRef,
          {
            'userId': userId,
            'amount': amount,
            'type': 'admin_reward',
            'description': description.trim(),
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

  // ============================================================
  // REFERRAL REWARD
  // ============================================================

  /*
   * Referral reward client-side থেকে wallet পরিবর্তন করতে পারবে না।
   *
   * এই method এখন security অনুযায়ী বন্ধ রাখা হয়েছে।
   *
   * পরে আমরা trusted backend / Admin flow দিয়ে referral reward
   * চালু করব।
   */

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

    final currentUser = _auth.currentUser;

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
      'Referral reward এখন Trusted Backend/Admin থেকে process হবে।',
    );
  }

  // ============================================================
  // OWNER REVENUE
  // ============================================================

  /*
   * Owner wallet শুধুমাত্র Admin/Trusted Backend থেকে পরিবর্তন
   * করা যাবে।
   */

  Future<void> addOwnerRevenue({
    required double amount,
    required String type,
    String? description,
    String? referenceId,
  }) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception(
        'প্রথমে লগইন করুন।',
      );
    }

    _validateAmount(amount);

    final cleanType = type.trim();

    if (cleanType.isEmpty) {
      throw Exception(
        'Revenue type দিন।',
      );
    }

    final ownerRef = _ownerWallet;

    final transactionRef = _transactions.doc();

    await _firestore.runTransaction(
      (transaction) async {
        final ownerSnapshot =
            await transaction.get(ownerRef);

        final ownerData =
            ownerSnapshot.data() ?? {};

        final currentBalance =
            _toDouble(ownerData['balance']);

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
            'userId': null,
            'amount': amount,
            'type': cleanType,
            'description':
                description?.trim() ?? '',
            'referenceId': referenceId,
            'status': 'completed',
            'transactionType':
                'owner_revenue',
            'ownerTransaction': true,
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

  /*
   * IMPORTANT:
   *
   * User এখন withdraw request তৈরি করবে।
   *
   * User-এর balance এই method-এ সরাসরি কমানো হচ্ছে না।
   *
   * কারণ client app-কে wallet balance পরিবর্তনের permission
   * দিলে user নিজের balance manipulate করতে পারবে।
   *
   * Admin request approve করার সময় trusted operation দিয়ে
   * balance কমানো হবে।
   */

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

    final userSnapshot =
        await _users.doc(user.uid).get();

    if (!userSnapshot.exists) {
      throw Exception(
        'User profile পাওয়া যায়নি।',
      );
    }

    final userData =
        userSnapshot.data() ?? {};

    final balance =
        _toDouble(userData['balance']);

    if (amount > balance) {
      throw Exception(
        'আপনার Wallet-এ পর্যাপ্ত টাকা নেই।',
      );
    }

    final withdrawRef =
        _withdrawRequests.doc();

    await withdrawRef.set({
      'userId': user.uid,
      'amount': amount,
      'method': cleanMethod,
      'account': cleanAccount,
      'status': 'pending',
      'createdAt':
          FieldValue.serverTimestamp(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
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
  // GET SINGLE WITHDRAW REQUEST
  // ============================================================

  Future<DocumentSnapshot<Map<String, dynamic>>>
      getWithdrawRequest(
    String requestId,
  ) async {
    final cleanId = requestId.trim();

    if (cleanId.isEmpty) {
      throw Exception(
        'Withdraw request ID পাওয়া যায়নি।',
      );
    }

    return _withdrawRequests.doc(cleanId).get();
  }

  // ============================================================
  // CANCEL WITHDRAW REQUEST
  // ============================================================

  /*
   * Current Firestore Rules অনুযায়ী User নিজে existing
   * withdraw request update করতে পারে না।
   *
   * তাই এই method এখন নিরাপত্তার কারণে blocked।
   *
   * পরের ধাপে Rules-এ নিরাপদ cancellation permission যোগ করব।
   */

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
        'Withdraw request ID দিন।',
      );
    }

    throw Exception(
      'Withdraw cancellation-এর নিরাপদ Rules এখনো সেট করা হয়নি।',
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }

    return 0.0;
  }

  static void _validateAmount(double amount) {
    if (amount.isNaN || amount.isInfinite) {
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

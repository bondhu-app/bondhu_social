import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/earnings_service.dart';

class AdminEarningsScreen extends StatefulWidget {
  const AdminEarningsScreen({super.key});

  @override
  State<AdminEarningsScreen> createState() =>
      _AdminEarningsScreenState();
}

class _AdminEarningsScreenState
    extends State<AdminEarningsScreen> {
  final EarningsService _earningsService =
      EarningsService.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final TextEditingController _userIdController =
      TextEditingController();

  final TextEditingController _amountController =
      TextEditingController();

  final TextEditingController _descriptionController =
      TextEditingController();

  bool _isProcessing = false;

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }

    return 0.0;
  }

  String _money(dynamic value) {
    return '৳${_toDouble(value).toStringAsFixed(2)}';
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      _ownerWalletStream() {
    return _firestore
        .collection('settings')
        .doc('owner_wallet')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _transactionsStream() {
    return _firestore
        .collection('transactions')
        .orderBy(
          'createdAt',
          descending: true,
        )
        .limit(50)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _usersStream() {
    return _firestore
        .collection('users')
        .snapshots();
  }

  @override
  void initState() {
    super.initState();
    _initializeOwnerWallet();
  }

  Future<void> _initializeOwnerWallet() async {
    try {
      await _earningsService
          .createOwnerWalletIfNeeded();
    } catch (_) {}
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addUserReward() async {
    FocusScope.of(context).unfocus();

    final userId =
        _userIdController.text.trim();

    final amountText =
        _amountController.text.trim();

    final description =
        _descriptionController.text.trim();

    if (userId.isEmpty) {
      _showMessage(
        'User ID দিন।',
        error: true,
      );
      return;
    }

    final amount =
        double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      _showMessage(
        'সঠিক Amount দিন।',
        error: true,
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await _earningsService.addAdminReward(
        userId: userId,
        amount: amount,
        description: description.isEmpty
            ? 'Admin Reward'
            : description,
      );

      if (!mounted) {
        return;
      }

      _userIdController.clear();
      _amountController.clear();
      _descriptionController.clear();

      _showMessage(
        'User-কে ${_money(amount)} Reward দেওয়া হয়েছে।',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text(
          'Admin Earnings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future<void>.delayed(
            const Duration(
              milliseconds: 500,
            ),
          );
        },
        child: ListView(
          padding:
              const EdgeInsets.all(16),
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildOwnerWallet(),
            const SizedBox(height: 16),
            _buildUserCount(),
            const SizedBox(height: 16),
            _buildRewardCard(),
            const SizedBox(height: 16),
            _buildTransactions(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 3,
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  child: Icon(
                    Icons.account_balance_wallet,
                    size: 30,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Admin Earnings',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'অ্যাপের আয়, Owner Wallet এবং User Reward এখান থেকে পরিচালনা করুন।',
              style: TextStyle(
                fontSize: 15,
                color:
                    Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerWallet() {
    return StreamBuilder<
        DocumentSnapshot<
            Map<String, dynamic>>>(
      stream:
          _ownerWalletStream(),
      builder: (
        context,
        snapshot,
      ) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding:
                  EdgeInsets.all(30),
              child: Center(
                child:
                    CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(16),
              child: Text(
                'Owner Wallet load করা যায়নি.\n${snapshot.error}',
              ),
            ),
          );
        }

        final data =
            snapshot.data?.data() ??
                {};

        final balance =
            _toDouble(data['balance']);

        final totalEarned =
            _toDouble(data['totalEarned']);

        final totalPaid =
            _toDouble(
          data['totalPaidToUsers'],
        );

        return Card(
          elevation: 4,
          child: Padding(
            padding:
                const EdgeInsets.all(20),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      size: 30,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Owner Wallet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  _money(balance),
                  style:
                      const TextStyle(
                    fontSize: 38,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'বর্তমান Owner Balance',
                  style: TextStyle(
                    color:
                        Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(
                      child: _statBox(
                        icon:
                            Icons.trending_up,
                        title:
                            'Total Revenue',
                        value:
                            _money(
                          totalEarned,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statBox(
                        icon:
                            Icons.payments,
                        title:
                            'Paid Users',
                        value:
                            _money(
                          totalPaid,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statBox({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(14),
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color:
              Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCount() {
    return StreamBuilder<
        QuerySnapshot<
            Map<String, dynamic>>>(
      stream: _usersStream(),
      builder: (
        context,
        snapshot,
      ) {
        final users =
            snapshot.data?.docs ??
                [];

        int admins = 0;

        for (final user in users) {
          final data =
              user.data();

          if (data['role'] ==
              'admin') {
            admins++;
          }
        }

        return Card(
          child: Padding(
            padding:
                const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 25,
                  child: Icon(
                    Icons.people,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Users',
                        style:
                            TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${users.length} জন User',
                      ),
                      Text(
                        '$admins জন Admin',
                        style:
                            TextStyle(
                          color: Colors
                              .grey
                              .shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${users.length}',
                  style:
                      const TextStyle(
                    fontSize: 28,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRewardCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                CircleAvatar(
                  child: Icon(
                    Icons.card_giftcard,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Give User Reward',
                  style:
                      TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Admin থেকে কোনো User-কে Reward দেওয়ার জন্য ব্যবহার করুন।',
              style: TextStyle(
                color:
                    Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller:
                  _userIdController,
              decoration:
                  const InputDecoration(
                labelText:
                    'User ID',
                hintText:
                    'যেমন: eEF4zV8Lm2dSVaTXX7zig3slPRC3',
                prefixIcon:
                    Icon(
                  Icons.person,
                ),
                border:
                    OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller:
                  _amountController,
              keyboardType:
                  const TextInputType
                      .numberWithOptions(
                decimal: true,
              ),
              decoration:
                  const InputDecoration(
                labelText:
                    'Amount',
                hintText:
                    'যেমন: 10',
                prefixIcon:
                    Icon(
                  Icons.account_balance_wallet,
                ),
                border:
                    OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller:
                  _descriptionController,
              decoration:
                  const InputDecoration(
                labelText:
                    'Description',
                hintText:
                    'যেমন: Referral Reward',
                prefixIcon:
                    Icon(
                  Icons.description,
                ),
                border:
                    OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width:
                  double.infinity,
              height: 52,
              child:
                  ElevatedButton.icon(
                onPressed:
                    _isProcessing
                        ? null
                        : _addUserReward,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth:
                              2,
                        ),
                      )
                    : const Icon(
                        Icons.add_card,
                      ),
                label: Text(
                  _isProcessing
                      ? 'Processing...'
                      : 'Give Reward',
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactions() {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                CircleAvatar(
                  child: Icon(
                    Icons.receipt_long,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Recent Transactions',
                  style:
                      TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            StreamBuilder<
                QuerySnapshot<
                    Map<String, dynamic>>>(
              stream:
                  _transactionsStream(),
              builder: (
                context,
                snapshot,
              ) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Padding(
                    padding:
                        EdgeInsets.all(20),
                    child: Center(
                      child:
                          CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding:
                        const EdgeInsets.all(
                      12,
                    ),
                    child: Text(
                      'Transaction load করা যায়নি.\n${snapshot.error}',
                    ),
                  );
                }

                final transactions =
                    snapshot.data?.docs ??
                        [];

                if (transactions
                    .isEmpty) {
                  return const Padding(
                    padding:
                        EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'এখনও কোনো Transaction নেই।',
                      ),
                    ),
                  );
                }

                return Column(
                  children:
                      transactions
                          .map(
                    (document) {
                      return _transactionItem(
                        document,
                      );
                    },
                  ).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _transactionItem(
    DocumentSnapshot<
        Map<String, dynamic>> document,
  ) {
    final data =
        document.data() ??
            {};

    final amount =
        _toDouble(
      data['amount'],
    );

    final type =
        data['type']
            ?.toString() ??
        'transaction';

    final description =
        data['description']
            ?.toString() ??
        '';

    final userId =
        data['userId']
            ?.toString() ??
        '';

    final status =
        data['status']
            ?.toString() ??
        '';

    final createdAt =
        data['createdAt'];

    String dateText =
        'সময় পাওয়া যায়নি';

    if (createdAt
        is Timestamp) {
      final date =
          createdAt.toDate();

      dateText =
          '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    }

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      padding:
          const EdgeInsets.all(12),
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color:
              Colors.grey.shade300,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            child: Icon(
              amount >= 0
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  description.isEmpty
                      ? type
                      : description,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (userId.isNotEmpty)
                  Text(
                    'User: $userId',
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        TextStyle(
                      fontSize: 12,
                      color: Colors
                          .grey
                          .shade700,
                    ),
                  ),
                const SizedBox(height: 3),
                Text(
                  dateText,
                  style:
                      TextStyle(
                    fontSize: 11,
                    color: Colors
                        .grey
                        .shade600,
                  ),
                ),
                if (status.isNotEmpty)
                  Text(
                    'Status: $status',
                    style:
                        TextStyle(
                      fontSize: 11,
                      color: Colors
                          .grey
                          .shade600,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _money(amount),
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminEarningsScreen extends StatefulWidget {
  const AdminEarningsScreen({super.key});

  @override
  State<AdminEarningsScreen> createState() =>
      _AdminEarningsScreenState();
}

class _AdminEarningsScreenState extends State<AdminEarningsScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  bool _loading = false;

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

  String _money(dynamic value) {
    return '৳${_toDouble(value).toStringAsFixed(2)}';
  }

  // ============================================================
  // OWNER WALLET
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      _ownerWalletStream() {
    return _firestore
        .collection('settings')
        .doc('owner_wallet')
        .snapshots();
  }

  // ============================================================
  // USERS
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _usersStream() {
    return _firestore
        .collection('users')
        .snapshots();
  }

  // ============================================================
  // WITHDRAW REQUESTS
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _withdrawStream() {
    return _firestore
        .collection('withdraw_requests')
        .snapshots();
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refreshData() async {
    if (_loading) {
      return;
    }

    setState(() {
      _loading = true;
    });

    await Future<void>.delayed(
      const Duration(milliseconds: 500),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),

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
        onRefresh: _refreshData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // ==================================================
            // HEADER
            // ==================================================

            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 32,
                      child: Icon(
                        Icons.account_balance_wallet,
                        size: 34,
                      ),
                    ),

                    const SizedBox(width: 15),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Earnings Management',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            'App-এর আয়, পেমেন্ট এবং Wallet পরিচালনা করুন।',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            // ==================================================
            // OWNER WALLET
            // ==================================================

            StreamBuilder<
                DocumentSnapshot<Map<String, dynamic>>>(
              stream: _ownerWalletStream(),
              builder: (
                context,
                snapshot,
              ) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(25),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _errorCard(
                    'Owner Wallet Load করতে সমস্যা হয়েছে',
                    snapshot.error.toString(),
                  );
                }

                final data =
                    snapshot.data?.data() ?? {};

                final balance =
                    _toDouble(data['balance']);

                final totalEarned =
                    _toDouble(data['totalEarned']);

                final totalPaid =
                    _toDouble(
                  data['totalPaidToUsers'],
                );

                return Column(
                  children: [
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding:
                            const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons
                                      .account_balance_wallet,
                                  size: 28,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Owner Wallet',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            const Text(
                              'Current Balance',
                              style: TextStyle(
                                fontSize: 13,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              _money(balance),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            icon: Icons.trending_up,
                            title: 'Total Revenue',
                            value:
                                _money(totalEarned),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: _statCard(
                            icon: Icons.payments,
                            title: 'Paid Users',
                            value:
                                _money(totalPaid),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 18),

            // ==================================================
            // USER WALLET TOTAL
            // ==================================================

            StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: _usersStream(),
              builder: (
                context,
                snapshot,
              ) {
                if (snapshot.hasError) {
                  return _errorCard(
                    'Users Load Error',
                    snapshot.error.toString(),
                  );
                }

                final users =
                    snapshot.data?.docs ?? [];

                double totalUserWallet = 0;
                int usersWithBalance = 0;

                for (final document in users) {
                  final data = document.data();

                  final wallet =
                      _toDouble(data['wallet']);

                  totalUserWallet += wallet;

                  if (wallet > 0) {
                    usersWithBalance++;
                  }
                }

                return Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.people),
                            SizedBox(width: 10),
                            Text(
                              'User Wallet Summary',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        Row(
                          children: [
                            Expanded(
                              child: _smallInfo(
                                title: 'Total Users',
                                value:
                                    '${users.length}',
                                icon:
                                    Icons.people,
                              ),
                            ),

                            Expanded(
                              child: _smallInfo(
                                title:
                                    'Wallet Users',
                                value:
                                    '$usersWithBalance',
                                icon:
                                    Icons
                                        .account_balance_wallet,
                              ),
                            ),

                            Expanded(
                              child: _smallInfo(
                                title:
                                    'User Balance',
                                value:
                                    _money(
                                  totalUserWallet,
                                ),
                                icon:
                                    Icons.payments,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 18),

            // ==================================================
            // WITHDRAW SUMMARY
            // ==================================================

            StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: _withdrawStream(),
              builder: (
                context,
                snapshot,
              ) {
                if (snapshot.hasError) {
                  return _errorCard(
                    'Withdraw Data Load Error',
                    snapshot.error.toString(),
                  );
                }

                final requests =
                    snapshot.data?.docs ?? [];

                int pending = 0;
                int approved = 0;
                int rejected = 0;

                double pendingAmount = 0;
                double approvedAmount = 0;
                double rejectedAmount = 0;

                for (final document in requests) {
                  final data =
                      document.data();

                  final status =
                      data['status']
                              ?.toString()
                              .toLowerCase() ??
                          'pending';

                  final amount =
                      _toDouble(
                    data['amount'],
                  );

                  if (status == 'pending') {
                    pending++;
                    pendingAmount += amount;
                  } else if (status == 'approved' ||
                      status == 'paid' ||
                      status == 'completed') {
                    approved++;
                    approvedAmount += amount;
                  } else if (status == 'rejected') {
                    rejected++;
                    rejectedAmount += amount;
                  }
                }

                return Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons
                                  .request_quote,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Withdraw Summary',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        _withdrawRow(
                          title: 'Pending',
                          count: pending,
                          amount:
                              pendingAmount,
                          icon:
                              Icons.pending_actions,
                        ),

                        const Divider(),

                        _withdrawRow(
                          title: 'Approved',
                          count: approved,
                          amount:
                              approvedAmount,
                          icon:
                              Icons.check_circle,
                        ),

                        const Divider(),

                        _withdrawRow(
                          title: 'Rejected',
                          count: rejected,
                          amount:
                              rejectedAmount,
                          icon:
                              Icons.cancel,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 18),

            // ==================================================
            // EARNING INFORMATION
            // ==================================================

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Earnings Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Owner Wallet-এর balance, totalEarned এবং totalPaidToUsers Firestore-এর settings/owner_wallet document থেকে নেওয়া হচ্ছে।',
                      style: TextStyle(
                        color:
                            Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'User Wallet-এর তথ্য users collection থেকে নেওয়া হচ্ছে।',
                      style: TextStyle(
                        color:
                            Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Withdraw-এর তথ্য withdraw_requests collection থেকে নেওয়া হচ্ছে।',
                      style: TextStyle(
                        color:
                            Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 18,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 26,
            ),

            const SizedBox(height: 7),

            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color:
                    Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SMALL INFO
  // ============================================================

  Widget _smallInfo({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 23,
        ),

        const SizedBox(height: 5),

        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color:
                Colors.grey.shade700,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // WITHDRAW ROW
  // ============================================================

  Widget _withdrawRow({
    required String title,
    required int count,
    required double amount,
    required IconData icon,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          child: Icon(
            icon,
            size: 20,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                '$count টি request',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),

        Text(
          _money(amount),
          style: const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ERROR CARD
  // ============================================================

  Widget _errorCard(
    String title,
    String error,
  ) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.error_outline,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    title,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              error,
              maxLines: 4,
              overflow:
                  TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

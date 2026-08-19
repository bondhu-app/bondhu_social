import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_earnings_screen.dart';
import 'admin_withdraw_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  // ============================================================
  // FIRESTORE
  // ============================================================

  FirebaseFirestore get _firestore =>
      FirebaseFirestore.instance;

  // ============================================================
  // MONEY
  // ============================================================

  String _money(dynamic value) {
    double amount = 0;

    if (value is num) {
      amount = value.toDouble();
    } else if (value is String) {
      amount = double.tryParse(value) ?? 0;
    }

    return '৳${amount.toStringAsFixed(2)}';
  }

  // ============================================================
  // DOUBLE
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
  // POSTS
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _postsStream() {
    return _firestore
        .collection('posts')
        .snapshots();
  }

  // ============================================================
  // PENDING WITHDRAWALS
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _pendingWithdrawalsStream() {
    return _firestore
        .collection('withdraw_requests')
        .where(
          'status',
          isEqualTo: 'pending',
        )
        .snapshots();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
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
          padding: const EdgeInsets.all(16),
          children: [
            // ==================================================
            // ADMIN HEADER
            // ==================================================

            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      child: Icon(
                        Icons.admin_panel_settings,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Admin Dashboard',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'অ্যাপের গুরুত্বপূর্ণ তথ্য পরিচালনা করুন',
                            style: TextStyle(
                              color:
                                  Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ==================================================
            // OWNER WALLET
            // ==================================================

            StreamBuilder<
                DocumentSnapshot<
                    Map<String, dynamic>>>(
              stream: _ownerWalletStream(),
              builder: (
                context,
                snapshot,
              ) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Card(
                    child: Padding(
                      padding:
                          EdgeInsets.all(20),
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
                        snapshot.error
                                .toString()
                                .replaceFirst(
                                  'Exception: ',
                                  '',
                                ),
                      ),
                    ),
                  );
                }

                final data =
                    snapshot.data?.data() ?? {};

                final balance =
                    _toDouble(
                  data['balance'],
                );

                final totalEarned =
                    _toDouble(
                  data['totalEarned'],
                );

                final totalPaid =
                    _toDouble(
                  data['totalPaidToUsers'],
                );

                return Card(
                  elevation: 3,
                  child: Padding(
                    padding:
                        const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              size: 28,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Owner Wallet',
                              style:
                                  TextStyle(
                                fontSize: 19,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        Text(
                          _money(balance),
                          style:
                              const TextStyle(
                            fontSize: 30,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 15),

                        Row(
                          children: [
                            Expanded(
                              child:
                                  _smallStat(
                                title:
                                    'Revenue',
                                value:
                                    _money(
                                  totalEarned,
                                ),
                                icon:
                                    Icons.trending_up,
                              ),
                            ),
                            Expanded(
                              child:
                                  _smallStat(
                                title:
                                    'Paid Users',
                                value:
                                    _money(
                                  totalPaid,
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

            const SizedBox(height: 15),

            // ==================================================
            // USERS
            // ==================================================

            StreamBuilder<
                QuerySnapshot<
                    Map<String, dynamic>>>(
              stream: _usersStream(),
              builder: (
                context,
                snapshot,
              ) {
                final count =
                    snapshot.data?.docs.length ??
                        0;

                return _dashboardTile(
                  icon:
                      Icons.people,
                  title:
                      'Users',
                  subtitle:
                      '$count জন User',
                  onTap: () {
                    _showInfoDialog(
                      context,
                      'Users',
                      'বর্তমানে মোট $count জন User রয়েছে।',
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 10),

            // ==================================================
            // POSTS
            // ==================================================

            StreamBuilder<
                QuerySnapshot<
                    Map<String, dynamic>>>(
              stream: _postsStream(),
              builder: (
                context,
                snapshot,
              ) {
                final count =
                    snapshot.data?.docs.length ??
                        0;

                return _dashboardTile(
                  icon:
                      Icons.article,
                  title:
                      'Posts',
                  subtitle:
                      '$count টি Post',
                  onTap: () {
                    _showInfoDialog(
                      context,
                      'Posts',
                      'বর্তমানে মোট $count টি Post রয়েছে।',
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 10),

            // ==================================================
            // WITHDRAW REQUESTS
            // ==================================================

            StreamBuilder<
                QuerySnapshot<
                    Map<String, dynamic>>>(
              stream:
                  _pendingWithdrawalsStream(),
              builder: (
                context,
                snapshot,
              ) {
                final count =
                    snapshot.data?.docs.length ??
                        0;

                return _dashboardTile(
                  icon:
                      Icons.pending_actions,
                  title:
                      'Withdraw Requests',
                  subtitle: count == 0
                      ? 'কোনো pending request নেই'
                      : '$count টি pending request',
                  trailing: count > 0
                      ? Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                Colors.orange,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              20,
                            ),
                          ),
                          child: Text(
                            '$count',
                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const AdminWithdrawScreen(),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 10),

            // ==================================================
            // EARNINGS & WITHDRAW
            // ==================================================

            _dashboardTile(
              icon:
                  Icons.account_balance,
              title:
                  'Earnings & Withdraw',
              subtitle:
                  'Owner wallet এবং earnings পরিচালনা',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const AdminEarningsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            // ==================================================
            // ALL WITHDRAW REQUESTS
            // ==================================================

            _dashboardTile(
              icon:
                  Icons.payments,
              title:
                  'Manage Withdrawals',
              subtitle:
                  'Approve অথবা Reject করুন',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const AdminWithdrawScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 18),

            // ==================================================
            // ADMIN SECURITY
            // ==================================================

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.security,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Admin Security',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'এই Dashboard-এর Admin কাজগুলো Firestore Rules-এর মাধ্যমে সুরক্ষিত রাখা হয়েছে।',
                      style: TextStyle(
                        color:
                            Colors.grey.shade700,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Admin role: admin',
                      style: TextStyle(
                        color:
                            Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SMALL STAT
  // ============================================================

  Widget _smallStat({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 25,
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DASHBOARD TILE
  // ============================================================

  Widget _dashboardTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 5,
        ),
        leading: CircleAvatar(
          child: Icon(
            icon,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
        ),
        trailing: trailing ??
            const Icon(
              Icons.arrow_forward_ios,
              size: 18,
            ),
        onTap: onTap,
      ),
    );
  }

  // ============================================================
  // INFO DIALOG
  // ============================================================

  void _showInfoDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'ঠিক আছে',
              ),
            ),
          ],
        );
      },
    );
  }
}

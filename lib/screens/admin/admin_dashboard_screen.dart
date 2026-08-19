import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin_earnings_screen.dart';
import 'admin_withdraw_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  FirebaseFirestore get _firestore =>
      FirebaseFirestore.instance;

  FirebaseAuth get _auth =>
      FirebaseAuth.instance;

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
  // REVENUE
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      _revenueStream() {
    return _firestore
        .collection('settings')
        .doc('revenue')
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
      backgroundColor: const Color(0xFFF0F2F5),

      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () {
              _logout(context);
            },
            icon: const Icon(
              Icons.logout,
            ),
          ),
        ],
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

            _adminHeader(),

            const SizedBox(height: 18),

            // ==================================================
            // FINANCIAL OVERVIEW
            // ==================================================

            const Text(
              'Financial Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            _financialOverview(),

            const SizedBox(height: 20),

            // ==================================================
            // PLATFORM STATISTICS
            // ==================================================

            const Text(
              'Platform Statistics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            _platformStatistics(),

            const SizedBox(height: 20),

            // ==================================================
            // MANAGEMENT
            // ==================================================

            const Text(
              'Management',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            _managementMenu(context),

            const SizedBox(height: 20),

            // ==================================================
            // SECURITY
            // ==================================================

            _securityCard(),

            const SizedBox(height: 20),

            // ==================================================
            // LOGOUT
            // ==================================================

            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  _logout(context);
                },
                icon: const Icon(
                  Icons.logout,
                ),
                label: const Text(
                  'Admin Logout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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
  // ADMIN HEADER
  // ============================================================

  Widget _adminHeader() {
    final user = _auth.currentUser;

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [

            const CircleAvatar(
              radius: 32,
              child: Icon(
                Icons.admin_panel_settings,
                size: 36,
              ),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  const Text(
                    'Admin Control Panel',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    user?.email ??
                        'Admin Account',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(20),
                      color:
                          Colors.green.withOpacity(0.12),
                    ),
                    child: const Text(
                      'ADMIN',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FINANCIAL OVERVIEW
  // ============================================================

  Widget _financialOverview() {
    return Column(
      children: [

        StreamBuilder<
            DocumentSnapshot<
                Map<String, dynamic>>>(
          stream: _ownerWalletStream(),
          builder: (
            context,
            snapshot,
          ) {
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

                _moneyCard(
                  title: 'Owner Wallet',
                  value: _money(balance),
                  icon:
                      Icons.account_balance_wallet,
                  subtitle:
                      'বর্তমান Admin wallet balance',
                ),

                const SizedBox(height: 10),

                Row(
                  children: [

                    Expanded(
                      child: _smallMoneyCard(
                        title: 'Total Revenue',
                        value:
                            _money(totalEarned),
                        icon:
                            Icons.trending_up,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: _smallMoneyCard(
                        title: 'Paid Users',
                        value:
                            _money(totalPaid),
                        icon:
                            Icons.payments,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 10),

        StreamBuilder<
            DocumentSnapshot<
                Map<String, dynamic>>>(
          stream: _revenueStream(),
          builder: (
            context,
            snapshot,
          ) {
            final data =
                snapshot.data?.data() ?? {};

            final adminRevenue =
                _toDouble(
              data['adminRevenue'],
            );

            final totalGenerated =
                _toDouble(
              data['totalGenerated'],
            );

            return Row(
              children: [

                Expanded(
                  child: _smallMoneyCard(
                    title: 'Admin Income',
                    value:
                        _money(adminRevenue),
                    icon:
                        Icons.monetization_on,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _smallMoneyCard(
                    title: 'Generated',
                    value:
                        _money(totalGenerated),
                    icon:
                        Icons.analytics,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // MONEY CARD
  // ============================================================

  Widget _moneyCard({
    required String title,
    required String value,
    required IconData icon,
    required String subtitle,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [

            CircleAvatar(
              radius: 27,
              child: Icon(
                icon,
                size: 28,
              ),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 27,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
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
    );
  }

  // ============================================================
  // SMALL MONEY CARD
  // ============================================================

  Widget _smallMoneyCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [

            Icon(
              icon,
              size: 28,
            ),

            const SizedBox(height: 7),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
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
  // PLATFORM STATISTICS
  // ============================================================

  Widget _platformStatistics() {
    return Column(
      children: [

        StreamBuilder<
            QuerySnapshot<
                Map<String, dynamic>>>(
          stream: _usersStream(),
          builder: (
            context,
            snapshot,
          ) {
            final count =
                snapshot.data?.docs.length ?? 0;

            return _statTile(
              icon: Icons.people,
              title: 'Users',
              subtitle:
                  '$count জন User',
              value: '$count',
            );
          },
        ),

        const SizedBox(height: 10),

        StreamBuilder<
            QuerySnapshot<
                Map<String, dynamic>>>(
          stream: _postsStream(),
          builder: (
            context,
            snapshot,
          ) {
            final count =
                snapshot.data?.docs.length ?? 0;

            return _statTile(
              icon: Icons.article,
              title: 'Posts',
              subtitle:
                  '$count টি Post',
              value: '$count',
            );
          },
        ),

        const SizedBox(height: 10),

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
                snapshot.data?.docs.length ?? 0;

            return _statTile(
              icon:
                  Icons.pending_actions,
              title:
                  'Pending Withdrawals',
              subtitle: count == 0
                  ? 'কোনো pending request নেই'
                  : '$count টি request অপেক্ষায়',
              value: '$count',
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // STAT TILE
  // ============================================================

  Widget _statTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
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
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MANAGEMENT MENU
  // ============================================================

  Widget _managementMenu(
    BuildContext context,
  ) {
    return Column(
      children: [

        _menuTile(
          icon: Icons.account_balance,
          title:
              'Earnings & Revenue',
          subtitle:
              'Admin Income এবং Owner Wallet',
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

        _menuTile(
          icon:
              Icons.account_balance_wallet,
          title:
              'Withdraw Management',
          subtitle:
              'User withdrawal approve অথবা reject',
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

        const SizedBox(height: 10),

        _menuTile(
          icon: Icons.people,
          title:
              'User Management',
          subtitle:
              'User account এবং তথ্য পরিচালনা',
          onTap: () {
            _showComingSoon(
              context,
              'User Management',
            );
          },
        ),

        const SizedBox(height: 10),

        _menuTile(
          icon: Icons.article,
          title:
              'Post Management',
          subtitle:
              'সব Post পরিচালনা',
          onTap: () {
            _showComingSoon(
              context,
              'Post Management',
            );
          },
        ),

        const SizedBox(height: 10),

        _menuTile(
          icon: Icons.settings,
          title:
              'App Settings',
          subtitle:
              'অ্যাপের earning এবং system settings',
          onTap: () {
            _showComingSoon(
              context,
              'App Settings',
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // MENU TILE
  // ============================================================

  Widget _menuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          radius: 25,
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
        ),
        onTap: onTap,
      ),
    );
  }

  // ============================================================
  // SECURITY
  // ============================================================

  Widget _securityCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
              'এই Dashboard শুধুমাত্র role = admin account-এর জন্য।',
              style: TextStyle(
                color:
                    Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Admin Role: admin',
              style: TextStyle(
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
  // COMING SOON
  // ============================================================

  void _showComingSoon(
    BuildContext context,
    String title,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: const Text(
            'এই Management section পরের ধাপে সম্পূর্ণভাবে চালু করা হবে।',
          ),
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

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout(
    BuildContext context,
  ) async {
    final shouldLogout =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Admin Logout',
          ),
          content: const Text(
            'আপনি কি Admin account থেকে Logout করতে চান?',
          ),
          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'না',
              ),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Logout',
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    await _auth.signOut();
  }
}

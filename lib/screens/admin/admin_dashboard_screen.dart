import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_earnings_screen.dart';
import 'admin_withdraw_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_notifications_screen.dart';
import 'user_details_screen.dart';
import 'post_details_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends State<AdminDashboardScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  bool _showUsers = false;
  bool _showPosts = false;

  String _userSearch = '';

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

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      _ownerWalletStream() {
    return _firestore
        .collection('settings')
        .doc('owner_wallet')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _usersStream() {
    return _firestore
        .collection('users')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _postsStream() {
    return _firestore
        .collection('posts')
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots();
  }

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

  void _openPage(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );
  }

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
            tooltip: 'Notifications',
            onPressed: () {
              _openPage(
                const AdminNotificationsScreen(),
              );
            },
            icon: const Icon(
              Icons.notifications_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () {
              _openPage(
                const AdminSettingsScreen(),
              );
            },
            icon: const Icon(
              Icons.settings_outlined,
            ),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          await Future<void>.delayed(
            const Duration(milliseconds: 500),
          );
        },

        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ==================================================
            // ADMIN HEADER
            // ==================================================

            Card(
              elevation: 4,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 34,
                      child: Icon(
                        Icons.admin_panel_settings,
                        size: 38,
                      ),
                    ),

                    const SizedBox(width: 15),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Admin Panel',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            'বন্ধু সোশ্যাল পরিচালনা কেন্দ্র',
                            style: TextStyle(
                              color:
                                  Colors.grey.shade700,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(
                                20,
                              ),
                              border: Border.all(
                                color: Colors.green,
                              ),
                            ),
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    FontWeight.bold,
                              ),
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
            // QUICK ADMIN MENU
            // ==================================================

            const Text(
              'Admin Controls',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.35,
              children: [
                _quickMenu(
                  icon: Icons.flag_outlined,
                  title: 'Reports',
                  subtitle: 'Reports দেখুন',
                  onTap: () {
                    _openPage(
                      const AdminReportsScreen(),
                    );
                  },
                ),

                _quickMenu(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Notification পাঠান',
                  onTap: () {
                    _openPage(
                      const AdminNotificationsScreen(),
                    );
                  },
                ),

                _quickMenu(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  subtitle: 'App Settings',
                  onTap: () {
                    _openPage(
                      const AdminSettingsScreen(),
                    );
                  },
                ),

                _quickMenu(
                  icon: Icons.account_balance_wallet,
                  title: 'Earnings',
                  subtitle: 'Income দেখুন',
                  onTap: () {
                    _openPage(
                      const AdminEarningsScreen(),
                    );
                  },
                ),
              ],
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
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child:
                            CircularProgressIndicator(),
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

                        const SizedBox(height: 15),

                        Text(
                          _money(balance),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 15),

                        Row(
                          children: [
                            Expanded(
                              child: _smallStat(
                                title: 'Revenue',
                                value:
                                    _money(
                                  totalEarned,
                                ),
                                icon:
                                    Icons.trending_up,
                              ),
                            ),
                            Expanded(
                              child: _smallStat(
                                title: 'Paid Users',
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
                final users =
                    snapshot.data?.docs ?? [];

                final filteredUsers =
                    users.where(
                  (document) {
                    if (_userSearch
                        .trim()
                        .isEmpty) {
                      return true;
                    }

                    final data =
                        document.data();

                    final name =
                        data['name']
                                ?.toString()
                                .toLowerCase() ??
                            '';

                    final email =
                        data['email']
                                ?.toString()
                                .toLowerCase() ??
                            '';

                    final username =
                        data['username']
                                ?.toString()
                                .toLowerCase() ??
                            '';

                    final search =
                        _userSearch
                            .trim()
                            .toLowerCase();

                    return name.contains(search) ||
                        email.contains(search) ||
                        username.contains(search);
                  },
                ).toList();

                return Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading:
                            const CircleAvatar(
                          child: Icon(
                            Icons.people,
                          ),
                        ),
                        title: const Text(
                          'Users',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${users.length} জন User',
                        ),
                        trailing: Icon(
                          _showUsers
                              ? Icons.expand_less
                              : Icons.expand_more,
                        ),
                        onTap: () {
                          setState(() {
                            _showUsers =
                                !_showUsers;
                          });
                        },
                      ),

                      if (_showUsers)
                        Padding(
                          padding:
                              const EdgeInsets
                                  .fromLTRB(
                            16,
                            0,
                            16,
                            16,
                          ),
                          child: Column(
                            children: [
                              TextField(
                                decoration:
                                    const InputDecoration(
                                  hintText:
                                      'User Search করুন...',
                                  prefixIcon:
                                      Icon(
                                    Icons.search,
                                  ),
                                  border:
                                      OutlineInputBorder(),
                                ),
                                onChanged:
                                    (value) {
                                  setState(() {
                                    _userSearch =
                                        value;
                                  });
                                },
                              ),

                              const SizedBox(
                                height: 12,
                              ),

                              ...filteredUsers
                                  .map(
                                (document) =>
                                    _userItem(
                                  document,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
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
                final posts =
                    snapshot.data?.docs ?? [];

                return Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading:
                            const CircleAvatar(
                          child: Icon(
                            Icons.article,
                          ),
                        ),
                        title: const Text(
                          'Posts',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${posts.length} টি Post',
                        ),
                        trailing: Icon(
                          _showPosts
                              ? Icons.expand_less
                              : Icons.expand_more,
                        ),
                        onTap: () {
                          setState(() {
                            _showPosts =
                                !_showPosts;
                          });
                        },
                      ),

                      if (_showPosts)
                        Padding(
                          padding:
                              const EdgeInsets
                                  .fromLTRB(
                            16,
                            0,
                            16,
                            16,
                          ),
                          child: Column(
                            children: [
                              ...posts
                                  .take(30)
                                  .map(
                                (document) =>
                                    _postItem(
                                  document,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            // ==================================================
            // WITHDRAW
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
                      ? CircleAvatar(
                          radius: 14,
                          child: Text(
                            '$count',
                            style:
                                const TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                  onTap: () {
                    _openPage(
                      const AdminWithdrawScreen(),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 10),

            _dashboardTile(
              icon: Icons.payments,
              title: 'Manage Withdrawals',
              subtitle:
                  'Approve অথবা Reject করুন',
              onTap: () {
                _openPage(
                  const AdminWithdrawScreen(),
                );
              },
            ),

            const SizedBox(height: 10),

            // ==================================================
            // REPORTS
            // ==================================================

            _dashboardTile(
              icon: Icons.flag_outlined,
              title: 'Admin Reports',
              subtitle:
                  'User Report এবং Post Report পরিচালনা করুন',
              onTap: () {
                _openPage(
                  const AdminReportsScreen(),
                );
              },
            ),

            const SizedBox(height: 10),

            // ==================================================
            // NOTIFICATIONS
            // ==================================================

            _dashboardTile(
              icon: Icons.notifications_outlined,
              title: 'Admin Notifications',
              subtitle:
                  'সব User-কে Notification পাঠান',
              onTap: () {
                _openPage(
                  const AdminNotificationsScreen(),
                );
              },
            ),

            const SizedBox(height: 10),

            // ==================================================
            // SETTINGS
            // ==================================================

            _dashboardTile(
              icon: Icons.settings_outlined,
              title: 'Admin Settings',
              subtitle:
                  'App এবং Admin Settings পরিচালনা করুন',
              onTap: () {
                _openPage(
                  const AdminSettingsScreen(),
                );
              },
            ),

            const SizedBox(height: 18),

            // ==================================================
            // SECURITY
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

                    const Text(
                      'Admin role: admin',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
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
  // QUICK MENU
  // ============================================================

  Widget _quickMenu({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 25,
                child: Icon(
                  icon,
                  size: 27,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // USER ITEM
  // ============================================================

  Widget _userItem(
    DocumentSnapshot<
        Map<String, dynamic>> document,
  ) {
    final data =
        document.data() ?? {};

    final name =
        data['name']?.toString() ??
            'নাম নেই';

    final email =
        data['email']?.toString() ??
            'Email নেই';

    final username =
        data['username']?.toString() ??
            '';

    final role =
        data['role']?.toString() ??
            'user';

    final photoUrl =
        data['photoUrl']?.toString();

    final wallet =
        _toDouble(
      data['wallet'],
    );

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 8,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage:
              photoUrl != null &&
                      photoUrl.isNotEmpty
                  ? NetworkImage(photoUrl)
                  : null,
          child:
              photoUrl == null ||
                      photoUrl.isEmpty
                  ? const Icon(
                      Icons.person,
                    )
                  : null,
        ),

        title: Text(
          name,
          style: const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        subtitle: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              email,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
            ),

            if (username.isNotEmpty)
              Text(
                '@$username',
              ),

            Text(
              'Wallet: ${_money(wallet)}',
            ),
          ],
        ),

        isThreeLine: true,

        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'details') {
              _openPage(
                UserDetailsScreen(
                  userId: document.id,
                ),
              );
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'details',
              child: Row(
                children: [
                  Icon(Icons.person),
                  SizedBox(width: 8),
                  Text('User Details'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // POST ITEM
  // ============================================================

  Widget _postItem(
    DocumentSnapshot<
        Map<String, dynamic>> document,
  ) {
    final data =
        document.data() ?? {};

    final userName =
        data['userName']?.toString() ??
            'বন্ধু';

    final text =
        data['text']?.toString() ??
            '';

    final likes =
        data['likeCount'] ?? 0;

    final comments =
        data['commentCount'] ?? 0;

    final shares =
        data['shareCount'] ?? 0;

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 8,
      ),
      child: ListTile(
        leading:
            const CircleAvatar(
          child: Icon(
            Icons.article,
          ),
        ),

        title: Text(
          userName,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        subtitle: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              text.isEmpty
                  ? 'কোনো Text নেই'
                  : text,
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
            ),

            const SizedBox(height: 5),

            Text(
              '👍 $likes   💬 $comments   ↗ $shares',
            ),
          ],
        ),

        isThreeLine: true,

        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'details') {
              _openPage(
                PostDetailsScreen(
                  postId: document.id,
                ),
              );
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'details',
              child: Row(
                children: [
                  Icon(Icons.article),
                  SizedBox(width: 8),
                  Text('Post Details'),
                ],
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
          style:
              const TextStyle(
            fontSize: 12,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          value,
          style:
              const TextStyle(
            fontSize: 15,
            fontWeight:
                FontWeight.bold,
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
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
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
}

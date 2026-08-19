import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_earnings_screen.dart';
import 'admin_withdraw_screen.dart';

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
  // POSTS
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _postsStream() {
    return _firestore
        .collection('posts')
        .snapshots();
  }

  // ============================================================
  // WITHDRAW
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
      backgroundColor:
          const Color(0xFFF0F2F5),

      appBar: AppBar(
        title: const Text(
          'ADMIN CONTROL PANEL',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ======================================================
          // ADMIN HEADER
          // ======================================================

          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [

                  const CircleAvatar(
                    radius: 42,
                    child: Icon(
                      Icons.admin_panel_settings,
                      size: 48,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'ADMIN CONTROL PANEL',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'বন্ধু সোশ্যাল অ্যাপ পরিচালনা করুন',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ======================================================
          // OWNER WALLET
          // ======================================================

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
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              }

              final data =
                  snapshot.data?.data() ?? {};

              final balance =
                  _toDouble(data['balance']);

              final revenue =
                  _toDouble(data['totalEarned']);

              final paid =
                  _toDouble(
                data['totalPaidToUsers'],
              );

              return Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(18),
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
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Text(
                        _money(balance),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      Row(
                        children: [

                          Expanded(
                            child: _moneyStat(
                              'Revenue',
                              _money(revenue),
                              Icons.trending_up,
                            ),
                          ),

                          Expanded(
                            child: _moneyStat(
                              'Paid Users',
                              _money(paid),
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

          // ======================================================
          // ADMIN CONTROL PANEL TITLE
          // ======================================================

          const Padding(
            padding: EdgeInsets.only(
              left: 4,
              bottom: 10,
            ),
            child: Text(
              'Admin Control Panel',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // ======================================================
          // USERS MANAGEMENT
          // ======================================================

          _controlTile(
            icon: Icons.people_alt,
            title: 'Users Management',
            subtitle:
                'সব User দেখুন এবং পরিচালনা করুন',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const UsersManagementScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          // ======================================================
          // POSTS MANAGEMENT
          // ======================================================

          _controlTile(
            icon: Icons.article,
            title: 'Posts Management',
            subtitle:
                'সব Post দেখুন এবং পরিচালনা করুন',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const PostsManagementScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          // ======================================================
          // APP STATISTICS
          // ======================================================

          _controlTile(
            icon: Icons.bar_chart,
            title: 'App Statistics',
            subtitle:
                'User, Post এবং App-এর পরিসংখ্যান',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const AppStatisticsScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          // ======================================================
          // ADMIN SECURITY
          // ======================================================

          _controlTile(
            icon: Icons.security,
            title: 'Admin Security',
            subtitle:
                'Admin account এবং security settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const AdminSecurityScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          // ======================================================
          // APP SETTINGS
          // ======================================================

          _controlTile(
            icon: Icons.settings,
            title: 'App Settings',
            subtitle:
                'অ্যাপের গুরুত্বপূর্ণ Settings পরিচালনা করুন',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const AppSettingsScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 18),

          // ======================================================
          // EARNINGS
          // ======================================================

          _controlTile(
            icon: Icons.account_balance,
            title: 'Earnings & Withdraw',
            subtitle:
                'Owner Wallet এবং Earnings পরিচালনা',
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

          // ======================================================
          // WITHDRAW
          // ======================================================

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

              return _controlTile(
                icon: Icons.payments,
                title: 'Manage Withdrawals',
                subtitle: count == 0
                    ? 'কোনো pending request নেই'
                    : '$count টি pending request আছে',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const AdminWithdrawScreen(),
                    ),
                  );
                },
                badge:
                    count > 0 ? '$count' : null,
              );
            },
          ),

          const SizedBox(height: 25),

          // ======================================================
          // SECURITY INFO
          // ======================================================

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  const Row(
                    children: [

                      Icon(
                        Icons.verified_user,
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

                  const SizedBox(height: 10),

                  Text(
                    'Admin Dashboard শুধুমাত্র Admin account-এর জন্য ব্যবহারযোগ্য।',
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
    );
  }

  // ============================================================
  // MONEY STAT
  // ============================================================

  Widget _moneyStat(
    String title,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [

        Icon(
          icon,
          size: 24,
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
            fontSize: 14,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CONTROL TILE
  // ============================================================

  Widget _controlTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),

        leading: CircleAvatar(
          radius: 25,
          child: Icon(
            icon,
            size: 25,
          ),
        ),

        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        subtitle: Padding(
          padding:
              const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
          ),
        ),

        trailing: badge != null
            ? Row(
                mainAxisSize:
                    MainAxisSize.min,
                children: [

                  Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration:
                        BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(
                        15,
                      ),
                      border:
                          Border.all(
                        color:
                            Colors.orange,
                      ),
                    ),
                    child: Text(
                      badge,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  const Icon(
                    Icons
                        .arrow_forward_ios,
                    size: 16,
                  ),
                ],
              )
            : const Icon(
                Icons.arrow_forward_ios,
                size: 17,
              ),

        onTap: onTap,
      ),
    );
  }
}

// ============================================================
// USERS MANAGEMENT SCREEN
// ============================================================

class UsersManagementScreen
    extends StatelessWidget {
  const UsersManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Users Management',
        ),
      ),
      body: StreamBuilder<
          QuerySnapshot<
              Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .snapshots(),
        builder: (
          context,
          snapshot,
        ) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final users =
              snapshot.data?.docs ?? [];

          if (users.isEmpty) {
            return const Center(
              child: Text(
                'কোনো User পাওয়া যায়নি।',
              ),
            );
          }

          return ListView.builder(
            padding:
                const EdgeInsets.all(12),
            itemCount: users.length,
            itemBuilder: (
              context,
              index,
            ) {
              final data =
                  users[index].data();

              final name =
                  data['name']
                          ?.toString() ??
                      'নাম নেই';

              final email =
                  data['email']
                          ?.toString() ??
                      'Email নেই';

              final role =
                  data['role']
                          ?.toString() ??
                      'user';

              return Card(
                child: ListTile(
                  leading:
                      const CircleAvatar(
                    child:
                        Icon(Icons.person),
                  ),
                  title: Text(
                    name,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  subtitle:
                      Text(email),
                  trailing: Text(
                    role,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================
// POSTS MANAGEMENT SCREEN
// ============================================================

class PostsManagementScreen
    extends StatelessWidget {
  const PostsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Posts Management',
        ),
      ),
      body: StreamBuilder<
          QuerySnapshot<
              Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .snapshots(),
        builder: (
          context,
          snapshot,
        ) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final posts =
              snapshot.data?.docs ?? [];

          if (posts.isEmpty) {
            return const Center(
              child: Text(
                'কোনো Post নেই।',
              ),
            );
          }

          return ListView.builder(
            padding:
                const EdgeInsets.all(12),
            itemCount: posts.length,
            itemBuilder: (
              context,
              index,
            ) {
              final data =
                  posts[index].data();

              final userName =
                  data['userName']
                          ?.toString() ??
                      'বন্ধু';

              final text =
                  data['text']
                          ?.toString() ??
                      '';

              final likes =
                  data['likeCount'] ?? 0;

              final comments =
                  data['commentCount'] ?? 0;

              return Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      Text(
                        userName,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      Text(
                        text.isEmpty
                            ? 'কোনো Text নেই'
                            : text,
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      Text(
                        '👍 $likes   💬 $comments',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================
// APP STATISTICS SCREEN
// ============================================================

class AppStatisticsScreen
    extends StatelessWidget {
  const AppStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'App Statistics',
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [

          StreamBuilder<
              QuerySnapshot<
                  Map<String, dynamic>>>(
            stream:
                FirebaseFirestore.instance
                    .collection('users')
                    .snapshots(),
            builder: (
              context,
              snapshot,
            ) {
              final count =
                  snapshot.data?.docs.length ??
                      0;

              return _statCard(
                icon: Icons.people,
                title: 'Total Users',
                value: '$count',
              );
            },
          ),

          const SizedBox(height: 12),

          StreamBuilder<
              QuerySnapshot<
                  Map<String, dynamic>>>(
            stream:
                FirebaseFirestore.instance
                    .collection('posts')
                    .snapshots(),
            builder: (
              context,
              snapshot,
            ) {
              final count =
                  snapshot.data?.docs.length ??
                      0;

              return _statCard(
                icon: Icons.article,
                title: 'Total Posts',
                value: '$count',
              );
            },
          ),

          const SizedBox(height: 12),

          StreamBuilder<
              QuerySnapshot<
                  Map<String, dynamic>>>(
            stream:
                FirebaseFirestore.instance
                    .collection(
                      'withdraw_requests',
                    )
                    .snapshots(),
            builder: (
              context,
              snapshot,
            ) {
              final count =
                  snapshot.data?.docs.length ??
                      0;

              return _statCard(
                icon: Icons.payments,
                title: 'Withdraw Requests',
                value: '$count',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      child: ListTile(
        leading:
            CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          title,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        trailing: Text(
          value,
          style:
              const TextStyle(
            fontSize: 22,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ADMIN SECURITY SCREEN
// ============================================================

class AdminSecurityScreen
    extends StatelessWidget {
  const AdminSecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Security',
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [

          Card(
            child: ListTile(
              leading:
                  const Icon(
                Icons.verified_user,
              ),
              title: const Text(
                'Admin Access',
              ),
              subtitle: const Text(
                'Admin account-এর জন্য Dashboard access সক্রিয়।',
              ),
            ),
          ),

          const SizedBox(height: 10),

          Card(
            child: ListTile(
              leading:
                  const Icon(
                Icons.security,
              ),
              title: const Text(
                'Firestore Security',
              ),
              subtitle: const Text(
                'Firestore Rules দিয়ে Admin data সুরক্ষিত রাখুন।',
              ),
            ),
          ),

          const SizedBox(height: 10),

          Card(
            child: ListTile(
              leading:
                  const Icon(
                Icons.email,
              ),
              title: const Text(
                'Admin Email',
              ),
              subtitle: const Text(
                'md.mojidul.haque.1234@gmail.com',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// APP SETTINGS SCREEN
// ============================================================

class AppSettingsScreen
    extends StatelessWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'App Settings',
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [

          Card(
            child: ListTile(
              leading:
                  const Icon(
                Icons.settings,
              ),
              title: const Text(
                'General Settings',
              ),
              subtitle: const Text(
                'অ্যাপের সাধারণ Settings',
              ),
              onTap: () {
                _showMessage(
                  context,
                  'General Settings পরে যোগ করা হবে।',
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          Card(
            child: ListTile(
              leading:
                  const Icon(
                Icons.attach_money,
              ),
              title: const Text(
                'Earning Settings',
              ),
              subtitle: const Text(
                'User earning এবং Admin revenue settings',
              ),
              onTap: () {
                _showMessage(
                  context,
                  'Earning Settings পরে যোগ করা হবে।',
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          Card(
            child: ListTile(
              leading:
                  const Icon(
                Icons.notifications,
              ),
              title: const Text(
                'Notification Settings',
              ),
              subtitle: const Text(
                'App notification settings',
              ),
              onTap: () {
                _showMessage(
                  context,
                  'Notification Settings পরে যোগ করা হবে।',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_withdrawals_screen.dart';

class AdminEarningsScreen extends StatelessWidget {
  const AdminEarningsScreen({super.key});

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
  // OWNER WALLET STREAM
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      _ownerWalletStream() {
    return FirebaseFirestore.instance
        .collection('settings')
        .doc('owner_wallet')
        .snapshots();
  }

  // ============================================================
  // WITHDRAW COUNT
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _pendingWithdrawalsStream() {
    return FirebaseFirestore.instance
        .collection('withdraw_requests')
        .where(
          'status',
          isEqualTo: 'pending',
        )
        .snapshots();
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Earnings',
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        stream: _ownerWalletStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
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

          final totalPaidToUsers =
              _toDouble(
            data['totalPaidToUsers'],
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ==================================================
              // OWNER WALLET CARD
              // ==================================================

              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet,
                        size: 55,
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'Owner Wallet Balance',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        _money(balance),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const Divider(
                        height: 30,
                      ),

                      Row(
                        children: [
                          Expanded(
                            child: _walletItem(
                              title: 'Total Revenue',
                              value:
                                  _money(
                                totalEarned,
                              ),
                              icon:
                                  Icons.trending_up,
                            ),
                          ),

                          Expanded(
                            child: _walletItem(
                              title: 'Paid Users',
                              value:
                                  _money(
                                totalPaidToUsers,
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
              ),

              const SizedBox(height: 20),

              // ==================================================
              // PENDING WITHDRAWALS
              // ==================================================

              StreamBuilder<
                  QuerySnapshot<
                      Map<String, dynamic>>>(
                stream:
                    _pendingWithdrawalsStream(),
                builder: (
                  context,
                  withdrawSnapshot,
                ) {
                  if (withdrawSnapshot
                          .connectionState ==
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

                  final pendingCount =
                      withdrawSnapshot
                              .data
                              ?.docs
                              .length ??
                          0;

                  return Card(
                    child: ListTile(
                      leading:
                          const CircleAvatar(
                        child: Icon(
                          Icons.pending_actions,
                        ),
                      ),
                      title: const Text(
                        'Pending Withdrawals',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        pendingCount == 0
                            ? 'কোনো pending request নেই'
                            : '$pendingCount টি request অপেক্ষায় আছে',
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AdminWithdrawalsScreen(),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // ==================================================
              // WITHDRAW MANAGEMENT
              // ==================================================

              Card(
                child: ListTile(
                  leading:
                      const CircleAvatar(
                    child: Icon(
                      Icons.account_balance,
                    ),
                  ),
                  title: const Text(
                    'Withdraw Management',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text(
                    'Withdraw request দেখুন, Approve অথবা Reject করুন',
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const AdminWithdrawalsScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // ==================================================
              // INFORMATION
              // ==================================================

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
                            Icons.info_outline,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Admin Information',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        '• User withdrawal request করলে টাকা wallet থেকে reserve হবে।',
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        '• Admin Approve করলে withdrawal completed হবে।',
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        '• Admin Reject করলে টাকা User-এর wallet-এ ফেরত যাবে।',
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        '• শুধুমাত্র Admin এই অংশ পরিচালনা করতে পারবে।',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // WALLET ITEM
  // ============================================================

  Widget _walletItem({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 28,
        ),

        const SizedBox(height: 6),

        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

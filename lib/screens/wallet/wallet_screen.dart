import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'প্রথমে Login করুন।',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          const Color(0xFFF0F2F5),

      appBar: AppBar(
        title: const Text(
          'আমার Wallet',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: StreamBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
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

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Wallet লোড করা যায়নি।\n\n${snapshot.error}',
                textAlign:
                    TextAlign.center,
              ),
            );
          }

          final data =
              snapshot.data?.data() ?? {};

          final wallet =
              _toDouble(data['wallet']);

          final totalEarned =
              _toDouble(data['totalEarned']);

          final totalWithdrawn =
              _toDouble(data['totalWithdrawn']);

          return ListView(
            padding:
                const EdgeInsets.all(16),
            children: [

              // ==================================================
              // BALANCE
              // ==================================================

              Card(
                elevation: 3,
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(24),
                  decoration:
                      BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [

                      const Icon(
                        Icons
                            .account_balance_wallet,
                        size: 50,
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      const Text(
                        'বর্তমান Balance',
                        style:
                            TextStyle(
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      Text(
                        _money(wallet),
                        style:
                            const TextStyle(
                          fontSize: 34,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              // ==================================================
              // STATS
              // ==================================================

              Row(
                children: [

                  Expanded(
                    child: _statCard(
                      icon:
                          Icons.trending_up,
                      title:
                          'Total Earned',
                      value:
                          _money(
                        totalEarned,
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child: _statCard(
                      icon:
                          Icons.payments,
                      title:
                          'Withdrawn',
                      value:
                          _money(
                        totalWithdrawn,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 15,
              ),

              // ==================================================
              // WITHDRAW
              // ==================================================

              Card(
                child: ListTile(
                  leading:
                      const CircleAvatar(
                    child: Icon(
                      Icons
                          .account_balance,
                    ),
                  ),
                  title: const Text(
                    'Withdraw Money',
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  subtitle:
                      const Text(
                    'আপনার Wallet থেকে টাকা Withdraw করুন',
                  ),
                  trailing:
                      const Icon(
                    Icons
                        .arrow_forward_ios,
                    size: 18,
                  ),
                  onTap: () {
                    _showWithdrawDialog(
                      context,
                      wallet,
                    );
                  },
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              // ==================================================
              // TRANSACTION
              // ==================================================

              Card(
                child: ListTile(
                  leading:
                      const CircleAvatar(
                    child: Icon(
                      Icons.history,
                    ),
                  ),
                  title: const Text(
                    'Transaction History',
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  subtitle:
                      const Text(
                    'আপনার Earnings ও Withdraw History',
                  ),
                  trailing:
                      const Icon(
                    Icons
                        .arrow_forward_ios,
                    size: 18,
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Transaction History পরের ধাপে যুক্ত করা হবে।',
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // NOTE
              // ==================================================

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      const Icon(
                        Icons.info_outline,
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      Expanded(
                        child: Text(
                          'Wallet-এর Balance Firestore-এর users collection থেকে নেওয়া হচ্ছে।',
                          style:
                              TextStyle(
                            color: Colors
                                .grey
                                .shade700,
                          ),
                        ),
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
            const EdgeInsets.all(16),
        child: Column(
          children: [

            Icon(
              icon,
              size: 28,
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              title,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 12,
              ),
            ),

            const SizedBox(
              height: 5,
            ),

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
      ),
    );
  }

  // ============================================================
  // WITHDRAW DIALOG
  // ============================================================

  void _showWithdrawDialog(
    BuildContext context,
    double balance,
  ) {
    final controller =
        TextEditingController();

    showDialog<void>(
      context: context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          title: const Text(
            'Withdraw Money',
          ),

          content: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [

              Text(
                'Available: ${_money(balance)}',
              ),

              const SizedBox(
                height: 15,
              ),

              TextField(
                controller:
                    controller,
                keyboardType:
                    const TextInputType
                        .numberWithOptions(
                  decimal: true,
                ),
                decoration:
                    const InputDecoration(
                  labelText:
                      'Withdraw Amount',
                  prefixText: '৳ ',
                  border:
                      OutlineInputBorder(),
                ),
              ),
            ],
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),

            FilledButton(
              onPressed: () {
                final amount =
                    double.tryParse(
                          controller
                              .text
                              .trim(),
                        ) ??
                        0;

                if (amount <= 0) {
                  ScaffoldMessenger
                      .of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'সঠিক Amount দিন।',
                      ),
                    ),
                  );
                  return;
                }

                if (amount > balance) {
                  ScaffoldMessenger
                      .of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'আপনার Wallet-এ পর্যাপ্ত Balance নেই।',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(
                  dialogContext,
                );

                ScaffoldMessenger
                    .of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Withdraw Request system পরের ধাপে যুক্ত করা হবে।',
                    ),
                  ),
                );
              },
              child: const Text(
                'Request',
              ),
            ),
          ],
        );
      },
    );
  }
}

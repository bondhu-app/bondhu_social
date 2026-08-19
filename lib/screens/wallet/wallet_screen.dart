import 'package:flutter/material.dart';

import '../../services/wallet_service.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  final WalletService _walletService =
      WalletService.instance;

  String _money(dynamic value) {
    double amount = 0;

    if (value is num) {
      amount = value.toDouble();
    } else if (value is String) {
      amount = double.tryParse(value) ?? 0;
    }

    return '৳${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),

      appBar: AppBar(
        title: const Text(
          'আমার Wallet',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: StreamBuilder(
        stream: _walletService.walletStream(),
        builder: (
          context,
          snapshot,
        ) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(20),
                child: Text(
                  'Wallet তথ্য পাওয়া যায়নি।\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data =
              snapshot.data?.data()
                  as Map<String, dynamic>? ??
              {};

          final wallet =
              data['wallet'] ?? 0;

          final totalEarned =
              data['totalEarned'] ?? 0;

          return RefreshIndicator(
            onRefresh: () async {
              await _walletService
                  .initializeWallet();
            },

            child: ListView(
              padding:
                  const EdgeInsets.all(16),

              children: [

                // ==================================================
                // WALLET CARD
                // ==================================================

                Card(
                  elevation: 4,
                  child: Padding(
                    padding:
                        const EdgeInsets.all(24),

                    child: Column(
                      children: [

                        const Icon(
                          Icons
                              .account_balance_wallet,
                          size: 55,
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        const Text(
                          'বর্তমান Wallet Balance',
                          style: TextStyle(
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
                // TOTAL EARNED
                // ==================================================

                Card(
                  child: ListTile(
                    leading:
                        const CircleAvatar(
                      child: Icon(
                        Icons.trending_up,
                      ),
                    ),

                    title: const Text(
                      'মোট আয়',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    subtitle: const Text(
                      'এখন পর্যন্ত আপনার মোট User earning',
                    ),

                    trailing: Text(
                      _money(totalEarned),
                      style:
                          const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 15,
                ),

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

                            SizedBox(
                              width: 8,
                            ),

                            Text(
                              'Earning System',
                              style:
                                  TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        const Text(
                          'আপনার earning-এর নির্ধারিত অংশ User Wallet-এ যোগ হবে এবং বাকি অংশ Admin Revenue হিসেবে Owner Wallet-এ যাবে।',
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        const Text(
                          'বর্তমান ভাগ: User 80% • Admin 20%',
                          style: TextStyle(
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
                // WITHDRAW BUTTON
                // ==================================================

                SizedBox(
                  height: 52,

                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Withdraw System পরের ধাপে যোগ করা হবে।',
                          ),
                        ),
                      );
                    },

                    icon: const Icon(
                      Icons.payments,
                    ),

                    label: const Text(
                      'Withdraw',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 30,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminEarningsScreen extends StatelessWidget {
  const AdminEarningsScreen({super.key});

  final String _walletCollection = 'settings';
  final String _walletDocument = 'owner_wallet';

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
      _walletStream() {
    return FirebaseFirestore.instance
        .collection(_walletCollection)
        .doc(_walletDocument)
        .snapshots();
  }

  Future<void> _addRevenue(
    BuildContext context,
  ) async {
    final controller = TextEditingController();

    final amount = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Revenue যোগ করুন',
          ),
          content: TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: const InputDecoration(
              labelText: 'টাকার পরিমাণ',
              hintText: 'যেমন: 100',
              prefixText: '৳ ',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'বাতিল',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final value =
                    double.tryParse(
                  controller.text.trim(),
                );

                if (value == null ||
                    value <= 0) {
                  return;
                }

                Navigator.pop(
                  context,
                  value,
                );
              },
              child: const Text(
                'যোগ করুন',
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (amount == null || amount <= 0) {
      return;
    }

    try {
      final walletRef = FirebaseFirestore
          .instance
          .collection(_walletCollection)
          .doc(_walletDocument);

      await FirebaseFirestore.instance
          .runTransaction(
        (transaction) async {
          final snapshot =
              await transaction.get(
            walletRef,
          );

          final data =
              snapshot.data() ?? {};

          final oldRevenue =
              _toDouble(
            data['totalEarned'],
          );

          final oldBalance =
              _toDouble(
            data['balance'],
          );

          final oldPaid =
              _toDouble(
            data['totalPaidToUsers'],
          );

          transaction.set(
            walletRef,
            {
              'balance':
                  oldBalance + amount,
              'totalEarned':
                  oldRevenue + amount,
              'totalPaidToUsers':
                  oldPaid,
              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
            SetOptions(
              merge: true,
            ),
          );
        },
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              '${_money(amount)} Revenue যোগ হয়েছে।',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Revenue যোগ করা যায়নি: $e',
            ),
          ),
        );
      }
    }
  }

  Future<void> _initializeWallet(
    BuildContext context,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection(_walletCollection)
          .doc(_walletDocument)
          .set(
        {
          'balance': 0,
          'totalEarned': 0,
          'totalPaidToUsers': 0,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Owner Wallet তৈরি হয়েছে।',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Wallet তৈরি করা যায়নি: $e',
            ),
          ),
        );
      }
    }
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
            fontWeight:
                FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<
          DocumentSnapshot<
              Map<String, dynamic>>>(
        stream: _walletStream(),
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
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  20,
                ),
                child: Text(
                  'Error: ${snapshot.error}',
                ),
              ),
            );
          }

          final exists =
              snapshot.data?.exists ??
                  false;

          final data =
              snapshot.data?.data() ??
                  {};

          final balance =
              _toDouble(
            data['balance'],
          );

          final revenue =
              _toDouble(
            data['totalEarned'],
          );

          final paidUsers =
              _toDouble(
            data['totalPaidToUsers'],
          );

          final netEarnings =
              revenue - paidUsers;

          return ListView(
            padding:
                const EdgeInsets.all(16),
            children: [
              // =================================================
              // HEADER
              // =================================================

              Card(
                elevation: 3,
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    20,
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        child: Icon(
                          Icons
                              .account_balance,
                          size: 32,
                        ),
                      ),
                      const SizedBox(
                        width: 15,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            const Text(
                              'Admin Earnings',
                              style:
                                  TextStyle(
                                fontSize: 23,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Text(
                              'Owner Revenue ও Wallet পরিচালনা করুন',
                              style: TextStyle(
                                color: Colors
                                    .grey
                                    .shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              // =================================================
              // WALLET NOT FOUND
              // =================================================

              if (!exists)
                Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(
                      18,
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons
                              .account_balance_wallet_outlined,
                          size: 55,
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        const Text(
                          'Owner Wallet পাওয়া যায়নি।',
                          style:
                              TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        const Text(
                          'প্রথমে Wallet তৈরি করুন।',
                          textAlign:
                              TextAlign.center,
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        SizedBox(
                          width:
                              double.infinity,
                          child:
                              ElevatedButton
                                  .icon(
                            onPressed: () {
                              _initializeWallet(
                                context,
                              );
                            },
                            icon:
                                const Icon(
                              Icons
                                  .add,
                            ),
                            label:
                                const Text(
                              'Create Owner Wallet',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (exists) ...[
                // =================================================
                // BALANCE
                // =================================================

                Card(
                  elevation: 3,
                  child: Padding(
                    padding:
                        const EdgeInsets.all(
                      20,
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons
                              .account_balance_wallet,
                          size: 40,
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        const Text(
                          'Owner Balance',
                          style:
                              TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Text(
                          _money(balance),
                          style:
                              const TextStyle(
                            fontSize: 34,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                // =================================================
                // REVENUE
                // =================================================

                Card(
                  child: ListTile(
                    leading:
                        const CircleAvatar(
                      child: Icon(
                        Icons
                            .trending_up,
                      ),
                    ),
                    title: const Text(
                      'Total Revenue',
                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    subtitle:
                        const Text(
                      'অ্যাপ থেকে মোট জমা হওয়া Revenue',
                    ),
                    trailing: Text(
                      _money(revenue),
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                // =================================================
                // PAID USERS
                // =================================================

                Card(
                  child: ListTile(
                    leading:
                        const CircleAvatar(
                      child: Icon(
                        Icons
                            .payments,
                      ),
                    ),
                    title: const Text(
                      'Paid to Users',
                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    subtitle:
                        const Text(
                      'Users-কে মোট দেওয়া টাকা',
                    ),
                    trailing: Text(
                      _money(
                        paidUsers,
                      ),
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                // =================================================
                // NET EARNINGS
                // =================================================

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
                      'Net Earnings',
                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    subtitle:
                        const Text(
                      'Revenue - Users Payment',
                    ),
                    trailing: Text(
                      _money(
                        netEarnings,
                      ),
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                // =================================================
                // ADD REVENUE
                // =================================================

                SizedBox(
                  width:
                      double.infinity,
                  child:
                      ElevatedButton.icon(
                    onPressed: () {
                      _addRevenue(
                        context,
                      );
                    },
                    icon: const Icon(
                      Icons.add,
                    ),
                    label: const Text(
                      'Add Revenue',
                    ),
                    style:
                        ElevatedButton
                            .styleFrom(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 15,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                // =================================================
                // INFORMATION
                // =================================================

                Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(
                      16,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
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
                              'Revenue সম্পর্কে',
                              style:
                                  TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Text(
                          'Revenue হলো অ্যাপের আয়ের টাকা। '
                          'বাস্তবে বিজ্ঞাপন, পেইড সার্ভিস, কমিশন বা অন্য কোনো বৈধ আয়ের উৎস থেকে টাকা পাওয়ার পর সেটি Revenue হিসেবে হিসাব করা যাবে।',
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
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminRevenueScreen extends StatelessWidget {
  const AdminRevenueScreen({super.key});

  static const String walletCollection = 'settings';
  static const String walletDocument = 'owner_wallet';
  static const String earningsCollection = 'earnings';

  FirebaseFirestore get firestore =>
      FirebaseFirestore.instance;

  // ============================================================
  // NUMBER
  // ============================================================

  double toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }

  String money(dynamic value) {
    return '৳${toDouble(value).toStringAsFixed(2)}';
  }

  // ============================================================
  // OWNER WALLET
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      ownerWalletStream() {
    return firestore
        .collection(walletCollection)
        .doc(walletDocument)
        .snapshots();
  }

  // ============================================================
  // EARNINGS
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      earningsStream() {
    return firestore
        .collection(earningsCollection)
        .orderBy(
          'createdAt',
          descending: true,
        )
        .limit(100)
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
          'Admin Revenue',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: StreamBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        stream: ownerWalletStream(),

        builder: (
          context,
          walletSnapshot,
        ) {
          if (walletSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (walletSnapshot.hasError) {
            return _error(
              'Owner Wallet লোড করা যায়নি',
              walletSnapshot.error.toString(),
            );
          }

          final wallet =
              walletSnapshot.data?.data() ?? {};

          final balance =
              toDouble(wallet['balance']);

          final totalEarned =
              toDouble(wallet['totalEarned']);

          final totalPaid =
              toDouble(
            wallet['totalPaidToUsers'],
          );

          return StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
            stream: earningsStream(),

            builder: (
              context,
              earningsSnapshot,
            ) {
              if (earningsSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child:
                      CircularProgressIndicator(),
                );
              }

              if (earningsSnapshot.hasError) {
                return _error(
                  'Revenue লোড করা যায়নি',
                  earningsSnapshot.error
                      .toString(),
                );
              }

              final earnings =
                  earningsSnapshot.data?.docs ??
                      [];

              double adminIncome = 0;
              double userIncome = 0;
              double grossIncome = 0;

              for (final doc in earnings) {
                final data = doc.data();

                adminIncome +=
                    toDouble(
                  data['adminAmount'],
                );

                userIncome +=
                    toDouble(
                  data['userAmount'],
                );

                grossIncome +=
                    toDouble(
                  data['grossAmount'],
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await Future<void>.delayed(
                    const Duration(
                      milliseconds: 500,
                    ),
                  );
                },

                child: ListView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),

                  padding:
                      const EdgeInsets.all(16),

                  children: [

                    // ==================================================
                    // ADMIN HEADER
                    // ==================================================

                    _header(),

                    const SizedBox(
                      height: 16,
                    ),

                    // ==================================================
                    // OWNER WALLET
                    // ==================================================

                    _walletCard(
                      balance,
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    // ==================================================
                    // REVENUE STATS
                    // ==================================================

                    Row(
                      children: [

                        Expanded(
                          child:
                              _statCard(
                            title:
                                'Total Revenue',
                            value:
                                money(
                              totalEarned,
                            ),
                            icon:
                                Icons
                                    .trending_up,
                          ),
                        ),

                        const SizedBox(
                          width: 10,
                        ),

                        Expanded(
                          child:
                              _statCard(
                            title:
                                'Admin Income',
                            value:
                                money(
                              adminIncome,
                            ),
                            icon:
                                Icons
                                    .account_balance,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Row(
                      children: [

                        Expanded(
                          child:
                              _statCard(
                            title:
                                'User Income',
                            value:
                                money(
                              userIncome,
                            ),
                            icon:
                                Icons
                                    .people,
                          ),
                        ),

                        const SizedBox(
                          width: 10,
                        ),

                        Expanded(
                          child:
                              _statCard(
                            title:
                                'Records',
                            value:
                                '${earnings.length}',
                            icon:
                                Icons
                                    .receipt_long,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    _fullStat(
                      title:
                          'Total Paid To Users',
                      value:
                          money(
                        totalPaid,
                      ),
                      icon:
                          Icons.payments,
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    _fullStat(
                      title:
                          'Gross Earnings',
                      value:
                          money(
                        grossIncome,
                      ),
                      icon:
                          Icons.bar_chart,
                    ),

                    const SizedBox(
                      height: 22,
                    ),

                    // ==================================================
                    // HISTORY
                    // ==================================================

                    const Text(
                      'Revenue History',
                      style:
                          TextStyle(
                        fontSize: 21,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      '${earnings.length} টি earning record',
                      style:
                          TextStyle(
                        color:
                            Colors.grey.shade700,
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    if (earnings.isEmpty)
                      _empty(),

                    ...earnings.map(
                      (document) {
                        return _earningCard(
                          document,
                        );
                      },
                    ),

                    const SizedBox(
                      height: 30,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _header() {
    return Card(
      elevation: 3,

      child: Padding(
        padding:
            const EdgeInsets.all(20),

        child: Row(
          children: [

            const CircleAvatar(
              radius: 30,
              child: Icon(
                Icons.admin_panel_settings,
                size: 33,
              ),
            ),

            const SizedBox(
              width: 15,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  const Text(
                    'Admin Revenue',
                    style:
                        TextStyle(
                      fontSize: 23,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  Text(
                    'Admin-এর Income, Revenue এবং Wallet এখানে দেখা যাবে।',
                    style:
                        TextStyle(
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
  // WALLET
  // ============================================================

  Widget _walletCard(
    double balance,
  ) {
    return Card(
      elevation: 3,

      child: Padding(
        padding:
            const EdgeInsets.all(22),

        child: Column(
          children: [

            const Icon(
              Icons.account_balance_wallet,
              size: 40,
            ),

            const SizedBox(
              height: 8,
            ),

            const Text(
              'Owner Wallet Balance',
              style:
                  TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              money(balance),
              style:
                  const TextStyle(
                fontSize: 32,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            const Text(
              'বর্তমান Owner Balance',
              style:
                  TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(15),

        child: Column(
          children: [

            Icon(
              icon,
              size: 27,
            ),

            const SizedBox(
              height: 7,
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
  // FULL STAT
  // ============================================================

  Widget _fullStat({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      child: ListTile(
        leading:
            CircleAvatar(
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

        trailing: Text(
          value,
          style:
              const TextStyle(
            fontSize: 17,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EARNING CARD
  // ============================================================

  Widget _earningCard(
    DocumentSnapshot<
        Map<String, dynamic>> document,
  ) {
    final data =
        document.data() ?? {};

    final userId =
        data['userId']
                ?.toString() ??
            'Unknown User';

    final source =
        data['source']
                ?.toString() ??
            'earning';

    final description =
        data['description']
                ?.toString() ??
            '';

    final gross =
        toDouble(
      data['grossAmount'],
    );

    final userAmount =
        toDouble(
      data['userAmount'],
    );

    final adminAmount =
        toDouble(
      data['adminAmount'],
    );

    final commission =
        toDouble(
      data[
          'adminCommissionPercent'],
    );

    final createdAt =
        data['createdAt'];

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),

      child: Padding(
        padding:
            const EdgeInsets.all(15),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            // USER
            Row(
              children: [

                const CircleAvatar(
                  child:
                      Icon(
                    Icons.person,
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      const Text(
                        'User ID',
                        style:
                            TextStyle(
                          fontSize: 11,
                          color:
                              Colors.grey,
                        ),
                      ),

                      Text(
                        userId,
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

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
                        BorderRadius
                            .circular(
                      15,
                    ),
                    border:
                        Border.all(),
                  ),

                  child: Text(
                    '${commission.toStringAsFixed(0)}%',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            if (description.isNotEmpty)
              _infoRow(
                'Description',
                description,
              ),

            _infoRow(
              'Source',
              source,
            ),

            _infoRow(
              'Gross Earning',
              money(gross),
            ),

            _infoRow(
              'User Received',
              money(userAmount),
            ),

            _infoRow(
              'Admin Revenue',
              money(adminAmount),
            ),

            if (createdAt != null)
              _infoRow(
                'Created',
                _date(createdAt),
              ),

            const SizedBox(
              height: 10,
            ),

            // ADMIN INCOME
            Container(
              width:
                  double.infinity,

              padding:
                  const EdgeInsets
                      .all(12),

              decoration:
                  BoxDecoration(
                borderRadius:
                    BorderRadius
                        .circular(
                  10,
                ),
                border:
                    Border.all(),
              ),

              child: Column(
                children: [

                  const Text(
                    'ADMIN INCOME',
                    style:
                        TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    money(adminAmount),
                    style:
                        const TextStyle(
                      fontSize: 23,
                      fontWeight:
                          FontWeight.bold,
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
  // INFO ROW
  // ============================================================

  Widget _infoRow(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 6,
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          SizedBox(
            width: 125,

            child: Text(
              title,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              textAlign:
                  TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATE
  // ============================================================

  String _date(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }

    if (date == null) {
      return 'সময় নেই';
    }

    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    final year =
        date.year.toString();

    final hour =
        date.hour.toString().padLeft(2, '0');

    final minute =
        date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _empty() {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(28),

        child: Column(
          children: [

            const Icon(
              Icons.receipt_long,
              size: 55,
            ),

            const SizedBox(
              height: 12,
            ),

            const Text(
              'এখনও কোনো Revenue নেই',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              'User earning শুরু হলে Admin Income এখানে দেখা যাবে।',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                color:
                    Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _error(
    String title,
    String message,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(20),

        child: Card(
          child: Padding(
            padding:
                const EdgeInsets.all(20),

            child: Column(
              mainAxisSize:
                  MainAxisSize.min,

              children: [

                const Icon(
                  Icons.error_outline,
                  size: 50,
                ),

                const SizedBox(
                  height: 10,
                ),

                Text(
                  title,
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  message,
                  textAlign:
                      TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminEarningsScreen extends StatelessWidget {
  const AdminEarningsScreen({super.key});

  FirebaseFirestore get _firestore =>
      FirebaseFirestore.instance;

  // ============================================================
  // NUMBER
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
  // MONEY
  // ============================================================

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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF0F2F5),

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
        onRefresh: () async {
          await Future<void>.delayed(
            const Duration(
              milliseconds: 500,
            ),
          );
        },

        child: ListView(
          padding:
              const EdgeInsets.all(16),
          children: [

            // ==================================================
            // HEADER
            // ==================================================

            Card(
              elevation: 3,
              child: Padding(
                padding:
                    const EdgeInsets.all(20),
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

                    const SizedBox(width: 15),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [

                          const Text(
                            'Earnings & Revenue',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            'Admin-এর Income এবং Owner Wallet দেখুন',
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

            const SizedBox(height: 18),

            // ==================================================
            // OWNER WALLET
            // ==================================================

            const Text(
              'Owner Wallet',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            StreamBuilder<
                DocumentSnapshot<
                    Map<String, dynamic>>>(
              stream:
                  _ownerWalletStream(),
              builder: (
                context,
                snapshot,
              ) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Card(
                    child: Padding(
                      padding:
                          EdgeInsets.all(25),
                      child: Center(
                        child:
                            CircularProgressIndicator(),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _errorCard(
                    snapshot.error
                        .toString(),
                  );
                }

                final data =
                    snapshot.data?.data() ??
                        {};

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
                  data[
                      'totalPaidToUsers'],
                );

                return Column(
                  children: [

                    _bigMoneyCard(
                      title:
                          'Current Balance',
                      value:
                          _money(balance),
                      icon:
                          Icons
                              .account_balance_wallet,
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [

                        Expanded(
                          child:
                              _moneyInfoCard(
                            title:
                                'Total Earned',
                            value:
                                _money(
                              totalEarned,
                            ),
                            icon:
                                Icons
                                    .trending_up,
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child:
                              _moneyInfoCard(
                            title:
                                'Paid Users',
                            value:
                                _money(
                              totalPaid,
                            ),
                            icon:
                                Icons
                                    .payments,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // ==================================================
            // ADMIN REVENUE
            // ==================================================

            const Text(
              'Admin Revenue',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            StreamBuilder<
                DocumentSnapshot<
                    Map<String, dynamic>>>(
              stream:
                  _revenueStream(),
              builder: (
                context,
                snapshot,
              ) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Card(
                    child: Padding(
                      padding:
                          EdgeInsets.all(25),
                      child: Center(
                        child:
                            CircularProgressIndicator(),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _errorCard(
                    snapshot.error
                        .toString(),
                  );
                }

                final data =
                    snapshot.data?.data() ??
                        {};

                final adminRevenue =
                    _toDouble(
                  data['adminRevenue'],
                );

                final totalGenerated =
                    _toDouble(
                  data['totalGenerated'],
                );

                final userEarnings =
                    _toDouble(
                  data['userEarnings'],
                );

                return Column(
                  children: [

                    _bigMoneyCard(
                      title:
                          'Admin Income',
                      value:
                          _money(
                        adminRevenue,
                      ),
                      icon:
                          Icons
                              .monetization_on,
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [

                        Expanded(
                          child:
                              _moneyInfoCard(
                            title:
                                'Generated',
                            value:
                                _money(
                              totalGenerated,
                            ),
                            icon:
                                Icons
                                    .analytics,
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child:
                              _moneyInfoCard(
                            title:
                                'User Earnings',
                            value:
                                _money(
                              userEarnings,
                            ),
                            icon:
                                Icons
                                    .person,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // ==================================================
            // REVENUE EXPLANATION
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

                        SizedBox(width: 8),

                        Text(
                          'Revenue System',
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
                      'User earning এবং Admin revenue আলাদা হিসেবে হিসাব করা হবে।',
                      style: TextStyle(
                        color:
                            Colors.grey.shade700,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'উদাহরণ:',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'User Earns = ৳100\n'
                      'User Gets = ৳80\n'
                      'Admin Revenue = ৳20',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // FIRESTORE INFORMATION
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
                          Icons.storage,
                        ),

                        SizedBox(width: 8),

                        Text(
                          'Firestore Data',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    _firestorePath(
                      'Collection',
                      'settings',
                    ),

                    _firestorePath(
                      'Document',
                      'owner_wallet',
                    ),

                    const Divider(),

                    _firestorePath(
                      'Collection',
                      'settings',
                    ),

                    _firestorePath(
                      'Document',
                      'revenue',
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
  // BIG MONEY CARD
  // ============================================================

  Widget _bigMoneyCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      elevation: 3,
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Row(
          children: [

            CircleAvatar(
              radius: 30,
              child: Icon(
                icon,
                size: 32,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  Text(
                    title,
                    style:
                        const TextStyle(
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    value,
                    style:
                        const TextStyle(
                      fontSize: 30,
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
  // MONEY INFO CARD
  // ============================================================

  Widget _moneyInfoCard({
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
              size: 26,
            ),

            const SizedBox(height: 7),

            Text(
              title,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 5),

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
  // FIRESTORE PATH
  // ============================================================

  Widget _firestorePath(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Row(
        children: [

          SizedBox(
            width: 100,
            child: Text(
              title,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR CARD
  // ============================================================

  Widget _errorCard(
    String error,
  ) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Text(
          error.replaceFirst(
            'Exception: ',
            '',
          ),
        ),
      ),
    );
  }
}

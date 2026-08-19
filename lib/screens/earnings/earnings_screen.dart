import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/earnings_service.dart';
import 'withdraw_screen.dart';

class EarningsScreen extends StatefulWidget {
  EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final EarningsService _earningsService =
      EarningsService.instance;

  @override
  void initState() {
    super.initState();

    _initializeWallet();
  }

  Future<void> _initializeWallet() async {
    try {
      await _earningsService.createWalletIfNeeded();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  String _money(dynamic value) {
    double amount = 0;

    if (value is num) {
      amount = value.toDouble();
    } else if (value is String) {
      amount = double.tryParse(value) ?? 0;
    }

    return '৳${amount.toStringAsFixed(2)}';
  }

  String _date(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    }

    return 'সময় পাওয়া যায়নি';
  }

  String _statusText(String status) {
    switch (status) {
      case 'completed':
        return 'সম্পন্ন';

      case 'pending':
        return 'অপেক্ষমাণ';

      case 'cancelled':
        return 'বাতিল';

      case 'approved':
        return 'অনুমোদিত';

      case 'rejected':
        return 'প্রত্যাখ্যাত';

      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
      case 'approved':
        return Colors.green;

      case 'pending':
        return Colors.orange;

      case 'cancelled':
      case 'rejected':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  Future<void> _openWithdraw() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WithdrawScreen(),
      ),
    );
  }

  Future<void> _cancelWithdraw(
    String requestId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Withdraw বাতিল করবেন?'),
          content: const Text(
            'এই pending withdraw request বাতিল করলে '
            'টাকাটি আবার আপনার Wallet-এ যোগ হবে।',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('না'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('হ্যাঁ, বাতিল'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await _earningsService.cancelWithdrawRequest(
        requestId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Withdraw request বাতিল হয়েছে। টাকা Wallet-এ ফেরত এসেছে।',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  Widget _walletCard(
    String title,
    String amount,
    IconData icon,
  ) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CircleAvatar(
                radius: 25,
                child: Icon(icon),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _transactionItem(
    Map<String, dynamic> data,
  ) {
    final amount = data['amount'];
    final type =
        data['type']?.toString() ?? 'transaction';

    final description =
        data['description']?.toString() ?? '';

    final status =
        data['status']?.toString() ?? '';

    final isWithdraw =
        data['transactionType'] == 'withdrawal';

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 5,
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            isWithdraw
                ? Icons.arrow_upward
                : Icons.arrow_downward,
          ),
        ),
        title: Text(
          description.isNotEmpty
              ? description
              : type,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(_date(data['createdAt'])),
            const SizedBox(height: 3),
            Text(
              _statusText(status),
              style: TextStyle(
                color: _statusColor(status),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: Text(
          '${isWithdraw ? '-' : '+'}${_money(amount)}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isWithdraw
                ? Colors.red
                : Colors.green,
          ),
        ),
      ),
    );
  }

  Widget _withdrawItem(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    final status =
        data['status']?.toString() ?? '';

    final amount = data['amount'];

    final method =
        data['method']?.toString() ?? '';

    final account =
        data['account']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 5,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.payments,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _money(amount),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(status)
                        .withOpacity(.12),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusText(status),
                    style: TextStyle(
                      color: _statusColor(status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Method: $method'),
            const SizedBox(height: 4),
            Text('Account: $account'),
            const SizedBox(height: 4),
            Text(
              'সময়: ${_date(data['createdAt'])}',
            ),
            if (status == 'pending') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _cancelWithdraw(
                      document.id,
                    );
                  },
                  icon: const Icon(
                    Icons.cancel_outlined,
                  ),
                  label: const Text(
                    'Withdraw বাতিল করুন',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Earnings & Wallet',
        ),
        actions: [
          IconButton(
            onPressed: _initializeWallet,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _initializeWallet,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 10),

            // ==================================================
            // WALLET
            // ==================================================

            StreamBuilder<
                DocumentSnapshot<Map<String, dynamic>>>(
              stream:
                  _earningsService.walletStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
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

                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(
                      child:
                          CircularProgressIndicator(),
                    ),
                  );
                }

                final data =
                    snapshot.data!.data() ?? {};

                final balance =
                    data['balance'] ?? 0;

                final totalEarned =
                    data['totalEarned'] ?? 0;

                final totalWithdrawn =
                    data['totalWithdrawn'] ?? 0;

                return Column(
                  children: [
                    Card(
                      margin:
                          const EdgeInsets.all(12),
                      elevation: 3,
                      child: Padding(
                        padding:
                            const EdgeInsets.all(22),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.account_balance_wallet,
                              size: 50,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Available Balance',
                              style: TextStyle(
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _money(balance),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 15),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed:
                                    _openWithdraw,
                                icon: const Icon(
                                  Icons
                                      .account_balance_wallet,
                                ),
                                label: const Text(
                                  'Withdraw',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        _walletCard(
                          'Total Earned',
                          _money(totalEarned),
                          Icons.trending_up,
                        ),
                        _walletCard(
                          'Withdrawn',
                          _money(totalWithdrawn),
                          Icons.payments_outlined,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 15),

            // ==================================================
            // TRANSACTIONS
            // ==================================================

            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 15,
              ),
              child: Text(
                'Transaction History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 8),

            StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: _earningsService
                  .myTransactionsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(15),
                    child: Text(
                      snapshot.error
                          .toString()
                          .replaceFirst(
                            'Exception: ',
                            '',
                          ),
                    ),
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child:
                          CircularProgressIndicator(),
                    ),
                  );
                }

                final docs =
                    snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(25),
                    child: Center(
                      child: Text(
                        'এখনও কোনো transaction নেই।',
                      ),
                    ),
                  );
                }

                return Column(
                  children: docs
                      .map(
                        (doc) =>
                            _transactionItem(
                          doc.data(),
                        ),
                      )
                      .toList(),
                );
              },
            ),

            const SizedBox(height: 20),

            // ==================================================
            // WITHDRAW REQUESTS
            // ==================================================

            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 15,
              ),
              child: Text(
                'Withdraw Requests',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 8),

            StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: _earningsService
                  .myWithdrawRequestsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(15),
                    child: Text(
                      snapshot.error
                          .toString()
                          .replaceFirst(
                            'Exception: ',
                            '',
                          ),
                    ),
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child:
                          CircularProgressIndicator(),
                    ),
                  );
                }

                final docs =
                    snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(25),
                    child: Center(
                      child: Text(
                        'কোনো Withdraw Request নেই।',
                      ),
                    ),
                  );
                }

                return Column(
                  children: docs
                      .map(
                        (doc) =>
                            _withdrawItem(doc),
                      )
                      .toList(),
                );
              },
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

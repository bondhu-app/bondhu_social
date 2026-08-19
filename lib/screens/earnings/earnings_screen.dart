import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/earnings_service.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

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

  void _openWithdraw() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WithdrawScreen(
          earningsService: _earningsService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _earningsService.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Earnings & Wallet'),
        ),
        body: const Center(
          child: Text(
            'প্রথমে লগইন করুন।',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings & Wallet'),
        centerTitle: true,
      ),
      body: StreamBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        stream: _earningsService.walletStream(),
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
                      .replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data = snapshot.data?.data() ?? {};

          final balance = data['balance'] ?? 0;
          final totalEarned =
              data['totalEarned'] ?? 0;
          final totalWithdrawn =
              data['totalWithdrawn'] ?? 0;

          return RefreshIndicator(
            onRefresh: _initializeWallet,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _walletCard(
                  balance: balance,
                  totalEarned: totalEarned,
                  totalWithdrawn: totalWithdrawn,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _openWithdraw,
                    icon: const Icon(
                      Icons.account_balance_wallet,
                    ),
                    label: const Text(
                      'Withdraw',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Transaction History',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _transactionList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _walletCard({
    required dynamic balance,
    required dynamic totalEarned,
    required dynamic totalWithdrawn,
  }) {
    return Card(
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
              'Available Balance',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _money(balance),
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 30),
            Row(
              children: [
                Expanded(
                  child: _walletItem(
                    'Total Earned',
                    _money(totalEarned),
                    Icons.trending_up,
                  ),
                ),
                Expanded(
                  child: _walletItem(
                    'Withdrawn',
                    _money(totalWithdrawn),
                    Icons.payments,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _walletItem(
    String title,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 28),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _transactionList() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _earningsService.myTransactionsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              snapshot.error
                  .toString()
                  .replaceFirst('Exception: ', ''),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(25),
              child: Center(
                child: Text(
                  'এখনও কোনো transaction নেই।',
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final data = docs[index].data();

            final type =
                data['type']?.toString() ?? '';

            final description =
                data['description']?.toString() ?? type;

            final amount = data['amount'] ?? 0;

            final transactionType =
                data['transactionType']?.toString() ?? '';

            final isEarning =
                transactionType == 'earning';

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Icon(
                    isEarning
                        ? Icons.add
                        : Icons.remove,
                  ),
                ),
                title: Text(
                  description.isEmpty
                      ? type
                      : description,
                ),
                subtitle: Text(
                  'Status: ${data['status'] ?? 'unknown'}',
                ),
                trailing: Text(
                  '${isEarning ? '+' : '-'}${_money(amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isEarning
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ============================================================
// WITHDRAW SCREEN
// ============================================================

class WithdrawScreen extends StatefulWidget {
  final EarningsService earningsService;

  const WithdrawScreen({
    super.key,
    required this.earningsService,
  });

  @override
  State<WithdrawScreen> createState() =>
      _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _amountController =
      TextEditingController();

  final TextEditingController _accountController =
      TextEditingController();

  String _method = 'bKash';

  bool _loading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  double _balanceFromData(
    Map<String, dynamic> data,
  ) {
    final value = data['balance'];

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }

  Future<void> _withdraw() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount =
        double.tryParse(_amountController.text.trim());

    if (amount == null) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await widget.earningsService.createWithdrawRequest(
        amount: amount,
        method: _method,
        account: _accountController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Withdraw request সফলভাবে পাঠানো হয়েছে।',
          ),
        ),
      );

      _amountController.clear();
      _accountController.clear();

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Withdraw'),
        centerTitle: true,
      ),
      body: StreamBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        stream: widget.earningsService.walletStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error
                    .toString()
                    .replaceFirst('Exception: ', ''),
              ),
            );
          }

          final data = snapshot.data?.data() ?? {};

          final balance =
              _balanceFromData(data);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet,
                        size: 45,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Available Balance',
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '৳${balance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Withdraw Amount',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller:
                              _amountController,
                          keyboardType:
                              const TextInputType
                                  .numberWithOptions(
                            decimal: true,
                          ),
                          decoration:
                              const InputDecoration(
                            labelText: 'Amount',
                            hintText: 'Minimum ৳100',
                            prefixText: '৳ ',
                            border:
                                OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Amount দিন';
                            }

                            final amount =
                                double.tryParse(
                              value.trim(),
                            );

                            if (amount == null) {
                              return 'সঠিক amount দিন';
                            }

                            if (amount < 100) {
                              return 'Minimum withdraw ৳100';
                            }

                            if (amount > balance) {
                              return 'আপনার balance পর্যাপ্ত নয়';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Payment Method',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _method,
                          decoration:
                              const InputDecoration(
                            border:
                                OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'bKash',
                              child: Text('bKash'),
                            ),
                            DropdownMenuItem(
                              value: 'Nagad',
                              child: Text('Nagad'),
                            ),
                            DropdownMenuItem(
                              value: 'Rocket',
                              child: Text('Rocket'),
                            ),
                            DropdownMenuItem(
                              value: 'Bank',
                              child: Text('Bank'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;

                            setState(() {
                              _method = value;
                            });
                          },
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller:
                              _accountController,
                          keyboardType:
                              TextInputType.phone,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Payment Account',
                            hintText:
                                'bKash/Nagad/Bank number',
                            border:
                                OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Payment account দিন';
                            }

                            if (value.trim().length <
                                5) {
                              return 'সঠিক account দিন';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed:
                                _loading
                                    ? null
                                    : _withdraw,
                            child: _loading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Submit Withdraw Request',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                'Withdraw Requests',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _withdrawRequests(),
            ],
          );
        },
      ),
    );
  }

  Widget _withdrawRequests() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: widget.earningsService
          .myWithdrawRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Text(
            snapshot.error
                .toString()
                .replaceFirst('Exception: ', ''),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'কোনো withdraw request নেই।',
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final doc = docs[index];

            final data = doc.data();

            final amount = data['amount'] is num
                ? (data['amount'] as num).toDouble()
                : double.tryParse(
                      '${data['amount']}',
                    ) ??
                    0;

            final status =
                data['status']?.toString() ??
                    'pending';

            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(
                    Icons.payments,
                  ),
                ),
                title: Text(
                  '৳${amount.toStringAsFixed(2)}',
                ),
                subtitle: Text(
                  '${data['method'] ?? ''} • '
                  '${data['account'] ?? ''}\n'
                  'Status: $status',
                ),
                isThreeLine: true,
                trailing: status == 'pending'
                    ? TextButton(
                        onPressed: () =>
                            _cancel(doc.id),
                        child: const Text(
                          'Cancel',
                        ),
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _cancel(String requestId) async {
    try {
      await widget.earningsService
          .cancelWithdrawRequest(requestId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Withdraw request বাতিল করা হয়েছে।',
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
}

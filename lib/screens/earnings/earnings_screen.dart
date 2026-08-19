import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/earnings_service.dart';

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
          content: Text(_errorMessage(e)),
        ),
      );
    }
  }

  String _errorMessage(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '');
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
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Earnings & Wallet',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Transaction History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TransactionHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _initializeWallet,
        child: StreamBuilder<
            DocumentSnapshot<Map<String, dynamic>>>(
          stream: _earningsService.walletStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                    ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 180),
                  Center(
                    child: Text(
                      _errorMessage(snapshot.error!),
                    ),
                  ),
                ],
              );
            }

            final data = snapshot.data?.data() ?? {};

            final balance = data['balance'] ?? 0;
            final totalEarned =
                data['totalEarned'] ?? 0;
            final totalWithdrawn =
                data['totalWithdrawn'] ?? 0;

            return ListView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _buildWalletCard(
                  balance: balance,
                  totalEarned: totalEarned,
                  totalWithdrawn: totalWithdrawn,
                ),

                const SizedBox(height: 20),

                _buildWithdrawButton(
                  balance: balance,
                ),

                const SizedBox(height: 20),

                _buildQuickActions(),

                const SizedBox(height: 24),

                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                _buildRecentTransactions(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWalletCard({
    required dynamic balance,
    required dynamic totalEarned,
    required dynamic totalWithdrawn,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1565C0),
            Color(0xFF42A5F5),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 28,
              ),
              SizedBox(width: 10),
              Text(
                'My Wallet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          const Text(
            'Available Balance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            _money(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: _walletStat(
                  title: 'Total Earned',
                  value: _money(totalEarned),
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _walletStat(
                  title: 'Withdrawn',
                  value: _money(totalWithdrawn),
                  icon: Icons.payments,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _walletStat({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 21,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawButton({
    required dynamic balance,
  }) {
    double amount = 0;

    if (balance is num) {
      amount = balance.toDouble();
    }

    return SizedBox(
      height: 55,
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(
          Icons.account_balance,
        ),
        label: const Text(
          'Withdraw Money',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: amount >=
                EarningsService.minimumWithdrawAmount
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        WithdrawScreen(
                      currentBalance: amount,
                    ),
                  ),
                );
              }
            : () {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Withdraw করতে কমপক্ষে ৳100 থাকতে হবে।',
                    ),
                  ),
                );
              },
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _quickAction(
            icon: Icons.receipt_long,
            title: 'Transactions',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      TransactionHistoryScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _quickAction(
            icon: Icons.account_balance,
            title: 'Withdrawals',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      WithdrawHistoryScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 10,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 30,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream:
          _earningsService.myTransactionsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
                ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _errorMessage(snapshot.error!),
              ),
            ),
          );
        }

        final docs =
            snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 45,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'কোনো transaction নেই।',
                  ),
                ],
              ),
            ),
          );
        }

        final recent =
            docs.take(5).toList();

        return Column(
          children: recent.map((doc) {
            final data = doc.data();

            final type =
                data['transactionType']
                        ?.toString() ??
                    data['type']
                        ?.toString() ??
                    'transaction';

            final amount =
                data['amount'] ?? 0;

            final status =
                data['status']
                        ?.toString() ??
                    '';

            final isEarning =
                type == 'earning' ||
                    type == 'referral' ||
                    type == 'admin_reward';

            return Card(
              margin:
                  const EdgeInsets.only(
                bottom: 8,
              ),
              child: ListTile(
                leading: CircleAvatar(
                  child: Icon(
                    isEarning
                        ? Icons.add
                        : Icons.remove,
                  ),
                ),
                title: Text(
                  _transactionTitle(data),
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  status.isEmpty
                      ? ''
                      : 'Status: $status',
                ),
                trailing: Text(
                  '${isEarning ? '+' : '-'}${_money(amount)}',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 15,
                    color: isEarning
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _transactionTitle(
    Map<String, dynamic> data,
  ) {
    final description =
        data['description']
            ?.toString()
            .trim();

    if (description != null &&
        description.isNotEmpty) {
      return description;
    }

    final type =
        data['type']?.toString() ??
            'Transaction';

    switch (type) {
      case 'referral':
        return 'Referral Reward';

      case 'admin_reward':
        return 'Admin Reward';

      case 'withdraw':
        return 'Withdrawal';

      default:
        return type;
    }
  }
}

// ============================================================
// WITHDRAW SCREEN
// ============================================================

class WithdrawScreen extends StatefulWidget {
  final double currentBalance;

  WithdrawScreen({
    super.key,
    required this.currentBalance,
  });

  @override
  State<WithdrawScreen> createState() =>
      _WithdrawScreenState();
}

class _WithdrawScreenState
    extends State<WithdrawScreen> {
  final EarningsService _service =
      EarningsService.instance;

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

  String _errorMessage(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '');
  }

  Future<void> _withdraw() async {
    FocusScope.of(context).unfocus();

    final amountText =
        _amountController.text.trim();

    final account =
        _accountController.text.trim();

    if (amountText.isEmpty) {
      _showError('Amount দিন।');
      return;
    }

    final amount =
        double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      _showError('সঠিক Amount দিন।');
      return;
    }

    if (amount <
        EarningsService.minimumWithdrawAmount) {
      _showError(
        'Minimum Withdraw ৳100।',
      );
      return;
    }

    if (amount > widget.currentBalance) {
      _showError(
        'আপনার Wallet-এ পর্যাপ্ত টাকা নেই।',
      );
      return;
    }

    if (account.isEmpty) {
      _showError(
        'Payment account দিন।',
      );
      return;
    }

    if (_method != 'Bank') {
      if (account.length < 8) {
        _showError(
          'সঠিক Payment account দিন।',
        );
        return;
      }
    }

    setState(() {
      _loading = true;
    });

    try {
      await _service.createWithdrawRequest(
        amount: amount,
        method: _method,
        account: account,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Withdraw request সফলভাবে পাঠানো হয়েছে।',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      _showError(
        _errorMessage(e),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Withdraw Money',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available Balance',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '৳${widget.currentBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Payment Method',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: _method,
              decoration:
                  const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.payment,
                ),
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
              onChanged: _loading
                  ? null
                  : (value) {
                      if (value == null) return;

                      setState(() {
                        _method = value;
                      });
                    },
            ),

            const SizedBox(height: 18),

            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration:
                  const InputDecoration(
                labelText: 'Withdraw Amount',
                hintText: 'Minimum ৳100',
                prefixText: '৳ ',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 18),

            TextField(
              controller: _accountController,
              keyboardType:
                  TextInputType.phone,
              decoration:
                  InputDecoration(
                labelText:
                    _method == 'Bank'
                        ? 'Bank Account'
                        : '$_method Number',
                hintText:
                    _method == 'Bank'
                        ? 'Bank account number'
                        : 'Payment number',
                prefixIcon: const Icon(
                  Icons.account_circle,
                ),
                border:
                    const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'আপনার payment information সঠিকভাবে দিন। '
              'Admin request যাচাই করে payment করবে।',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed:
                    _loading ? null : _withdraw,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send,
                      ),
                label: Text(
                  _loading
                      ? 'Processing...'
                      : 'Submit Withdraw Request',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// TRANSACTION HISTORY
// ============================================================

class TransactionHistoryScreen
    extends StatelessWidget {
  TransactionHistoryScreen({
    super.key,
  });

  final EarningsService _service =
      EarningsService.instance;

  String _money(dynamic value) {
    double amount = 0;

    if (value is num) {
      amount = value.toDouble();
    } else if (value is String) {
      amount =
          double.tryParse(value) ?? 0;
    }

    return '৳${amount.toStringAsFixed(2)}';
  }

  String _title(
    Map<String, dynamic> data,
  ) {
    final description =
        data['description']
            ?.toString()
            .trim();

    if (description != null &&
        description.isNotEmpty) {
      return description;
    }

    return data['type']
            ?.toString() ??
        'Transaction';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transaction History',
        ),
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream:
            _service.myTransactionsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
                  ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
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

          final docs =
              snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'কোনো transaction নেই।',
              ),
            );
          }

          return ListView.separated(
            padding:
                const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder:
                (_, __) =>
                    const SizedBox(height: 4),
            itemBuilder:
                (context, index) {
              final data =
                  docs[index].data();

              final type =
                  data['transactionType']
                          ?.toString() ??
                      '';

              final earning =
                  type == 'earning' ||
                      type == 'referral' ||
                      type == 'admin_reward';

              final amount =
                  data['amount'] ?? 0;

              final status =
                  data['status']
                          ?.toString() ??
                      '';

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      earning
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                    ),
                  ),
                  title: Text(
                    _title(data),
                  ),
                  subtitle: Text(
                    'Status: $status',
                  ),
                  trailing: Text(
                    '${earning ? '+' : '-'}${_money(amount)}',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      color: earning
                          ? Colors.green
                          : Colors.red,
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
// WITHDRAW HISTORY
// ============================================================

class WithdrawHistoryScreen
    extends StatelessWidget {
  WithdrawHistoryScreen({
    super.key,
  });

  final EarningsService _service =
      EarningsService.instance;

  String _money(dynamic value) {
    double amount = 0;

    if (value is num) {
      amount = value.toDouble();
    }

    return '৳${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Withdraw History',
        ),
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream:
            _service.myWithdrawRequestsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
                  ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
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

          final docs =
              snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'কোনো Withdraw request নেই।',
              ),
            );
          }

          return ListView.builder(
            padding:
                const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder:
                (context, index) {
              final doc =
                  docs[index];

              final data =
                  doc.data();

              final amount =
                  data['amount'] ?? 0;

              final method =
                  data['method']
                          ?.toString() ??
                      '';

              final account =
                  data['account']
                          ?.toString() ??
                      '';

              final status =
                  data['status']
                          ?.toString() ??
                      'pending';

              return Card(
                margin:
                    const EdgeInsets.only(
                  bottom: 10,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      status == 'completed'
                          ? Icons.check
                          : status ==
                                  'rejected'
                              ? Icons.close
                              : Icons
                                  .hourglass_top,
                    ),
                  ),
                  title: Text(
                    _money(amount),
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '$method • $account\nStatus: $status',
                  ),
                  isThreeLine: true,
                  trailing:
                      status == 'pending'
                          ? TextButton(
                              onPressed: () {
                                _cancel(
                                  context,
                                  doc.id,
                                );
                              },
                              child:
                                  const Text(
                                'Cancel',
                              ),
                            )
                          : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _cancel(
    BuildContext context,
    String requestId,
  ) async {
    try {
      await _service
          .cancelWithdrawRequest(
        requestId,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Withdraw request বাতিল হয়েছে।',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
        ),
      );
    }
  }
}

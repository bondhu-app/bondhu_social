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

  bool _isProcessing = false;

  // ============================================================
  // WITHDRAW DIALOG
  // ============================================================

  Future<void> _showWithdrawDialog() async {
    final amountController = TextEditingController();
    final accountController = TextEditingController();

    String selectedMethod = 'bKash';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Withdraw Request',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedMethod,
                      decoration: const InputDecoration(
                        labelText: 'Payment Method',
                        border: OutlineInputBorder(),
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

                        setDialogState(() {
                          selectedMethod = value;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: accountController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Payment Account',
                        hintText: 'মোবাইল নম্বর / Account',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Withdraw Amount',
                        hintText: 'যেমন: 100',
                        prefixText: '৳ ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final amount = double.tryParse(
                      amountController.text.trim(),
                    );

                    final account =
                        accountController.text.trim();

                    if (amount == null || amount <= 0) {
                      _showMessage(
                        'সঠিক Withdraw Amount দিন।',
                      );
                      return;
                    }

                    if (account.isEmpty) {
                      _showMessage(
                        'Payment Account দিন।',
                      );
                      return;
                    }

                    Navigator.pop(dialogContext);

                    await _createWithdrawRequest(
                      amount: amount,
                      method: selectedMethod,
                      account: account,
                    );
                  },
                  child: const Text('Request'),
                ),
              ],
            );
          },
        );
      },
    );

    amountController.dispose();
    accountController.dispose();
  }

  // ============================================================
  // CREATE WITHDRAW
  // ============================================================

  Future<void> _createWithdrawRequest({
    required double amount,
    required String method,
    required String account,
  }) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await _earningsService.createWithdrawRequest(
        amount: amount,
        method: method,
        account: account,
      );

      if (!mounted) return;

      _showMessage(
        'Withdraw request সফলভাবে তৈরি হয়েছে।',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        _cleanError(e),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // ============================================================
  // CANCEL WITHDRAW
  // ============================================================

  Future<void> _cancelWithdraw(
    String requestId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel Withdraw?'),
          content: const Text(
            'এই Withdraw Request বাতিল করলে টাকা আবার Wallet-এ যোগ হবে।',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('না'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('হ্যাঁ, বাতিল করুন'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await _earningsService.cancelWithdrawRequest(
        requestId,
      );

      if (!mounted) return;

      _showMessage(
        'Withdraw Request বাতিল হয়েছে। টাকা Wallet-এ ফেরত এসেছে।',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        _cleanError(e),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String _cleanError(Object error) {
    final text = error.toString();

    if (text.startsWith('Exception: ')) {
      return text.substring(11);
    }

    return text;
  }

  // ============================================================
  // MONEY FORMAT
  // ============================================================

  String _money(dynamic value) {
    double amount = 0;

    if (value is num) {
      amount = value.toDouble();
    } else if (value is String) {
      amount = double.tryParse(value) ?? 0;
    }

    return '৳ ${amount.toStringAsFixed(2)}';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Earnings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        stream: _earningsService.walletStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _cleanError(snapshot.error!),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final data =
              snapshot.data?.data() ?? {};

          final balance =
              data['balance'] ?? 0;

          final totalEarned =
              data['totalEarned'] ?? 0;

          final totalWithdrawn =
              data['totalWithdrawn'] ?? 0;

          return RefreshIndicator(
            onRefresh: () async {
              await _earningsService
                  .createWalletIfNeeded();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ==================================================
                // BALANCE CARD
                // ==================================================

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context)
                            .colorScheme
                            .primary,
                        Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet,
                        size: 42,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Available Balance',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _money(balance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : _showWithdrawDialog,
                          icon: const Icon(
                            Icons.payments_outlined,
                          ),
                          label: const Text(
                            'Withdraw',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                Colors.white,
                            foregroundColor:
                                Theme.of(context)
                                    .colorScheme
                                    .primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ==================================================
                // SUMMARY
                // ==================================================

                Row(
                  children: [
                    Expanded(
                      child: _summaryCard(
                        title: 'Total Earned',
                        value: _money(totalEarned),
                        icon: Icons.trending_up,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _summaryCard(
                        title: 'Withdrawn',
                        value:
                            _money(totalWithdrawn),
                        icon: Icons
                            .account_balance_outlined,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ==================================================
                // TRANSACTIONS
                // ==================================================

                const Text(
                  'Transaction History',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                StreamBuilder<
                    QuerySnapshot<
                        Map<String, dynamic>>>(
                  stream: _earningsService
                      .myTransactionsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _errorBox(
                        _cleanError(
                          snapshot.error!,
                        ),
                      );
                    }

                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Padding(
                        padding:
                            EdgeInsets.all(24),
                        child: Center(
                          child:
                              CircularProgressIndicator(),
                        ),
                      );
                    }

                    final docs =
                        snapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return _emptyBox(
                        icon:
                            Icons.receipt_long_outlined,
                        text:
                            'এখনও কোনো Transaction নেই।',
                      );
                    }

                    return Column(
                      children: docs
                          .map(
                            (doc) =>
                                _transactionTile(
                              doc,
                            ),
                          )
                          .toList(),
                    );
                  },
                ),

                const SizedBox(height: 28),

                // ==================================================
                // WITHDRAW REQUESTS
                // ==================================================

                const Text(
                  'Withdraw Requests',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                StreamBuilder<
                    QuerySnapshot<
                        Map<String, dynamic>>>(
                  stream: _earningsService
                      .myWithdrawRequestsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _errorBox(
                        _cleanError(
                          snapshot.error!,
                        ),
                      );
                    }

                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Padding(
                        padding:
                            EdgeInsets.all(24),
                        child: Center(
                          child:
                              CircularProgressIndicator(),
                        ),
                      );
                    }

                    final docs =
                        snapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return _emptyBox(
                        icon: Icons.payments_outlined,
                        text:
                            'এখনও কোনো Withdraw Request নেই।',
                      );
                    }

                    return Column(
                      children: docs
                          .map(
                            (doc) =>
                                _withdrawTile(
                              doc,
                            ),
                          )
                          .toList(),
                    );
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TRANSACTION TILE
  // ============================================================

  Widget _transactionTile(
    QueryDocumentSnapshot<Map<String, dynamic>>
        doc,
  ) {
    final data = doc.data();

    final amount =
        _money(data['amount']);

    final type =
        data['type']?.toString() ??
            'Transaction';

    final status =
        data['status']?.toString() ??
            'unknown';

    final description =
        data['description']?.toString() ??
            '';

    final isWithdrawal =
        data['transactionType'] ==
            'withdrawal';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(
        bottom: 8,
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            isWithdrawal
                ? Icons.arrow_upward
                : Icons.arrow_downward,
          ),
        ),
        title: Text(
          type,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          description.isEmpty
              ? status
              : '$description • $status',
        ),
        trailing: Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isWithdrawal
                ? Colors.red
                : Colors.green,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // WITHDRAW TILE
  // ============================================================

  Widget _withdrawTile(
    QueryDocumentSnapshot<Map<String, dynamic>>
        doc,
  ) {
    final data = doc.data();

    final amount =
        _money(data['amount']);

    final method =
        data['method']?.toString() ??
            '';

    final account =
        data['account']?.toString() ??
            '';

    final status =
        data['status']?.toString() ??
            'unknown';

    final requestId = doc.id;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(
        bottom: 8,
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
                  Icons.payments_outlined,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    amount,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _statusChip(status),
              ],
            ),
            const SizedBox(height: 10),
            Text('Method: $method'),
            const SizedBox(height: 4),
            Text('Account: $account'),
            if (status == 'pending') ...[
              const SizedBox(height: 12),
              Align(
                alignment:
                    Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () =>
                          _cancelWithdraw(
                            requestId,
                          ),
                  icon: const Icon(
                    Icons.cancel_outlined,
                  ),
                  label: const Text(
                    'Cancel Request',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATUS CHIP
  // ============================================================

  Widget _statusChip(String status) {
    String label;

    switch (status) {
      case 'pending':
        label = 'Pending';
        break;
      case 'completed':
        label = 'Completed';
        break;
      case 'cancelled':
        label = 'Cancelled';
        break;
      case 'rejected':
        label = 'Rejected';
        break;
      default:
        label = status;
    }

    return Chip(
      label: Text(label),
      visualDensity:
          VisualDensity.compact,
    );
  }

  // ============================================================
  // EMPTY BOX
  // ============================================================

  Widget _emptyBox({
    required IconData icon,
    required String text,
  }) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 30,
          horizontal: 16,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 42,
            ),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR BOX
  // ============================================================

  Widget _errorBox(String text) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          text,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

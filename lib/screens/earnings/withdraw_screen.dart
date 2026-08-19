import 'package:flutter/material.dart';

import '../../services/earnings_service.dart';

class WithdrawScreen extends StatefulWidget {
  WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final EarningsService _earningsService =
      EarningsService.instance;

  final TextEditingController _amountController =
      TextEditingController();

  final TextEditingController _accountController =
      TextEditingController();

  String _selectedMethod = 'bKash';

  bool _loading = false;

  double _balance = 0.0;

  @override
  void initState() {
    super.initState();

    _loadWallet();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accountController.dispose();

    super.dispose();
  }

  Future<void> _loadWallet() async {
    try {
      final wallet =
          await _earningsService.getWallet();

      if (!mounted) return;

      setState(() {
        _balance =
            (wallet['balance'] as num?)
                    ?.toDouble() ??
                0.0;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
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

  double _getAmount() {
    return double.tryParse(
          _amountController.text.trim(),
        ) ??
        0.0;
  }

  String _money(double amount) {
    return '৳${amount.toStringAsFixed(2)}';
  }

  Future<void> _submitWithdraw() async {
    FocusScope.of(context).unfocus();

    final amount = _getAmount();

    final account =
        _accountController.text.trim();

    if (amount <= 0) {
      _showError(
        'সঠিক Withdraw amount দিন।',
      );
      return;
    }

    if (amount <
        EarningsService.minimumWithdrawAmount) {
      _showError(
        'Minimum Withdraw হলো '
        '৳${EarningsService.minimumWithdrawAmount.toStringAsFixed(0)}।',
      );
      return;
    }

    if (amount > _balance) {
      _showError(
        'আপনার Wallet-এ পর্যাপ্ত টাকা নেই।',
      );
      return;
    }

    if (account.isEmpty) {
      _showError(
        'Payment account number দিন।',
      );
      return;
    }

    if (_selectedMethod != 'Bank' &&
        !_isValidMobile(account)) {
      _showError(
        'সঠিক 11 সংখ্যার মোবাইল নম্বর দিন।',
      );
      return;
    }

    if (_selectedMethod == 'Bank' &&
        account.length < 5) {
      _showError(
        'সঠিক Bank Account Number দিন।',
      );
      return;
    }

    final confirm =
        await _showConfirmation(amount);

    if (confirm != true) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await _earningsService.createWithdrawRequest(
        amount: amount,
        method: _selectedMethod,
        account: account,
      );

      if (!mounted) return;

      await _loadWallet();

      _amountController.clear();
      _accountController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Withdraw request সফলভাবে পাঠানো হয়েছে।',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
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

  bool _isValidMobile(String value) {
    final cleaned =
        value.replaceAll(' ', '');

    final regex =
        RegExp(r'^01[3-9]\d{8}$');

    return regex.hasMatch(cleaned);
  }

  Future<bool?> _showConfirmation(
    double amount,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Withdraw Confirm',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Amount: ${_money(amount)}',
              ),
              const SizedBox(height: 8),
              Text(
                'Method: $_selectedMethod',
              ),
              const SizedBox(height: 8),
              Text(
                'Account: ${_accountController.text.trim()}',
              ),
              const SizedBox(height: 15),
              const Text(
                'আপনি কি এই Withdraw request পাঠাতে চান?',
              ),
            ],
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
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _setFullBalance() {
    if (_balance <
        EarningsService.minimumWithdrawAmount) {
      _showError(
        'Minimum Withdraw হলো ৳100।',
      );
      return;
    }

    _amountController.text =
        _balance.toStringAsFixed(2);
  }

  Widget _methodButton({
    required String title,
    required IconData icon,
  }) {
    final selected =
        _selectedMethod == title;

    return Expanded(
      child: GestureDetector(
        onTap: _loading
            ? null
            : () {
                setState(() {
                  _selectedMethod = title;
                });
              },
        child: Container(
          margin:
              const EdgeInsets.symmetric(
            horizontal: 4,
          ),
          padding:
              const EdgeInsets.symmetric(
            vertical: 14,
          ),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? Theme.of(context)
                      .colorScheme
                      .primary
                  : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
            color: selected
                ? Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(.08)
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 28,
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style: TextStyle(
                  fontWeight: selected
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Withdraw',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadWallet,
        child: ListView(
          padding:
              const EdgeInsets.all(16),
          children: [
            // ==================================================
            // BALANCE CARD
            // ==================================================

            Card(
              elevation: 2,
              child: Padding(
                padding:
                    const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons
                          .account_balance_wallet,
                      size: 45,
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
                      _money(_balance),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // MINIMUM
            // ==================================================

            Container(
              padding:
                  const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange
                      .withOpacity(.5),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Minimum Withdraw: ৳100',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // PAYMENT METHOD
            // ==================================================

            const Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                _methodButton(
                  title: 'bKash',
                  icon: Icons.phone_android,
                ),
                _methodButton(
                  title: 'Nagad',
                  icon: Icons.phone_android,
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                _methodButton(
                  title: 'Rocket',
                  icon: Icons.phone_android,
                ),
                _methodButton(
                  title: 'Bank',
                  icon: Icons.account_balance,
                ),
              ],
            ),

            const SizedBox(height: 25),

            // ==================================================
            // AMOUNT
            // ==================================================

            const Text(
              'Withdraw Amount',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller:
                  _amountController,
              keyboardType:
                  const TextInputType
                      .numberWithOptions(
                decimal: true,
              ),
              enabled: !_loading,
              decoration:
                  InputDecoration(
                prefixText: '৳ ',
                hintText: 'যেমন: 100',
                border:
                    const OutlineInputBorder(),
                suffixIcon:
                    TextButton(
                  onPressed:
                      _loading
                          ? null
                          : _setFullBalance,
                  child: const Text(
                    'MAX',
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // ACCOUNT
            // ==================================================

            Text(
              _selectedMethod == 'Bank'
                  ? 'Bank Account Number'
                  : '$_selectedMethod Number',
              style: const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller:
                  _accountController,
              keyboardType:
                  TextInputType.phone,
              enabled: !_loading,
              decoration:
                  InputDecoration(
                hintText:
                    _selectedMethod ==
                            'Bank'
                        ? 'Bank Account Number'
                        : '01XXXXXXXXX',
                border:
                    const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            // ==================================================
            // SUBMIT
            // ==================================================

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _loading
                    ? null
                    : _submitWithdraw,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.send,
                      ),
                label: Text(
                  _loading
                      ? 'Processing...'
                      : 'Withdraw Request পাঠান',
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // NOTE
            // ==================================================

            const Card(
              child: Padding(
                padding:
                    EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'গুরুত্বপূর্ণ',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Withdraw request পাঠানোর পর '
                      'Admin request যাচাই করে payment করবে। '
                      'Pending request চাইলে Earnings & Wallet '
                      'থেকে cancel করা যাবে।',
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
}

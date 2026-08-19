import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/earnings_service.dart';

class AdminWithdrawalsScreen extends StatefulWidget {
  const AdminWithdrawalsScreen({super.key});

  @override
  State<AdminWithdrawalsScreen> createState() =>
      _AdminWithdrawalsScreenState();
}

class _AdminWithdrawalsScreenState
    extends State<AdminWithdrawalsScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final EarningsService _earningsService =
      EarningsService.instance;

  bool _processing = false;

  // ============================================================
  // MONEY
  // ============================================================

  String _money(dynamic value) {
    double amount = 0;

    if (value is num) {
      amount = value.toDouble();
    } else if (value is String) {
      amount = double.tryParse(value) ?? 0;
    }

    return '৳${amount.toStringAsFixed(2)}';
  }

  // ============================================================
  // DATE
  // ============================================================

  String _date(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();

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

    return 'তারিখ পাওয়া যায়নি';
  }

  // ============================================================
  // GET WITHDRAW REQUESTS
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _withdrawStream() {
    return _firestore
        .collection('withdraw_requests')
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots();
  }

  // ============================================================
  // APPROVE WITHDRAW
  // ============================================================

  Future<void> _approveWithdraw(
    String requestId,
    Map<String, dynamic> data,
  ) async {
    if (_processing) return;

    final status =
        data['status']?.toString() ?? '';

    if (status != 'pending') {
      _showMessage(
        'এই request আর pending নেই।',
      );

      return;
    }

    final amount =
        _toDouble(data['amount']);

    final userId =
        data['userId']?.toString() ?? '';

    if (userId.isEmpty) {
      _showMessage(
        'User ID পাওয়া যায়নি।',
      );

      return;
    }

    if (amount <= 0) {
      _showMessage(
        'Withdraw amount সঠিক নয়।',
      );

      return;
    }

    final confirmed =
        await _confirmDialog(
      title: 'Withdraw Approve',
      message:
          'আপনি কি ${_money(amount)} withdraw approve করতে চান?',
      confirmText: 'Approve',
    );

    if (!confirmed) return;

    setState(() {
      _processing = true;
    });

    try {
      final withdrawRef =
          _firestore
              .collection('withdraw_requests')
              .doc(requestId);

      final userRef =
          _firestore
              .collection('users')
              .doc(userId);

      final transactionQuery =
          await _firestore
              .collection('transactions')
              .where(
                'referenceId',
                isEqualTo: requestId,
              )
              .limit(1)
              .get();

      await _firestore.runTransaction(
        (transaction) async {
          final withdrawSnapshot =
              await transaction.get(
            withdrawRef,
          );

          if (!withdrawSnapshot.exists) {
            throw Exception(
              'Withdraw request পাওয়া যায়নি।',
            );
          }

          final withdrawData =
              withdrawSnapshot.data() ?? {};

          final currentStatus =
              withdrawData['status']
                      ?.toString() ??
                  '';

          if (currentStatus != 'pending') {
            throw Exception(
              'এই request আর pending নেই।',
            );
          }

          final userSnapshot =
              await transaction.get(
            userRef,
          );

          if (!userSnapshot.exists) {
            throw Exception(
              'User profile পাওয়া যায়নি।',
            );
          }

          final userData =
              userSnapshot.data() ?? {};

          final currentTotalWithdrawn =
              _toDouble(
            userData['totalWithdrawn'],
          );

          transaction.update(
            withdrawRef,
            {
              'status': 'approved',
              'approvedAt':
                  FieldValue.serverTimestamp(),
              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
          );

          // ------------------------------------------------------
          // Transaction history
          // ------------------------------------------------------

          if (transactionQuery.docs.isNotEmpty) {
            transaction.update(
              transactionQuery.docs.first.reference,
              {
                'status': 'completed',
                'updatedAt':
                    FieldValue.serverTimestamp(),
              },
            );
          }

          // ------------------------------------------------------
          // Owner wallet
          // ------------------------------------------------------

          final ownerRef =
              _firestore
                  .collection('settings')
                  .doc('owner_wallet');

          final ownerSnapshot =
              await transaction.get(
            ownerRef,
          );

          final ownerData =
              ownerSnapshot.data() ?? {};

          final ownerBalance =
              _toDouble(
            ownerData['balance'],
          );

          final ownerTotalPaid =
              _toDouble(
            ownerData['totalPaidToUsers'],
          );

          transaction.set(
            ownerRef,
            {
              'balance':
                  ownerBalance - amount,

              'totalPaidToUsers':
                  ownerTotalPaid + amount,

              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        },
      );

      if (!mounted) return;

      _showMessage(
        'Withdraw successfully approved হয়েছে।',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  // ============================================================
  // REJECT WITHDRAW
  // ============================================================

  Future<void> _rejectWithdraw(
    String requestId,
    Map<String, dynamic> data,
  ) async {
    if (_processing) return;

    final status =
        data['status']?.toString() ?? '';

    if (status != 'pending') {
      _showMessage(
        'এই request আর pending নেই।',
      );

      return;
    }

    final amount =
        _toDouble(data['amount']);

    final userId =
        data['userId']?.toString() ?? '';

    if (userId.isEmpty) {
      _showMessage(
        'User ID পাওয়া যায়নি।',
      );

      return;
    }

    final confirmed =
        await _confirmDialog(
      title: 'Withdraw Reject',
      message:
          'আপনি কি ${_money(amount)} withdraw request reject করতে চান?\n\nReject করলে টাকা User-এর wallet-এ ফেরত যাবে।',
      confirmText: 'Reject',
    );

    if (!confirmed) return;

    setState(() {
      _processing = true;
    });

    try {
      final withdrawRef =
          _firestore
              .collection('withdraw_requests')
              .doc(requestId);

      final userRef =
          _firestore
              .collection('users')
              .doc(userId);

      final transactionQuery =
          await _firestore
              .collection('transactions')
              .where(
                'referenceId',
                isEqualTo: requestId,
              )
              .limit(1)
              .get();

      await _firestore.runTransaction(
        (transaction) async {
          final withdrawSnapshot =
              await transaction.get(
            withdrawRef,
          );

          if (!withdrawSnapshot.exists) {
            throw Exception(
              'Withdraw request পাওয়া যায়নি।',
            );
          }

          final withdrawData =
              withdrawSnapshot.data() ?? {};

          final currentStatus =
              withdrawData['status']
                      ?.toString() ??
                  '';

          if (currentStatus != 'pending') {
            throw Exception(
              'এই request আর pending নেই।',
            );
          }

          final userSnapshot =
              await transaction.get(
            userRef,
          );

          if (!userSnapshot.exists) {
            throw Exception(
              'User profile পাওয়া যায়নি।',
            );
          }

          final userData =
              userSnapshot.data() ?? {};

          final currentBalance =
              _toDouble(
            userData['balance'],
          );

          final currentTotalWithdrawn =
              _toDouble(
            userData['totalWithdrawn'],
          );

          final newTotalWithdrawn =
              currentTotalWithdrawn >= amount
                  ? currentTotalWithdrawn -
                      amount
                  : 0.0;

          // ------------------------------------------------------
          // Return money to user wallet
          // ------------------------------------------------------

          transaction.set(
            userRef,
            {
              'balance':
                  currentBalance + amount,

              'totalWithdrawn':
                  newTotalWithdrawn,

              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

          // ------------------------------------------------------
          // Update withdraw request
          // ------------------------------------------------------

          transaction.update(
            withdrawRef,
            {
              'status': 'rejected',
              'rejectedAt':
                  FieldValue.serverTimestamp(),
              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
          );

          // ------------------------------------------------------
          // Update transaction history
          // ------------------------------------------------------

          if (transactionQuery.docs.isNotEmpty) {
            transaction.update(
              transactionQuery.docs.first.reference,
              {
                'status': 'rejected',
                'updatedAt':
                    FieldValue.serverTimestamp(),
              },
            );
          }
        },
      );

      if (!mounted) return;

      _showMessage(
        'Withdraw reject হয়েছে এবং টাকা User-এর wallet-এ ফেরত গেছে।',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  // ============================================================
  // CONFIRM DIALOG
  // ============================================================

  Future<bool> _confirmDialog({
    required String title,
    required String message,
    required String confirmText,
  }) async {
    final result =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: Text(
                confirmText,
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // DOUBLE
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
  // STATUS COLOR
  // ============================================================

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;

      case 'rejected':
      case 'cancelled':
        return Colors.red;

      case 'pending':
        return Colors.orange;

      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // REQUEST CARD
  // ============================================================

  Widget _requestCard(
    String requestId,
    Map<String, dynamic> data,
  ) {
    final amount =
        _toDouble(data['amount']);

    final userId =
        data['userId']?.toString() ?? '';

    final method =
        data['method']?.toString() ?? '';

    final account =
        data['account']?.toString() ?? '';

    final status =
        data['status']?.toString() ??
            'unknown';

    final createdAt =
        data['createdAt'];

    final isPending =
        status == 'pending';

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  child: Icon(
                    Icons.payments,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        _money(amount),
                        style:
                            const TextStyle(
                          fontSize: 22,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 3,
                      ),

                      Text(
                        '$method • $account',
                        style:
                            const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration:
                      BoxDecoration(
                    color: _statusColor(
                      status,
                    ).withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color:
                          _statusColor(
                        status,
                      ),
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(
              height: 25,
            ),

            Text(
              'User ID:',
              style: const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 3),

            SelectableText(
              userId,
              style:
                  const TextStyle(
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Request ID:',
              style: const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 3),

            SelectableText(
              requestId,
              style:
                  const TextStyle(
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Created: ${_date(createdAt)}',
              style:
                  const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),

            if (isPending) ...[
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _processing
                              ? null
                              : () =>
                                  _rejectWithdraw(
                                    requestId,
                                    data,
                                  ),
                      icon: const Icon(
                        Icons.close,
                      ),
                      label: const Text(
                        'Reject',
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          _processing
                              ? null
                              : () =>
                                  _approveWithdraw(
                                    requestId,
                                    data,
                                  ),
                      icon: const Icon(
                        Icons.check,
                      ),
                      label: const Text(
                        'Approve',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Withdrawals',
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: _withdrawStream(),
        builder: (context, snapshot) {
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
                    const EdgeInsets.all(20),
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

          final docs =
              snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: ListView(
                children: const [
                  SizedBox(height: 180),
                  Center(
                    child: Text(
                      'কোনো withdraw request নেই।',
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              padding:
                  const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder:
                  (context, index) {
                final doc = docs[index];

                return _requestCard(
                  doc.id,
                  doc.data(),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

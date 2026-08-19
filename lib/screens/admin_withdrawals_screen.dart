import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminWithdrawScreen extends StatefulWidget {
  const AdminWithdrawScreen({super.key});

  @override
  State<AdminWithdrawScreen> createState() =>
      _AdminWithdrawScreenState();
}

class _AdminWithdrawScreenState
    extends State<AdminWithdrawScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  bool _processing = false;

  CollectionReference<Map<String, dynamic>>
      get _withdrawRequests =>
          _firestore.collection('withdraw_requests');

  CollectionReference<Map<String, dynamic>>
      get _users =>
          _firestore.collection('users');

  CollectionReference<Map<String, dynamic>>
      get _transactions =>
          _firestore.collection('transactions');

  DocumentReference<Map<String, dynamic>>
      get _ownerWallet =>
          _firestore
              .collection('settings')
              .doc('owner_wallet');

  // ============================================================
  // HELPERS
  // ============================================================

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }

    return 0.0;
  }

  String _money(dynamic value) {
    return '৳${_toDouble(value).toStringAsFixed(2)}';
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '');
  }

  String _statusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';

      case 'approved':
        return 'Approved';

      case 'rejected':
        return 'Rejected';

      case 'cancelled':
        return 'Cancelled';

      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;

      case 'approved':
        return Colors.green;

      case 'rejected':
        return Colors.red;

      case 'cancelled':
        return Colors.grey;

      default:
        return Colors.blueGrey;
    }
  }

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    }

    return 'সময় পাওয়া যায়নি';
  }

  // ============================================================
  // APPROVE CONFIRMATION
  // ============================================================

  Future<void> _approveRequest(
    String requestId,
  ) async {
    final confirmed = await _showConfirmDialog(
      title: 'Withdraw Approve',
      message:
          'আপনি কি এই withdraw request approve করতে চান?',
      confirmText: 'Approve',
    );

    if (!confirmed) {
      return;
    }

    setState(() {
      _processing = true;
    });

    try {
      await _approveWithdraw(requestId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Withdraw request সফলভাবে approve হয়েছে।',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _cleanError(e),
          ),
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
  // APPROVE WITHDRAW
  // ============================================================

  Future<void> _approveWithdraw(
    String requestId,
  ) async {
    final requestRef =
        _withdrawRequests.doc(requestId);

    await _firestore.runTransaction(
      (transaction) async {
        final requestSnapshot =
            await transaction.get(requestRef);

        if (!requestSnapshot.exists) {
          throw Exception(
            'Withdraw request পাওয়া যায়নি।',
          );
        }

        final requestData =
            requestSnapshot.data() ?? {};

        final status =
            requestData['status']
                    ?.toString() ??
                '';

        if (status != 'pending') {
          throw Exception(
            'এই request আর pending নেই।',
          );
        }

        final userId =
            requestData['userId']
                    ?.toString() ??
                '';

        if (userId.isEmpty) {
          throw Exception(
            'User ID পাওয়া যায়নি।',
          );
        }

        final amount =
            _toDouble(
          requestData['amount'],
        );

        if (amount <= 0) {
          throw Exception(
            'Withdraw amount সঠিক নয়।',
          );
        }

        final userRef =
            _users.doc(userId);

        final userSnapshot =
            await transaction.get(userRef);

        if (!userSnapshot.exists) {
          throw Exception(
            'User profile পাওয়া যায়নি।',
          );
        }

        final ownerSnapshot =
            await transaction.get(
          _ownerWallet,
        );

        final ownerData =
            ownerSnapshot.data() ?? {};

        final ownerBalance =
            _toDouble(
          ownerData['balance'],
        );

        if (ownerBalance < amount) {
          throw Exception(
            'Owner wallet-এ পর্যাপ্ত টাকা নেই। '
            'বর্তমান balance: ${_money(ownerBalance)}',
          );
        }

        final totalPaidToUsers =
            _toDouble(
          ownerData['totalPaidToUsers'],
        );

        // --------------------------------------------------------
        // OWNER WALLET
        // --------------------------------------------------------

        transaction.set(
          _ownerWallet,
          {
            'balance':
                ownerBalance - amount,

            'totalPaidToUsers':
                totalPaidToUsers + amount,

            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        // --------------------------------------------------------
        // WITHDRAW REQUEST
        // --------------------------------------------------------

        transaction.update(
          requestRef,
          {
            'status':
                'approved',

            'approvedAt':
                FieldValue.serverTimestamp(),

            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );

        // --------------------------------------------------------
        // TRANSACTION HISTORY
        // --------------------------------------------------------

        final transactionRef =
            _transactions.doc();

        transaction.set(
          transactionRef,
          {
            'userId':
                userId,

            'amount':
                amount,

            'type':
                'withdraw_approved',

            'description':
                'Withdrawal approved',

            'referenceId':
                requestId,

            'status':
                'completed',

            'transactionType':
                'withdrawal',

            'createdAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }

  // ============================================================
  // REJECT
  // ============================================================

  Future<void> _rejectRequest(
    String requestId,
  ) async {
    final reason =
        await _showRejectDialog();

    if (reason == null) {
      return;
    }

    setState(() {
      _processing = true;
    });

    try {
      await _rejectWithdraw(
        requestId,
        reason,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Withdraw reject হয়েছে এবং টাকা User Wallet-এ ফেরত দেওয়া হয়েছে।',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _cleanError(e),
          ),
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
    String reason,
  ) async {
    final requestRef =
        _withdrawRequests.doc(requestId);

    await _firestore.runTransaction(
      (transaction) async {
        final requestSnapshot =
            await transaction.get(requestRef);

        if (!requestSnapshot.exists) {
          throw Exception(
            'Withdraw request পাওয়া যায়নি।',
          );
        }

        final requestData =
            requestSnapshot.data() ?? {};

        final status =
            requestData['status']
                    ?.toString() ??
                '';

        if (status != 'pending') {
          throw Exception(
            'এই request আর pending নেই।',
          );
        }

        final userId =
            requestData['userId']
                    ?.toString() ??
                '';

        if (userId.isEmpty) {
          throw Exception(
            'User ID পাওয়া যায়নি।',
          );
        }

        final amount =
            _toDouble(
          requestData['amount'],
        );

        if (amount <= 0) {
          throw Exception(
            'Withdraw amount সঠিক নয়।',
          );
        }

        final userRef =
            _users.doc(userId);

        final userSnapshot =
            await transaction.get(userRef);

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
                ? currentTotalWithdrawn - amount
                : 0.0;

        // --------------------------------------------------------
        // USER WALLET-এ টাকা ফেরত
        // --------------------------------------------------------

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

        // --------------------------------------------------------
        // WITHDRAW REQUEST
        // --------------------------------------------------------

        transaction.update(
          requestRef,
          {
            'status':
                'rejected',

            'rejectionReason':
                reason,

            'rejectedAt':
                FieldValue.serverTimestamp(),

            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );

        // --------------------------------------------------------
        // TRANSACTION HISTORY
        // --------------------------------------------------------

        final transactionQuery =
            await _transactions
                .where(
                  'userId',
                  isEqualTo: userId,
                )
                .where(
                  'referenceId',
                  isEqualTo: requestId,
                )
                .limit(1)
                .get();

        if (transactionQuery.docs.isNotEmpty) {
          transaction.update(
            transactionQuery.docs.first.reference,
            {
              'status':
                  'rejected',

              'description':
                  'Withdrawal rejected: $reason',

              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
          );
        }
      },
    );
  }

  // ============================================================
  // CONFIRM DIALOG
  // ============================================================

  Future<bool> _showConfirmDialog({
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
  // REJECT DIALOG
  // ============================================================

  Future<String?> _showRejectDialog() async {
    final controller =
        TextEditingController();

    final result =
        await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Reject Withdraw',
          ),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration:
                const InputDecoration(
              labelText:
                  'Reject Reason',
              hintText:
                  'Reject করার কারণ লিখুন',
              border:
                  OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final reason =
                    controller.text.trim();

                Navigator.pop(
                  context,
                  reason.isEmpty
                      ? 'Admin rejected'
                      : reason,
                );
              },
              child: const Text(
                'Reject',
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    return result;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Withdraw Requests',
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: _withdrawRequests
            .orderBy(
              'createdAt',
              descending: true,
            )
            .snapshots(),
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
                    const EdgeInsets.all(20),
                child: Text(
                  _cleanError(
                    snapshot.error!,
                  ),
                ),
              ),
            );
          }

          final docs =
              snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'কোনো withdraw request নেই।',
                style:
                    TextStyle(fontSize: 16),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await _withdrawRequests
                  .orderBy(
                    'createdAt',
                    descending: true,
                  )
                  .get();
            },
            child: ListView.builder(
              padding:
                  const EdgeInsets.all(12),
              itemCount: docs.length,
              itemBuilder:
                  (context, index) {
                final doc =
                    docs[index];

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

  // ============================================================
  // REQUEST CARD
  // ============================================================

  Widget _requestCard(
    String requestId,
    Map<String, dynamic> data,
  ) {
    final amount =
        _toDouble(
      data['amount'],
    );

    final userId =
        data['userId']
                ?.toString() ??
            '';

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
            'unknown';

    final reason =
        data['rejectionReason']
                ?.toString() ??
            '';

    final createdAt =
        _formatDate(
      data['createdAt'],
    );

    final statusColor =
        _statusColor(status);

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      elevation: 2,
      child: Padding(
        padding:
            const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Icon(
                    method == 'Bank'
                        ? Icons
                            .account_balance
                        : Icons
                            .account_balance_wallet,
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        _money(amount),
                        style:
                            const TextStyle(
                          fontSize: 21,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 4,
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
                    color:
                        statusColor.withOpacity(
                      0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Text(
                    _statusText(status),
                    style: TextStyle(
                      color:
                          statusColor,
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

            const Text(
              'User ID',
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            SelectableText(
              userId,
              style:
                  const TextStyle(
                fontSize: 13,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              'Request ID: $requestId',
              style:
                  const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              'Created: $createdAt',
              style:
                  const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),

            if (reason.isNotEmpty) ...[
              const SizedBox(
                height: 10,
              ),
              Text(
                'Reject reason: $reason',
                style:
                    const TextStyle(
                  color: Colors.red,
                ),
              ),
            ],

            if (status == 'pending') ...[
              const SizedBox(
                height: 16,
              ),
              Row(
                children: [
                  Expanded(
                    child:
                        OutlinedButton.icon(
                      onPressed:
                          _processing
                              ? null
                              : () =>
                                  _rejectRequest(
                                    requestId,
                                  ),
                      icon:
                          const Icon(
                        Icons.close,
                        color:
                            Colors.red,
                      ),
                      label:
                          const Text(
                        'Reject',
                        style:
                            TextStyle(
                          color:
                              Colors.red,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child:
                        ElevatedButton.icon(
                      onPressed:
                          _processing
                              ? null
                              : () =>
                                  _approveRequest(
                                    requestId,
                                  ),
                      icon:
                          const Icon(
                        Icons.check,
                      ),
                      label:
                          const Text(
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
}

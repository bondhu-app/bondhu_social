import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/earnings_service.dart';

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

  bool _loading = false;

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

  String _money(dynamic value) {
    double amount = 0;

    if (value is num) {
      amount = value.toDouble();
    } else if (value is String) {
      amount = double.tryParse(value) ?? 0;
    }

    return '৳${amount.toStringAsFixed(2)}';
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
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

  Future<void> _approveRequest(
    String requestId,
  ) async {
    final confirm =
        await _showConfirmDialog(
      title: 'Approve Withdraw?',
      message:
          'এই withdraw request approve করতে চান?',
      confirmText: 'Approve',
    );

    if (!confirm) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await _processApprove(requestId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Withdraw request approve হয়েছে।',
          ),
        ),
      );
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

  Future<void> _processApprove(
    String requestId,
  ) async {
    final requestRef =
        _withdrawRequests.doc(requestId);

    final transactionRef =
        _transactions.doc();

    await _firestore.runTransaction(
      (transaction) async {
        final requestSnapshot =
            await transaction.get(
          requestRef,
        );

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

        final totalWithdrawn =
            _toDouble(
          userData['totalWithdrawn'],
        );

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

        final ownerTotalPaid =
            _toDouble(
          ownerData['totalPaidToUsers'],
        );

        transaction.set(
          _ownerWallet,
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

        transaction.set(
          userRef,
          {
            'totalWithdrawn':
                totalWithdrawn,

            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      },
    );
  }

  Future<void> _rejectRequest(
    String requestId,
  ) async {
    final reason =
        await _showRejectDialog();

    if (reason == null) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await _processReject(
        requestId,
        reason,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Withdraw request reject হয়েছে এবং টাকা User Wallet-এ ফেরত দেওয়া হয়েছে।',
          ),
        ),
      );
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

  Future<void> _processReject(
    String requestId,
    String reason,
  ) async {
    final requestRef =
        _withdrawRequests.doc(requestId);

    final transactionQuery =
        await _transactions
            .where(
              'referenceId',
              isEqualTo: requestId,
            )
            .limit(1)
            .get();

    await _firestore.runTransaction(
      (transaction) async {
        final requestSnapshot =
            await transaction.get(
          requestRef,
        );

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
                ? currentTotalWithdrawn - amount
                : 0.0;

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

        if (transactionQuery.docs.isNotEmpty) {
          final transactionDoc =
              transactionQuery.docs.first;

          transaction.update(
            transactionDoc.reference,
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
                  'Reject reason',
              hintText:
                  'কেন reject করা হচ্ছে?',
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

  String _formatDate(
    dynamic value,
  ) {
    if (value is Timestamp) {
      final date =
          value.toDate();

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    }

    return 'সময় পাওয়া যায়নি';
  }

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

                final data =
                    doc.data();

                return _requestCard(
                  doc.id,
                  data,
                );
              },
            ),
          );
        },
      ),
    );
  }

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
                        CrossAxisAlignment
                            .start,
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
                      const EdgeInsets
                          .symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration:
                      BoxDecoration(
                    color: statusColor
                        .withOpacity(
                      0.12,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(
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

            Text(
              'User ID:',
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 3,
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
                color:
                    Colors.grey,
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            Text(
              'Created: $createdAt',
              style:
                  const TextStyle(
                fontSize: 12,
                color:
                    Colors.grey,
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
                height: 15,
              ),

              Row(
                children: [
                  Expanded(
                    child:
                        OutlinedButton.icon(
                      onPressed:
                          _loading
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
                          _loading
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

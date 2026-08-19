import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminWithdrawScreen extends StatelessWidget {
  const AdminWithdrawScreen({super.key});

  FirebaseFirestore get _firestore =>
      FirebaseFirestore.instance;

  // ============================================================
  // MONEY
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

  String _money(dynamic value) {
    return '৳${_toDouble(value).toStringAsFixed(2)}';
  }

  // ============================================================
  // WITHDRAW REQUESTS
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),

      appBar: AppBar(
        title: const Text(
          'Manage Withdrawals',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: _withdrawStream(),
        builder: (
          context,
          snapshot,
        ) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
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
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final requests =
              snapshot.data?.docs ?? [];

          if (requests.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons
                        .check_circle_outline,
                    size: 70,
                  ),
                  SizedBox(height: 15),
                  Text(
                    'কোনো Withdraw Request নেই',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding:
                const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (
              context,
              index,
            ) {
              final document =
                  requests[index];

              final data =
                  document.data();

              return _withdrawCard(
                context,
                document.id,
                data,
              );
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // WITHDRAW CARD
  // ============================================================

  Widget _withdrawCard(
    BuildContext context,
    String requestId,
    Map<String, dynamic> data,
  ) {
    final userId =
        data['userId']?.toString() ??
            '';

    final userName =
        data['userName']?.toString() ??
            'Unknown User';

    final amount =
        _toDouble(data['amount']);

    final method =
        data['method']?.toString() ??
            'Unknown';

    final account =
        data['account']?.toString() ??
            '';

    final status =
        data['status']?.toString() ??
            'pending';

    final createdAt =
        data['createdAt'];

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      elevation: 2,
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            // ==================================================
            // USER
            // ==================================================

            Row(
              children: [

                const CircleAvatar(
                  child: Icon(
                    Icons.person,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      Text(
                        userName,
                        style:
                            const TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        'User ID: $userId',
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            TextStyle(
                          fontSize: 11,
                          color: Colors
                              .grey
                              .shade700,
                        ),
                      ),
                    ],
                  ),
                ),

                _statusBadge(status),
              ],
            ),

            const Divider(
              height: 25,
            ),

            // ==================================================
            // AMOUNT
            // ==================================================

            Row(
              children: [

                const Icon(
                  Icons.payments,
                  size: 22,
                ),

                const SizedBox(width: 8),

                const Text(
                  'Amount:',
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(width: 8),

                Text(
                  _money(amount),
                  style:
                      const TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ==================================================
            // METHOD
            // ==================================================

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                const Icon(
                  Icons.account_balance,
                  size: 20,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      const Text(
                        'Payment Method',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        method,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ==================================================
            // ACCOUNT
            // ==================================================

            if (account.isNotEmpty)
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  const Icon(
                    Icons.phone_android,
                    size: 20,
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [

                        const Text(
                          'Account',
                          style:
                              TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          account,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 12),

            // ==================================================
            // DATE
            // ==================================================

            if (createdAt
                is Timestamp)
              Row(
                children: [

                  const Icon(
                    Icons.access_time,
                    size: 18,
                  ),

                  const SizedBox(width: 8),

                  Text(
                    _formatDate(
                      createdAt,
                    ),
                    style:
                        TextStyle(
                      color: Colors
                          .grey
                          .shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // ==================================================
            // ACTION BUTTONS
            // ==================================================

            if (status == 'pending')
              Row(
                children: [

                  Expanded(
                    child:
                        OutlinedButton.icon(
                      onPressed: () {
                        _showRejectDialog(
                          context,
                          requestId,
                        );
                      },
                      icon:
                          const Icon(
                        Icons.close,
                      ),
                      label:
                          const Text(
                        'Reject',
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child:
                        FilledButton.icon(
                      onPressed: () {
                        _showApproveDialog(
                          context,
                          requestId,
                          amount,
                        );
                      },
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
        ),
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge(
    String status,
  ) {
    String text;

    if (status == 'approved') {
      text = 'Approved';
    } else if (status == 'rejected') {
      text = 'Rejected';
    } else {
      text = 'Pending';
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey,
        ),
      ),
      child: Text(
        text,
        style:
            const TextStyle(
          fontSize: 12,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(
    Timestamp timestamp,
  ) {
    final date =
        timestamp.toDate();

    String twoDigits(int value) {
      return value
          .toString()
          .padLeft(2, '0');
    }

    return '${date.year}-'
        '${twoDigits(date.month)}-'
        '${twoDigits(date.day)} '
        '${twoDigits(date.hour)}:'
        '${twoDigits(date.minute)}';
  }

  // ============================================================
  // APPROVE DIALOG
  // ============================================================

  void _showApproveDialog(
    BuildContext context,
    String requestId,
    double amount,
  ) {
    showDialog<void>(
      context: context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          title: const Text(
            'Withdraw Approve',
          ),
          content: Text(
            'আপনি কি ${_money(amount)} '
            'Withdraw Request Approve করতে চান?',
          ),
          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text('Cancel'),
            ),

            FilledButton(
              onPressed: () async {
                Navigator.pop(
                  dialogContext,
                );

                await _approveWithdraw(
                  context,
                  requestId,
                  amount,
                );
              },
              child:
                  const Text('Approve'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // REJECT DIALOG
  // ============================================================

  void _showRejectDialog(
    BuildContext context,
    String requestId,
  ) {
    final controller =
        TextEditingController();

    showDialog<void>(
      context: context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          title: const Text(
            'Withdraw Reject',
          ),
          content: TextField(
            controller:
                controller,
            maxLines: 3,
            decoration:
                const InputDecoration(
              labelText:
                  'Reject Reason',
              hintText:
                  'কারণ লিখুন',
              border:
                  OutlineInputBorder(),
            ),
          ),
          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text('Cancel'),
            ),

            FilledButton(
              onPressed: () async {
                final reason =
                    controller.text
                        .trim();

                Navigator.pop(
                  dialogContext,
                );

                await _rejectWithdraw(
                  context,
                  requestId,
                  reason,
                );
              },
              child:
                  const Text('Reject'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // APPROVE WITHDRAW
  // ============================================================

  Future<void> _approveWithdraw(
    BuildContext context,
    String requestId,
    double amount,
  ) async {
    try {
      final requestRef =
          _firestore
              .collection(
                'withdraw_requests',
              )
              .doc(requestId);

      final walletRef =
          _firestore
              .collection('settings')
              .doc('owner_wallet');

      await _firestore
          .runTransaction(
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
              requestSnapshot.data() ??
                  {};

          final currentStatus =
              requestData['status']
                      ?.toString() ??
                  'pending';

          if (currentStatus !=
              'pending') {
            throw Exception(
              'এই request ইতিমধ্যে processed হয়েছে।',
            );
          }

          final walletSnapshot =
              await transaction.get(
            walletRef,
          );

          final walletData =
              walletSnapshot.data() ??
                  {};

          final balance =
              _toDouble(
            walletData['balance'],
          );

          final totalPaid =
              _toDouble(
            walletData[
                'totalPaidToUsers'],
          );

          if (balance < amount) {
            throw Exception(
              'Owner Wallet-এ পর্যাপ্ত balance নেই।',
            );
          }

          transaction.update(
            requestRef,
            {
              'status':
                  'approved',
              'approvedAt':
                  FieldValue
                      .serverTimestamp(),
            },
          );

          transaction.set(
            walletRef,
            {
              'balance':
                  balance - amount,
              'totalPaidToUsers':
                  totalPaid + amount,
              'updatedAt':
                  FieldValue
                      .serverTimestamp(),
            },
            SetOptions(
              merge: true,
            ),
          );
        },
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Withdraw সফলভাবে Approve হয়েছে।',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
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

  // ============================================================
  // REJECT WITHDRAW
  // ============================================================

  Future<void> _rejectWithdraw(
    BuildContext context,
    String requestId,
    String reason,
  ) async {
    try {
      final requestRef =
          _firestore
              .collection(
                'withdraw_requests',
              )
              .doc(requestId);

      await requestRef.update(
        {
          'status': 'rejected',
          'rejectReason':
              reason.isEmpty
                  ? 'Admin দ্বারা Reject করা হয়েছে।'
                  : reason,
          'rejectedAt':
              FieldValue
                  .serverTimestamp(),
        },
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Withdraw Request Reject হয়েছে।',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
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

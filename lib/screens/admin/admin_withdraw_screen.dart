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

  String _selectedStatus = 'pending';
  bool _processing = false;

  // ============================================================
  // COLLECTION
  // ============================================================

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
  // MONEY
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

  // ============================================================
  // STATUS
  // ============================================================

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

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending_actions;

      case 'approved':
        return Icons.check_circle;

      case 'rejected':
        return Icons.cancel;

      case 'cancelled':
        return Icons.block;

      default:
        return Icons.info;
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
        return Colors.blue;
    }
  }

  // ============================================================
  // REQUEST STREAM
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _withdrawStream() {
    return _withdrawRequests
        .where(
          'status',
          isEqualTo: _selectedStatus,
        )
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
      backgroundColor:
          const Color(0xFFF0F2F5),

      appBar: AppBar(
        title: const Text(
          'Manage Withdrawals',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [
          // ======================================================
          // STATUS FILTER
          // ======================================================

          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              8,
            ),
            child: Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(12),
                child: DropdownButtonFormField<
                    String>(
                  initialValue:
                      _selectedStatus,

                  decoration:
                      const InputDecoration(
                    labelText:
                        'Withdraw Status',
                    prefixIcon:
                        Icon(
                      Icons.filter_alt,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),

                  items: const [
                    DropdownMenuItem(
                      value: 'pending',
                      child: Text(
                        'Pending',
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'approved',
                      child: Text(
                        'Approved',
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'rejected',
                      child: Text(
                        'Rejected',
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'cancelled',
                      child: Text(
                        'Cancelled',
                      ),
                    ),
                  ],

                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _selectedStatus =
                          value;
                    });
                  },
                ),
              ),
            ),
          ),

          // ======================================================
          // REQUEST LIST
          // ======================================================

          Expanded(
            child: StreamBuilder<
                QuerySnapshot<
                    Map<String, dynamic>>>(
              stream: _withdrawStream(),

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
                  return _errorView(
                    snapshot.error
                        .toString(),
                  );
                }

                final documents =
                    snapshot.data?.docs ??
                        [];

                if (documents.isEmpty) {
                  return _emptyView();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                    await Future<void>.delayed(
                      const Duration(
                        milliseconds: 300,
                      ),
                    );
                  },

                  child: ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      30,
                    ),

                    itemCount:
                        documents.length,

                    itemBuilder:
                        (
                      context,
                      index,
                    ) {
                      return _withdrawCard(
                        documents[index],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WITHDRAW CARD
  // ============================================================

  Widget _withdrawCard(
    DocumentSnapshot<
        Map<String, dynamic>> document,
  ) {
    final data =
        document.data() ?? {};

    final requestId =
        document.id;

    final userId =
        data['userId']?.toString() ??
            '';

    final amount =
        _toDouble(
      data['amount'],
    );

    final method =
        data['method']?.toString() ??
            'Unknown';

    final account =
        data['account']?.toString() ??
            '';

    final status =
        data['status']?.toString() ??
            'pending';

    final reason =
        data['reason']?.toString() ??
            '';

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
            // HEADER
            // ==================================================

            Row(
              children: [
                CircleAvatar(
                  child: Icon(
                    _statusIcon(status),
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
                      const Text(
                        'Withdraw Request',
                        style:
                            TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 3,
                      ),

                      Text(
                        'ID: $requestId',
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            TextStyle(
                          fontSize: 11,
                          color:
                              Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                _statusBadge(
                  status,
                ),
              ],
            ),

            const Divider(
              height: 25,
            ),

            // ==================================================
            // AMOUNT
            // ==================================================

            Center(
              child: Column(
                children: [
                  Text(
                    'Withdraw Amount',
                    style:
                        TextStyle(
                      color:
                          Colors.grey.shade700,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    _money(amount),
                    style:
                        const TextStyle(
                      fontSize: 28,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            // ==================================================
            // USER INFORMATION
            // ==================================================

            _infoRow(
              icon: Icons.person,
              title: 'User ID',
              value: userId.isEmpty
                  ? 'পাওয়া যায়নি'
                  : userId,
            ),

            const SizedBox(
              height: 8,
            ),

            _infoRow(
              icon:
                  Icons.account_balance_wallet,
              title: 'Payment Method',
              value: method,
            ),

            const SizedBox(
              height: 8,
            ),

            _infoRow(
              icon: Icons.phone,
              title: 'Payment Account',
              value: account.isEmpty
                  ? 'পাওয়া যায়নি'
                  : account,
            ),

            const SizedBox(
              height: 8,
            ),

            _infoRow(
              icon: Icons.access_time,
              title: 'Created',
              value:
                  _formatTimestamp(
                createdAt,
              ),
            ),

            if (reason.isNotEmpty) ...[
              const SizedBox(
                height: 8,
              ),

              _infoRow(
                icon:
                    Icons.info_outline,
                title: 'Reason',
                value: reason,
              ),
            ],

            // ==================================================
            // ADMIN ACTIONS
            // ==================================================

            if (status == 'pending') ...[
              const SizedBox(
                height: 18,
              ),

              Row(
                children: [
                  Expanded(
                    child:
                        OutlinedButton.icon(
                      onPressed:
                          _processing
                              ? null
                              : () {
                                  _showRejectDialog(
                                    document,
                                  );
                                },
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
                    child:
                        FilledButton.icon(
                      onPressed:
                          _processing
                              ? null
                              : () {
                                  _showApproveDialog(
                                    document,
                                  );
                                },
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
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge(
    String status,
  ) {
    final color =
        _statusColor(status);

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color: color,
        ),
      ),
      child: Text(
        _statusText(status),
        style:
            TextStyle(
          color: color,
          fontWeight:
              FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 19,
        ),

        const SizedBox(
          width: 10,
        ),

        SizedBox(
          width: 115,
          child: Text(
            title,
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),

        Expanded(
          child: Text(
            value,
            style:
                TextStyle(
              color:
                  Colors.grey.shade800,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // APPROVE DIALOG
  // ============================================================

  Future<void>
      _showApproveDialog(
    DocumentSnapshot<
        Map<String, dynamic>> document,
  ) async {
    final data =
        document.data() ?? {};

    final amount =
        _toDouble(
      data['amount'],
    );

    final method =
        data['method']?.toString() ??
            '';

    final account =
        data['account']?.toString() ??
            '';

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (
        context,
      ) {
        return AlertDialog(
          title: const Text(
            'Withdraw Approve',
          ),

          content: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'আপনি কি এই Withdraw Request approve করতে চান?',
              ),

              const SizedBox(
                height: 15,
              ),

              Text(
                'Amount: ${_money(amount)}',
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              Text(
                'Method: $method',
              ),

              const SizedBox(
                height: 5,
              ),

              Text(
                'Account: $account',
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'না',
              ),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Approve',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _approveWithdraw(
        document,
      );
    }
  }

  // ============================================================
  // REJECT DIALOG
  // ============================================================

  Future<void>
      _showRejectDialog(
    DocumentSnapshot<
        Map<String, dynamic>> document,
  ) async {
    final controller =
        TextEditingController();

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (
        context,
      ) {
        return AlertDialog(
          title: const Text(
            'Withdraw Reject',
          ),

          content: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Text(
                'Reject করার কারণ চাইলে নিচে লিখুন।',
              ),

              const SizedBox(
                height: 12,
              ),

              TextField(
                controller:
                    controller,
                maxLines: 3,
                decoration:
                    const InputDecoration(
                  hintText:
                      'Reject reason...',
                  border:
                      OutlineInputBorder(),
                ),
              ),
            ],
          ),

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

            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
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

    if (confirmed == true) {
      await _rejectWithdraw(
        document,
        controller.text.trim(),
      );
    }

    controller.dispose();
  }

  // ============================================================
  // APPROVE WITHDRAW
  // ============================================================

  Future<void> _approveWithdraw(
    DocumentSnapshot<
        Map<String, dynamic>> document,
  ) async {
    if (_processing) {
      return;
    }

    setState(() {
      _processing = true;
    });

    try {
      final requestRef =
          _withdrawRequests.doc(
        document.id,
      );

      final requestSnapshot =
          await requestRef.get();

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

      final transactionRef =
          _transactions.doc();

      final ownerRef =
          _ownerWallet;

      await _firestore
          .runTransaction(
        (transaction) async {
          final freshRequest =
              await transaction.get(
            requestRef,
          );

          if (!freshRequest.exists) {
            throw Exception(
              'Withdraw request পাওয়া যায়নি।',
            );
          }

          final freshRequestData =
              freshRequest.data() ??
                  {};

          final freshStatus =
              freshRequestData[
                        'status']
                    ?.toString() ??
                  '';

          if (freshStatus !=
              'pending') {
            throw Exception(
              'এই request ইতিমধ্যে process করা হয়েছে।',
            );
          }

          final freshUser =
              await transaction.get(
            userRef,
          );

          if (!freshUser.exists) {
            throw Exception(
              'User profile পাওয়া যায়নি।',
            );
          }

          final userData =
              freshUser.data() ??
                  {};

          final balance =
              _toDouble(
            userData['balance'],
          );

          if (balance < amount) {
            throw Exception(
              'User wallet-এ পর্যাপ্ত balance নেই।',
            );
          }

          final totalWithdrawn =
              _toDouble(
            userData[
                'totalWithdrawn'],
          );

          final ownerSnapshot =
              await transaction.get(
            ownerRef,
          );

          final ownerData =
              ownerSnapshot.data() ??
                  {};

          final ownerBalance =
              _toDouble(
            ownerData['balance'],
          );

          final totalPaid =
              _toDouble(
            ownerData[
                'totalPaidToUsers'],
          );

          transaction.update(
            userRef,
            {
              'balance':
                  balance - amount,
              'totalWithdrawn':
                  totalWithdrawn +
                      amount,
              'updatedAt':
                  FieldValue
                      .serverTimestamp(),
            },
          );

          transaction.update(
            requestRef,
            {
              'status':
                  'approved',
              'approvedAt':
                  FieldValue
                      .serverTimestamp(),
              'updatedAt':
                  FieldValue
                      .serverTimestamp(),
            },
          );

          transaction.set(
            transactionRef,
            {
              'userId': userId,
              'amount': amount,
              'type': 'withdraw',
              'description':
                  'Withdraw approved',
              'referenceId':
                  requestRef.id,
              'status':
                  'completed',
              'transactionType':
                  'withdraw',
              'method':
                  freshRequestData[
                      'method'],
              'account':
                  freshRequestData[
                      'account'],
              'createdAt':
                  FieldValue
                      .serverTimestamp(),
            },
          );

          transaction.set(
            ownerRef,
            {
              'balance':
                  ownerBalance -
                      amount,
              'totalPaidToUsers':
                  totalPaid +
                      amount,
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

      _showMessage(
        'Withdraw সফলভাবে approve হয়েছে।',
      );
    } catch (e) {
      _showMessage(
        _cleanError(e),
        isError: true,
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
    DocumentSnapshot<
        Map<String, dynamic>> document,
    String reason,
  ) async {
    if (_processing) {
      return;
    }

    setState(() {
      _processing = true;
    });

    try {
      final requestRef =
          _withdrawRequests.doc(
        document.id,
      );

      final snapshot =
          await requestRef.get();

      if (!snapshot.exists) {
        throw Exception(
          'Withdraw request পাওয়া যায়নি।',
        );
      }

      final data =
          snapshot.data() ?? {};

      final status =
          data['status']
                  ?.toString() ??
              '';

      if (status != 'pending') {
        throw Exception(
          'এই request আর pending নেই।',
        );
      }

      await requestRef.update(
        {
          'status': 'rejected',
          'reason': reason.isEmpty
              ? 'Admin দ্বারা Reject করা হয়েছে।'
              : reason,
          'rejectedAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
      );

      _showMessage(
        'Withdraw Request Reject হয়েছে।',
      );
    } catch (e) {
      _showMessage(
        _cleanError(e),
        isError: true,
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
  // EMPTY VIEW
  // ============================================================

  Widget _emptyView() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 70,
              color:
                  Colors.grey.shade500,
            ),

            const SizedBox(
              height: 15,
            ),

            Text(
              'কোনো ${_statusText(_selectedStatus)} Withdraw নেই।',
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 17,
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
  // ERROR VIEW
  // ============================================================

  Widget _errorView(
    String error,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
            ),

            const SizedBox(
              height: 15,
            ),

            const Text(
              'Withdraw data load করা যায়নি।',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 17,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Text(
              _cleanError(error),
              textAlign:
                  TextAlign.center,
            ),

            const SizedBox(
              height: 15,
            ),

            FilledButton(
              onPressed: () {
                setState(() {});
              },
              child:
                  const Text(
                'আবার চেষ্টা করুন',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TIMESTAMP
  // ============================================================

  String _formatTimestamp(
    dynamic value,
  ) {
    if (value is Timestamp) {
      final date =
          value.toDate();

      final day =
          date.day
              .toString()
              .padLeft(
                2,
                '0',
              );

      final month =
          date.month
              .toString()
              .padLeft(
                2,
                '0',
              );

      final year =
          date.year.toString();

      final hour =
          date.hour
              .toString()
              .padLeft(
                2,
                '0',
              );

      final minute =
          date.minute
              .toString()
              .padLeft(
                2,
                '0',
              );

      return '$day/$month/$year $hour:$minute';
    }

    return 'সময় পাওয়া যায়নি';
  }

  // ============================================================
  // ERROR CLEAN
  // ============================================================

  String _cleanError(
    dynamic error,
  ) {
    return error
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).hideCurrentSnackBar();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }
}

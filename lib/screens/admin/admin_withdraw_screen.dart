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

  String _filter = 'pending';
  String _search = '';

  bool _processing = false;

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
  // WITHDRAW STREAM
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
  // USERS
  // ============================================================

  Future<
      DocumentSnapshot<Map<String, dynamic>>>
      _getUser(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .get();
  }

  // ============================================================
  // STATUS
  // ============================================================

  String _status(dynamic value) {
    return value
            ?.toString()
            .trim()
            .toLowerCase() ??
        'pending';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
      case 'paid':
      case 'completed':
        return Colors.green;

      case 'rejected':
        return Colors.red;

      case 'cancelled':
        return Colors.grey;

      default:
        return Colors.orange;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'approved':
        return 'Approved';

      case 'paid':
        return 'Paid';

      case 'completed':
        return 'Completed';

      case 'rejected':
        return 'Rejected';

      case 'cancelled':
        return 'Cancelled';

      default:
        return 'Pending';
    }
  }

  // ============================================================
  // APPROVE
  // ============================================================

  Future<void> _approveRequest(
    DocumentSnapshot<Map<String, dynamic>>
        request,
  ) async {
    if (_processing) {
      return;
    }

    final data = request.data() ?? {};

    final userId =
        data['userId']?.toString() ?? '';

    final amount =
        _toDouble(data['amount']);

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

    final confirm =
        await _confirmAction(
      title: 'Approve Withdraw',
      message:
          'আপনি কি ${_money(amount)} Withdraw Request Approve করতে চান?',
      confirmText: 'Approve',
    );

    if (confirm != true) {
      return;
    }

    setState(() {
      _processing = true;
    });

    try {
      final requestRef =
          _firestore
              .collection('withdraw_requests')
              .doc(request.id);

      final userRef =
          _firestore
              .collection('users')
              .doc(userId);

      final walletRef =
          _firestore
              .collection('settings')
              .doc('owner_wallet');

      await _firestore.runTransaction(
        (transaction) async {
          final requestSnap =
              await transaction.get(
            requestRef,
          );

          final userSnap =
              await transaction.get(
            userRef,
          );

          final walletSnap =
              await transaction.get(
            walletRef,
          );

          final requestData =
              requestSnap.data();

          if (requestData == null) {
            throw Exception(
              'Withdraw request পাওয়া যায়নি।',
            );
          }

          final currentStatus =
              _status(
            requestData['status'],
          );

          if (currentStatus != 'pending') {
            throw Exception(
              'এই request ইতিমধ্যে process করা হয়েছে।',
            );
          }

          final userData =
              userSnap.data();

          if (userData == null) {
            throw Exception(
              'User পাওয়া যায়নি।',
            );
          }

          final currentWallet =
              _toDouble(
            userData['wallet'],
          );

          if (currentWallet < amount) {
            throw Exception(
              'User Wallet-এ পর্যাপ্ত balance নেই।',
            );
          }

          final walletData =
              walletSnap.data() ?? {};

          final ownerBalance =
              _toDouble(
            walletData['balance'],
          );

          final totalPaid =
              _toDouble(
            walletData[
                'totalPaidToUsers'],
          );

          transaction.update(
            userRef,
            {
              'wallet':
                  currentWallet - amount,
              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
          );

          transaction.update(
            requestRef,
            {
              'status': 'approved',
              'processedAt':
                  FieldValue.serverTimestamp(),
              'approvedAt':
                  FieldValue.serverTimestamp(),
            },
          );

          transaction.set(
            walletRef,
            {
              'balance':
                  ownerBalance - amount,
              'totalPaidToUsers':
                  totalPaid + amount,
              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
            SetOptions(
              merge: true,
            ),
          );
        },
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Withdraw সফলভাবে Approve হয়েছে।',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Approve করতে সমস্যা হয়েছে: $e',
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
  // REJECT
  // ============================================================

  Future<void> _rejectRequest(
    DocumentSnapshot<Map<String, dynamic>>
        request,
  ) async {
    if (_processing) {
      return;
    }

    final data = request.data() ?? {};

    final userId =
        data['userId']?.toString() ?? '';

    final amount =
        _toDouble(data['amount']);

    final reasonController =
        TextEditingController();

    final result =
        await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.cancel_outlined,
              ),
              SizedBox(width: 8),
              Text(
                'Reject Withdraw',
              ),
            ],
          ),
          content: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Amount: ${_money(amount)}',
              ),

              const SizedBox(height: 15),

              TextField(
                controller:
                    reasonController,
                maxLines: 3,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Reject করার কারণ',
                  hintText:
                      'কারণ লিখুন...',
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
                  dialogContext,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  reasonController
                      .text
                      .trim(),
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

    reasonController.dispose();

    if (result == null) {
      return;
    }

    final reason =
        result.isEmpty
            ? 'Admin দ্বারা Withdraw Reject করা হয়েছে।'
            : result;

    if (userId.isEmpty) {
      _showMessage(
        'User ID পাওয়া যায়নি।',
      );
      return;
    }

    final confirm =
        await _confirmAction(
      title: 'Confirm Reject',
      message:
          'আপনি কি এই Withdraw Request Reject করতে চান?',
      confirmText: 'Reject',
    );

    if (confirm != true) {
      return;
    }

    setState(() {
      _processing = true;
    });

    try {
      final requestRef =
          _firestore
              .collection('withdraw_requests')
              .doc(request.id);

      final userRef =
          _firestore
              .collection('users')
              .doc(userId);

      await _firestore.runTransaction(
        (transaction) async {
          final requestSnap =
              await transaction.get(
            requestRef,
          );

          final userSnap =
              await transaction.get(
            userRef,
          );

          final requestData =
              requestSnap.data();

          if (requestData == null) {
            throw Exception(
              'Withdraw request পাওয়া যায়নি।',
            );
          }

          final currentStatus =
              _status(
            requestData['status'],
          );

          if (currentStatus != 'pending') {
            throw Exception(
              'এই request ইতিমধ্যে process করা হয়েছে।',
            );
          }

          final userData =
              userSnap.data();

          if (userData == null) {
            throw Exception(
              'User পাওয়া যায়নি।',
            );
          }

          transaction.update(
            requestRef,
            {
              'status': 'rejected',
              'rejectReason':
                  reason,
              'processedAt':
                  FieldValue.serverTimestamp(),
              'rejectedAt':
                  FieldValue.serverTimestamp(),
            },
          );
        },
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Withdraw Reject করা হয়েছে।',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Reject করতে সমস্যা হয়েছে: $e',
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

  Future<bool?> _confirmAction({
    required String title,
    required String message,
    required String confirmText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
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
                  dialogContext,
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
  }

  // ============================================================
  // DELETE REQUEST
  // ============================================================

  Future<void> _deleteRequest(
    DocumentSnapshot<Map<String, dynamic>>
        request,
  ) async {
    if (_processing) {
      return;
    }

    final status =
        _status(
      request.data()?['status'],
    );

    if (status == 'pending') {
      _showMessage(
        'Pending request Delete করা যাবে না।',
      );
      return;
    }

    final confirm =
        await _confirmAction(
      title: 'Delete Request',
      message:
          'এই Withdraw Request মুছে ফেলতে চান?',
      confirmText: 'Delete',
    );

    if (confirm != true) {
      return;
    }

    setState(() {
      _processing = true;
    });

    try {
      await request.reference.delete();

      if (!mounted) {
        return;
      }

      _showMessage(
        'Request Delete হয়েছে।',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Delete করতে সমস্যা হয়েছে: $e',
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
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
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
          'Withdraw Management',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: Stack(
        children: [
          StreamBuilder<
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
                return Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(
                      20,
                    ),
                    child: Text(
                      'Withdraw Load Error:\n${snapshot.error}',
                      textAlign:
                          TextAlign.center,
                    ),
                  ),
                );
              }

              final allRequests =
                  snapshot.data?.docs ??
                      [];

              final filtered =
                  allRequests.where(
                (document) {
                  final data =
                      document.data();

                  final status =
                      _status(
                    data['status'],
                  );

                  final userName =
                      data['userName']
                              ?.toString()
                              .toLowerCase() ??
                          '';

                  final email =
                      data['email']
                              ?.toString()
                              .toLowerCase() ??
                          '';

                  final userId =
                      data['userId']
                              ?.toString()
                              .toLowerCase() ??
                          '';

                  final search =
                      _search
                          .trim()
                          .toLowerCase();

                  final statusMatch =
                      _filter == 'all' ||
                          status == _filter;

                  final searchMatch =
                      search.isEmpty ||
                          userName.contains(
                            search,
                          ) ||
                          email.contains(
                            search,
                          ) ||
                          userId.contains(
                            search,
                          );

                  return statusMatch &&
                      searchMatch;
                },
              ).toList();

              int pending = 0;
              int approved = 0;
              int rejected = 0;

              double pendingAmount = 0;
              double approvedAmount = 0;

              for (final document
                  in allRequests) {
                final data =
                    document.data();

                final status =
                    _status(
                  data['status'],
                );

                final amount =
                    _toDouble(
                  data['amount'],
                );

                if (status == 'pending') {
                  pending++;
                  pendingAmount += amount;
                } else if (status ==
                        'approved' ||
                    status == 'paid' ||
                    status ==
                        'completed') {
                  approved++;
                  approvedAmount += amount;
                } else if (status ==
                    'rejected') {
                  rejected++;
                }
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await Future<void>.delayed(
                    const Duration(
                      milliseconds: 500,
                    ),
                  );
                },
                child: ListView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),
                  children: [
                    // ==================================================
                    // SUMMARY
                    // ==================================================

                    Row(
                      children: [
                        Expanded(
                          child:
                              _summaryCard(
                            title: 'Pending',
                            value:
                                '$pending',
                            amount:
                                pendingAmount,
                            icon:
                                Icons
                                    .pending_actions,
                          ),
                        ),

                        const SizedBox(
                          width: 8,
                        ),

                        Expanded(
                          child:
                              _summaryCard(
                            title:
                                'Approved',
                            value:
                                '$approved',
                            amount:
                                approvedAmount,
                            icon:
                                Icons
                                    .check_circle,
                          ),
                        ),

                        const SizedBox(
                          width: 8,
                        ),

                        Expanded(
                          child:
                              _summaryCard(
                            title:
                                'Rejected',
                            value:
                                '$rejected',
                            amount: null,
                            icon:
                                Icons.cancel,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    // ==================================================
                    // SEARCH
                    // ==================================================

                    TextField(
                      decoration:
                          const InputDecoration(
                        hintText:
                            'User, Email অথবা User ID Search করুন...',
                        prefixIcon:
                            Icon(
                          Icons.search,
                        ),
                        border:
                            OutlineInputBorder(),
                        filled: true,
                        fillColor:
                            Colors.white,
                      ),
                      onChanged:
                          (value) {
                        setState(() {
                          _search =
                              value;
                        });
                      },
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // ==================================================
                    // FILTER
                    // ==================================================

                    SingleChildScrollView(
                      scrollDirection:
                          Axis.horizontal,
                      child: Row(
                        children: [
                          _filterButton(
                            'pending',
                            'Pending',
                            Icons
                                .pending_actions,
                          ),
                          _filterButton(
                            'approved',
                            'Approved',
                            Icons
                                .check_circle,
                          ),
                          _filterButton(
                            'rejected',
                            'Rejected',
                            Icons.cancel,
                          ),
                          _filterButton(
                            'all',
                            'All',
                            Icons.list,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    // ==================================================
                    // LIST
                    // ==================================================

                    if (filtered.isEmpty)
                      Card(
                        child: Padding(
                          padding:
                              const EdgeInsets
                                  .all(
                            30,
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons
                                    .inbox_outlined,
                                size: 50,
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              const Text(
                                'কোনো Withdraw Request পাওয়া যায়নি।',
                                textAlign:
                                    TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                    ...filtered.map(
                      (
                        document,
                      ) =>
                          _withdrawItem(
                        document,
                      ),
                    ),

                    const SizedBox(
                      height: 30,
                    ),
                  ],
                ),
              );
            },
          ),

          // ==========================================================
          // PROCESSING
          // ==========================================================

          if (_processing)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding:
                        EdgeInsets.all(25),
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 15),
                        Text(
                          'Processing...',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget _summaryCard({
    required String title,
    required String value,
    required double? amount,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 6,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
            ),

            const SizedBox(
              height: 5,
            ),

            Text(
              title,
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            if (amount != null)
              Text(
                _money(amount),
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color:
                      Colors.grey.shade700,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FILTER BUTTON
  // ============================================================

  Widget _filterButton(
    String value,
    String title,
    IconData icon,
  ) {
    final selected =
        _filter == value;

    return Padding(
      padding:
          const EdgeInsets.only(
        right: 8,
      ),
      child: FilterChip(
        selected: selected,
        avatar: Icon(
          icon,
          size: 18,
        ),
        label: Text(title),
        onSelected: (_) {
          setState(() {
            _filter = value;
          });
        },
      ),
    );
  }

  // ============================================================
  // WITHDRAW ITEM
  // ============================================================

  Widget _withdrawItem(
    DocumentSnapshot<
        Map<String, dynamic>> document,
  ) {
    final data =
        document.data() ?? {};

    final userId =
        data['userId']?.toString() ??
            '';

    final userName =
        data['userName']?.toString() ??
            data['name']?.toString() ??
            'Unknown User';

    final email =
        data['email']?.toString() ??
            '';

    final amount =
        _toDouble(
      data['amount'],
    );

    final method =
        data['method']?.toString() ??
            data['paymentMethod']
                ?.toString() ??
            'Payment Method নেই';

    final account =
        data['accountNumber']
                ?.toString() ??
            data['account']
                ?.toString() ??
            '';

    final status =
        _status(
      data['status'],
    );

    final reason =
        data['rejectReason']
                ?.toString() ??
            '';

    final statusColor =
        _statusColor(status);

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(14),
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

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style:
                            const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      if (email.isNotEmpty)
                        Text(
                          email,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors
                                .grey
                                .shade700,
                          ),
                        ),
                    ],
                  ),
                ),

                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration:
                      BoxDecoration(
                    color: statusColor
                        .withValues(
                      alpha: 0.12,
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
                      fontSize: 11,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            // ==================================================
            // AMOUNT
            // ==================================================

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(
                12,
              ),
              decoration:
                  BoxDecoration(
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
                color: Colors.grey
                    .withValues(
                  alpha: 0.08,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.payments,
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  const Text(
                    'Amount',
                  ),

                  const Spacer(),

                  Text(
                    _money(amount),
                    style:
                        const TextStyle(
                      fontSize: 19,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            // ==================================================
            // PAYMENT INFO
            // ==================================================

            _infoRow(
              Icons.payment,
              'Method',
              method,
            ),

            if (account.isNotEmpty)
              _infoRow(
                Icons.account_box,
                'Account',
                account,
              ),

            if (userId.isNotEmpty)
              _infoRow(
                Icons.fingerprint,
                'User ID',
                userId,
              ),

            if (reason.isNotEmpty &&
                status == 'rejected')
              _infoRow(
                Icons.info_outline,
                'Reject Reason',
                reason,
              ),

            const SizedBox(
              height: 12,
            ),

            // ==================================================
            // ACTIONS
            // ==================================================

            if (status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _processing
                              ? null
                              : () =>
                                  _rejectRequest(
                                    document,
                                  ),
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

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child:
                        FilledButton.icon(
                      onPressed:
                          _processing
                              ? null
                              : () =>
                                  _approveRequest(
                                    document,
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
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Request processed',
                      style: TextStyle(
                        color: Colors
                            .grey
                            .shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  IconButton(
                    tooltip:
                        'Delete History',
                    onPressed:
                        _processing
                            ? null
                            : () =>
                                _deleteRequest(
                                  document,
                                ),
                    icon:
                        const Icon(
                      Icons.delete_outline,
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
  // INFO ROW
  // ============================================================

  Widget _infoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 7,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
          ),

          const SizedBox(
            width: 8,
          ),

          SizedBox(
            width: 85,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color:
                    Colors.grey.shade700,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight:
                    FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

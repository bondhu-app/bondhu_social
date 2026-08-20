import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminWithdrawScreen extends StatelessWidget {
  const AdminWithdrawScreen({super.key});

  final String _collectionName = 'withdraw_requests';

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

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _requestsStream() {
    return FirebaseFirestore.instance
        .collection(_collectionName)
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots();
  }

  Future<void> _updateRequest({
    required BuildContext context,
    required String requestId,
    required Map<String, dynamic> data,
    required String newStatus,
  }) async {
    final userId =
        data['userId']?.toString() ?? '';

    final amount =
        _toDouble(data['amount']);

    if (userId.isEmpty) {
      _showMessage(
        context,
        'User ID পাওয়া যায়নি।',
      );
      return;
    }

    if (amount <= 0) {
      _showMessage(
        context,
        'Withdraw amount সঠিক নয়।',
      );
      return;
    }

    if (newStatus == 'rejected') {
      try {
        await FirebaseFirestore.instance
            .collection(_collectionName)
            .doc(requestId)
            .update({
          'status': 'rejected',
          'updatedAt':
              FieldValue.serverTimestamp(),
        });

        if (context.mounted) {
          _showMessage(
            context,
            'Withdraw request Reject করা হয়েছে।',
          );
        }
      } catch (e) {
        if (context.mounted) {
          _showMessage(
            context,
            'Reject করা যায়নি: $e',
          );
        }
      }

      return;
    }

    if (newStatus != 'approved') {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .runTransaction(
        (transaction) async {
          final requestRef =
              FirebaseFirestore.instance
                  .collection(
                    _collectionName,
                  )
                  .doc(requestId);

          final userRef =
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId);

          final ownerWalletRef =
              FirebaseFirestore.instance
                  .collection('settings')
                  .doc('owner_wallet');

          final requestSnapshot =
              await transaction.get(
            requestRef,
          );

          final userSnapshot =
              await transaction.get(
            userRef,
          );

          final ownerSnapshot =
              await transaction.get(
            ownerWalletRef,
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
              'এই request ইতিমধ্যে process করা হয়েছে।',
            );
          }

          if (!userSnapshot.exists) {
            throw Exception(
              'User পাওয়া যায়নি।',
            );
          }

          final userData =
              userSnapshot.data() ??
                  {};

          final currentWallet =
              _toDouble(
            userData['wallet'],
          );

          if (currentWallet <
              amount) {
            throw Exception(
              'User Wallet-এ পর্যাপ্ত টাকা নেই।',
            );
          }

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
              'wallet':
                  currentWallet - amount,
              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
          );

          transaction.set(
            ownerWalletRef,
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

          transaction.update(
            requestRef,
            {
              'status': 'approved',
              'approvedAt':
                  FieldValue.serverTimestamp(),
              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
          );
        },
      );

      if (context.mounted) {
        _showMessage(
          context,
          'Withdraw request Approve করা হয়েছে।',
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showMessage(
          context,
          'Approve করা যায়নি: $e',
        );
      }
    }
  }

  Future<void> _confirmAction({
    required BuildContext context,
    required String requestId,
    required Map<String, dynamic> data,
    required bool approve,
  }) async {
    final amount =
        _toDouble(data['amount']);

    final title = approve
        ? 'Withdraw Approve করবেন?'
        : 'Withdraw Reject করবেন?';

    final message = approve
        ? 'আপনি কি ${_money(amount)} Withdraw request Approve করতে চান?'
        : 'আপনি কি ${_money(amount)} Withdraw request Reject করতে চান?';

    final result =
        await showDialog<bool>(
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
                'না',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: Text(
                approve
                    ? 'Approve'
                    : 'Reject',
              ),
            ),
          ],
        );
      },
    );

    if (result != true) {
      return;
    }

    await _updateRequest(
      context: context,
      requestId: requestId,
      data: data,
      newStatus:
          approve ? 'approved' : 'rejected',
    );
  }

  void _showMessage(
    BuildContext context,
    String message,
  ) {
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
      backgroundColor:
          const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text(
          'Manage Withdrawals',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<
          QuerySnapshot<
              Map<String, dynamic>>>(
        stream: _requestsStream(),
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
                  'Withdraw data load error:\n${snapshot.error}',
                  textAlign:
                      TextAlign.center,
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
                        .account_balance_wallet_outlined,
                    size: 70,
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Text(
                    'কোনো Withdraw Request নেই।',
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

          return ListView(
            padding:
                const EdgeInsets.all(16),
            children: [
              // =================================================
              // HEADER
              // =================================================

              Card(
                elevation: 3,
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    20,
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        child: Icon(
                          Icons.payments,
                          size: 32,
                        ),
                      ),
                      const SizedBox(
                        width: 15,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            const Text(
                              'Withdraw Management',
                              style:
                                  TextStyle(
                                fontSize: 22,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Text(
                              '${requests.length} টি Withdraw Request',
                              style: TextStyle(
                                color: Colors
                                    .grey
                                    .shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              // =================================================
              // REQUEST LIST
              // =================================================

              ...requests.map(
                (document) {
                  return _requestCard(
                    context,
                    document,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _requestCard(
    BuildContext context,
    DocumentSnapshot<
        Map<String, dynamic>> document,
  ) {
    final data =
        document.data() ?? {};

    final requestId =
        document.id;

    final userId =
        data['userId']?.toString() ??
            'Unknown';

    final userName =
        data['userName']?.toString() ??
            'User';

    final email =
        data['email']?.toString() ??
            '';

    final method =
        data['method']?.toString() ??
            data['paymentMethod']
                ?.toString() ??
            'Payment method নেই';

    final account =
        data['account']?.toString() ??
            data['accountNumber']
                ?.toString() ??
            data['phone']
                ?.toString() ??
            '';

    final status =
        data['status']?.toString() ??
            'pending';

    final amount =
        _toDouble(data['amount']);

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // =================================================
            // USER
            // =================================================

            Row(
              children: [
                const CircleAvatar(
                  child: Icon(
                    Icons.person,
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
                        userName,
                        style:
                            const TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      if (email
                          .isNotEmpty)
                        Text(
                          email,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
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

            // =================================================
            // AMOUNT
            // =================================================

            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
              children: [
                const Text(
                  'Withdraw Amount',
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
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

            const SizedBox(
              height: 10,
            ),

            // =================================================
            // PAYMENT METHOD
            // =================================================

            if (method.isNotEmpty)
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  const Icon(
                    Icons
                        .account_balance_wallet,
                    size: 20,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: Text(
                      'Method: $method',
                    ),
                  ),
                ],
              ),

            if (account.isNotEmpty) ...[
              const SizedBox(
                height: 7,
              ),
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  const Icon(
                    Icons
                        .phone_android,
                    size: 20,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: Text(
                      'Account: $account',
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(
              height: 7,
            ),

            Text(
              'User ID: $userId',
              style: TextStyle(
                fontSize: 11,
                color:
                    Colors.grey.shade600,
              ),
            ),

            const SizedBox(
              height: 15,
            ),

            // =================================================
            // ACTION BUTTONS
            // =================================================

            if (status == 'pending')
              Row(
                children: [
                  Expanded(
                    child:
                        OutlinedButton.icon(
                      onPressed: () {
                        _confirmAction(
                          context:
                              context,
                          requestId:
                              requestId,
                          data: data,
                          approve:
                              false,
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
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child:
                        ElevatedButton.icon(
                      onPressed: () {
                        _confirmAction(
                          context:
                              context,
                          requestId:
                              requestId,
                          data: data,
                          approve:
                              true,
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

            if (status == 'approved')
              const SizedBox(
                width: double.infinity,
                child: Text(
                  '✓ এই Withdraw Approved হয়েছে।',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

            if (status == 'rejected')
              const SizedBox(
                width: double.infinity,
                child: Text(
                  '✕ এই Withdraw Rejected হয়েছে।',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(
    String status,
  ) {
    String text;
    IconData icon;

    if (status == 'approved') {
      text = 'Approved';
      icon = Icons.check_circle;
    } else if (status == 'rejected') {
      text = 'Rejected';
      icon = Icons.cancel;
    } else {
      text = 'Pending';
      icon = Icons.pending;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color:
              Colors.grey,
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
          ),
          const SizedBox(
            width: 4,
          ),
          Text(
            text,
            style:
                const TextStyle(
              fontSize: 11,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

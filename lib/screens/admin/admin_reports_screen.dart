import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() =>
      _AdminReportsScreenState();
}

class _AdminReportsScreenState
    extends State<AdminReportsScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  String _selectedStatus = 'pending';

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _reportsStream() {
    return _firestore
        .collection('reports')
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

  Future<void> _updateReport(
    String reportId,
    String status,
  ) async {
    try {
      await _firestore
          .collection('reports')
          .doc(reportId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'resolved'
                ? 'Report Resolved হয়েছে।'
                : 'Report Rejected হয়েছে।',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'কাজটি করা যায়নি: $error',
          ),
        ),
      );
    }
  }

  String _value(
    Map<String, dynamic> data,
    String key,
  ) {
    return data[key]?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Reports',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterButton('pending'),
                  const SizedBox(width: 8),
                  _filterButton('resolved'),
                  const SizedBox(width: 8),
                  _filterButton('rejected'),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: _reportsStream(),
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
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Reports লোড করা যায়নি.\n\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final reports =
                    snapshot.data?.docs ?? [];

                if (reports.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.report_off_outlined,
                          size: 60,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'কোনো Report নেই।',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: reports.length,
                  itemBuilder: (
                    context,
                    index,
                  ) {
                    final document =
                        reports[index];

                    final data =
                        document.data();

                    final reason = _value(
                      data,
                      'reason',
                    );

                    final description = _value(
                      data,
                      'description',
                    );

                    final reporterName = _value(
                      data,
                      'reporterName',
                    );

                    final targetName = _value(
                      data,
                      'targetName',
                    );

                    return Card(
                      margin: const EdgeInsets.only(
                        bottom: 12,
                      ),
                      child: Padding(
                        padding:
                            const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  child: Icon(
                                    Icons.flag_outlined,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    reason.isEmpty
                                        ? 'Report'
                                        : reason,
                                    style:
                                        const TextStyle(
                                      fontSize: 17,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (reporterName.isNotEmpty)
                              Text(
                                'Reporter: $reporterName',
                              ),
                            if (targetName.isNotEmpty)
                              Text(
                                'Target: $targetName',
                              ),
                            if (description.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                description,
                              ),
                            ],
                            if (_selectedStatus ==
                                'pending') ...[
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child:
                                        OutlinedButton(
                                      onPressed: () {
                                        _updateReport(
                                          document.id,
                                          'rejected',
                                        );
                                      },
                                      child: const Text(
                                        'Reject',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child:
                                        FilledButton(
                                      onPressed: () {
                                        _updateReport(
                                          document.id,
                                          'resolved',
                                        );
                                      },
                                      child: const Text(
                                        'Resolve',
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
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterButton(
    String status,
  ) {
    final selected =
        _selectedStatus == status;

    return ChoiceChip(
      label: Text(
        status == 'pending'
            ? 'Pending'
            : status == 'resolved'
                ? 'Resolved'
                : 'Rejected',
      ),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _selectedStatus = status;
        });
      },
    );
  }
}

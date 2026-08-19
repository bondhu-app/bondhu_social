import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Reports',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Reports লোড করা যায়নি.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final reports = snapshot.data?.docs ?? [];

          if (reports.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.report_outlined,
                    size: 70,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 15),
                  Text(
                    'কোনো Report নেই',
                    style: TextStyle(
                      fontSize: 18,
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
            itemBuilder: (context, index) {
              final doc = reports[index];
              final data = doc.data();

              final reason =
                  data['reason']?.toString() ?? 'কারণ নেই';

              final reporter =
                  data['reporterName']?.toString() ?? 'Unknown User';

              final status =
                  data['status']?.toString() ?? 'pending';

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      status == 'resolved'
                          ? Icons.check
                          : Icons.flag,
                    ),
                  ),
                  title: Text(
                    reason,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Reporter: $reporter\nStatus: $status',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      await FirebaseFirestore.instance
                          .collection('reports')
                          .doc(doc.id)
                          .update({
                        'status': value,
                      });
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'reviewing',
                        child: Text('Reviewing'),
                      ),
                      PopupMenuItem(
                        value: 'resolved',
                        child: Text('Resolved'),
                      ),
                      PopupMenuItem(
                        value: 'rejected',
                        child: Text('Rejected'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCreateNotification(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('New Notification'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Notifications লোড করা যায়নি.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final notifications =
              snapshot.data?.docs ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 70,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'কোনো Notification নেই',
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
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final data =
                  notifications[index].data();

              final title =
                  data['title']?.toString() ??
                      'Notification';

              final message =
                  data['message']?.toString() ??
                      '';

              return Card(
                margin:
                    const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(
                      Icons.notifications,
                    ),
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(message),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static void _showCreateNotification(
    BuildContext context,
  ) {
    final titleController =
        TextEditingController();

    final messageController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'New Notification',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration:
                      const InputDecoration(
                    labelText: 'Title',
                    border:
                        OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller:
                      messageController,
                  maxLines: 4,
                  decoration:
                      const InputDecoration(
                    labelText: 'Message',
                    border:
                        OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final title =
                    titleController.text.trim();

                final message =
                    messageController.text.trim();

                if (title.isEmpty ||
                    message.isEmpty) {
                  return;
                }

                await FirebaseFirestore.instance
                    .collection('notifications')
                    .add({
                  'title': title,
                  'message': message,
                  'createdAt':
                      FieldValue.serverTimestamp(),
                });

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }
}

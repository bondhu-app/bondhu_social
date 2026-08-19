import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({
    super.key,
  });

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState
    extends State<AdminNotificationsScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final TextEditingController _titleController =
      TextEditingController();

  final TextEditingController _messageController =
      TextEditingController();

  bool _sending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    final title =
        _titleController.text.trim();

    final message =
        _messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Title এবং Message লিখুন।',
          ),
        ),
      );
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      await _firestore
          .collection('notifications')
          .add({
        'title': title,
        'message': message,
        'type': 'admin',
        'createdAt':
            FieldValue.serverTimestamp(),
        'read': false,
      });

      _titleController.clear();
      _messageController.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Notification তৈরি হয়েছে।',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Notification তৈরি করা যায়নি: $error',
          ),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _sending = false;
      });
    }
  }

  Future<void> _deleteNotification(
    String id,
  ) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(id)
          .delete();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Delete করা যায়নি: $error',
          ),
        ),
      );
    }
  }

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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create Notification',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller:
                        _titleController,
                    decoration:
                        const InputDecoration(
                      labelText: 'Title',
                      prefixIcon:
                          Icon(
                        Icons.title,
                      ),
                      border:
                          OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller:
                        _messageController,
                    maxLines: 5,
                    decoration:
                        const InputDecoration(
                      labelText: 'Message',
                      alignLabelWithHint: true,
                      prefixIcon:
                          Icon(
                        Icons.message_outlined,
                      ),
                      border:
                          OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed:
                          _sending
                              ? null
                              : _sendNotification,
                      icon: _sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.send,
                            ),
                      label: Text(
                        _sending
                            ? 'Sending...'
                            : 'Send Notification',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Notification History',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore
                .collection('notifications')
                .orderBy(
                  'createdAt',
                  descending: true,
                )
                .limit(50)
                .snapshots(),
            builder: (
              context,
              snapshot,
            ) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(
                    child:
                        CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding:
                      const EdgeInsets.all(20),
                  child: Text(
                    'Notification লোড করা যায়নি.\n\n${snapshot.error}',
                  ),
                );
              }

              final notifications =
                  snapshot.data?.docs ?? [];

              if (notifications.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(
                    child: Text(
                      'কোনো Notification নেই।',
                    ),
                  ),
                );
              }

              return Column(
                children:
                    notifications.map(
                  (document) {
                    final data =
                        document.data();

                    final title =
                        data['title']
                                ?.toString() ??
                            'Notification';

                    final message =
                        data['message']
                                ?.toString() ??
                            '';

                    return Card(
                      child: ListTile(
                        leading:
                            const CircleAvatar(
                          child: Icon(
                            Icons
                                .notifications,
                          ),
                        ),
                        title: Text(
                          title,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        subtitle:
                            Text(message),
                        trailing:
                            IconButton(
                          onPressed: () {
                            _deleteNotification(
                              document.id,
                            );
                          },
                          icon:
                              const Icon(
                            Icons
                                .delete_outline,
                            color:
                                Colors.red,
                          ),
                        ),
                      ),
                    );
                  },
                ).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

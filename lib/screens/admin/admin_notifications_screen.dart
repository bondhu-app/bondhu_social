import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState
    extends State<AdminNotificationsScreen> {
  final TextEditingController titleController =
      TextEditingController();

  final TextEditingController messageController =
      TextEditingController();

  bool sending = false;

  @override
  void dispose() {
    titleController.dispose();
    messageController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    final title = titleController.text.trim();
    final message = messageController.text.trim();

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
      sending = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('admin_notifications')
          .add({
        'title': title,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'admin',
      });

      titleController.clear();
      messageController.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Notification পাঠানো হয়েছে।',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Notifications',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'Notification Title',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: messageController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Notification Message',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 15),

          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed:
                  sending ? null : _sendNotification,
              icon: const Icon(Icons.send),
              label: const Text(
                'Send Notification',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

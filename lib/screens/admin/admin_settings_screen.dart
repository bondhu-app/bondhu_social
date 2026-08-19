import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState
    extends State<AdminSettingsScreen> {
  bool maintenanceMode = false;
  bool allowPosts = true;
  bool allowComments = true;
  bool allowWithdraw = true;

  Future<void> _save(
    String key,
    bool value,
  ) async {
    await FirebaseFirestore.instance
        .collection('settings')
        .doc('app_settings')
        .set(
      {
        key: value,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'App Control',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          SwitchListTile(
            title: const Text('Maintenance Mode'),
            subtitle: const Text(
              'অ্যাপ Maintenance Mode চালু/বন্ধ',
            ),
            value: maintenanceMode,
            onChanged: (value) {
              setState(() {
                maintenanceMode = value;
              });
              _save('maintenanceMode', value);
            },
          ),

          SwitchListTile(
            title: const Text('Allow Posts'),
            subtitle: const Text(
              'User Post করতে পারবে',
            ),
            value: allowPosts,
            onChanged: (value) {
              setState(() {
                allowPosts = value;
              });
              _save('allowPosts', value);
            },
          ),

          SwitchListTile(
            title: const Text('Allow Comments'),
            subtitle: const Text(
              'User Comment করতে পারবে',
            ),
            value: allowComments,
            onChanged: (value) {
              setState(() {
                allowComments = value;
              });
              _save('allowComments', value);
            },
          ),

          SwitchListTile(
            title: const Text('Allow Withdraw'),
            subtitle: const Text(
              'User Withdraw করতে পারবে',
            ),
            value: allowWithdraw,
            onChanged: (value) {
              setState(() {
                allowWithdraw = value;
              });
              _save('allowWithdraw', value);
            },
          ),
        ],
      ),
    );
  }
}

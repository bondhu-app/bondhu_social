import 'package:flutter/material.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState
    extends State<AdminSettingsScreen> {
  bool allowRegistration = true;
  bool allowPosts = true;
  bool allowComments = true;
  bool maintenanceMode = false;
  bool notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(Icons.admin_panel_settings),
              ),
              title: Text(
                'Admin Settings',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'অ্যাপের গুরুত্বপূর্ণ Settings পরিচালনা করুন',
              ),
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'App Control',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(
                    Icons.person_add,
                  ),
                  title: const Text(
                    'Allow Registration',
                  ),
                  subtitle: const Text(
                    'নতুন User Account খুলতে পারবে',
                  ),
                  value: allowRegistration,
                  onChanged: (value) {
                    setState(() {
                      allowRegistration = value;
                    });
                  },
                ),

                SwitchListTile(
                  secondary: const Icon(
                    Icons.article,
                  ),
                  title: const Text(
                    'Allow Posts',
                  ),
                  subtitle: const Text(
                    'User Post করতে পারবে',
                  ),
                  value: allowPosts,
                  onChanged: (value) {
                    setState(() {
                      allowPosts = value;
                    });
                  },
                ),

                SwitchListTile(
                  secondary: const Icon(
                    Icons.comment,
                  ),
                  title: const Text(
                    'Allow Comments',
                  ),
                  subtitle: const Text(
                    'User Comment করতে পারবে',
                  ),
                  value: allowComments,
                  onChanged: (value) {
                    setState(() {
                      allowComments = value;
                    });
                  },
                ),

                SwitchListTile(
                  secondary: const Icon(
                    Icons.notifications,
                  ),
                  title: const Text(
                    'Notifications',
                  ),
                  subtitle: const Text(
                    'App Notifications চালু থাকবে',
                  ),
                  value: notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      notificationsEnabled = value;
                    });
                  },
                ),

                SwitchListTile(
                  secondary: const Icon(
                    Icons.build,
                  ),
                  title: const Text(
                    'Maintenance Mode',
                  ),
                  subtitle: const Text(
                    'App Maintenance Mode চালু করুন',
                  ),
                  value: maintenanceMode,
                  onChanged: (value) {
                    setState(() {
                      maintenanceMode = value;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Admin Settings সংরক্ষণ করা হয়েছে।',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.save),
            label: const Text(
              'Save Settings',
            ),
          ),
        ],
      ),
    );
  }
}

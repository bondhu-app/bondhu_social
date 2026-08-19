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
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  bool _maintenanceMode = false;
  bool _allowRegistration = true;
  bool _allowPosts = true;
  bool _allowComments = true;
  bool _allowWithdraw = true;

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final document = await _firestore
          .collection('settings')
          .doc('app_settings')
          .get();

      if (document.exists) {
        final data =
            document.data() ?? {};

        _maintenanceMode =
            data['maintenanceMode'] ?? false;

        _allowRegistration =
            data['allowRegistration'] ?? true;

        _allowPosts =
            data['allowPosts'] ?? true;

        _allowComments =
            data['allowComments'] ?? true;

        _allowWithdraw =
            data['allowWithdraw'] ?? true;
      }
    } catch (_) {
      // Default settings থাকবে।
    }

    if (!mounted) return;

    setState(() {
      _loading = false;
    });
  }

  Future<void> _saveSettings() async {
    setState(() {
      _saving = true;
    });

    try {
      await _firestore
          .collection('settings')
          .doc('app_settings')
          .set({
        'maintenanceMode':
            _maintenanceMode,
        'allowRegistration':
            _allowRegistration,
        'allowPosts':
            _allowPosts,
        'allowComments':
            _allowComments,
        'allowWithdraw':
            _allowWithdraw,
        'updatedAt':
            FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Admin Settings Save হয়েছে।',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Save করা যায়নি: $error',
          ),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Settings'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed:
                _saving ? null : _saveSettings,
            icon: const Icon(
              Icons.save_outlined,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _section(
            title: 'Application',
            children: [
              SwitchListTile(
                secondary: const Icon(
                  Icons.build_outlined,
                ),
                title: const Text(
                  'Maintenance Mode',
                ),
                subtitle: const Text(
                  'App maintenance mode চালু করুন',
                ),
                value: _maintenanceMode,
                onChanged: (value) {
                  setState(() {
                    _maintenanceMode = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          _section(
            title: 'Users',
            children: [
              SwitchListTile(
                secondary: const Icon(
                  Icons.person_add_outlined,
                ),
                title: const Text(
                  'Allow Registration',
                ),
                value: _allowRegistration,
                onChanged: (value) {
                  setState(() {
                    _allowRegistration = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          _section(
            title: 'Posts & Comments',
            children: [
              SwitchListTile(
                secondary: const Icon(
                  Icons.article_outlined,
                ),
                title: const Text(
                  'Allow Posts',
                ),
                value: _allowPosts,
                onChanged: (value) {
                  setState(() {
                    _allowPosts = value;
                  });
                },
              ),
              SwitchListTile(
                secondary: const Icon(
                  Icons.comment_outlined,
                ),
                title: const Text(
                  'Allow Comments',
                ),
                value: _allowComments,
                onChanged: (value) {
                  setState(() {
                    _allowComments = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          _section(
            title: 'Money',
            children: [
              SwitchListTile(
                secondary: const Icon(
                  Icons.payments_outlined,
                ),
                title: const Text(
                  'Allow Withdraw',
                ),
                subtitle: const Text(
                  'User Withdraw চালু/বন্ধ করুন',
                ),
                value: _allowWithdraw,
                onChanged: (value) {
                  setState(() {
                    _allowWithdraw = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed:
                  _saving ? null : _saveSettings,
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.save,
                    ),
              label: Text(
                _saving
                    ? 'Saving...'
                    : 'Save Settings',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

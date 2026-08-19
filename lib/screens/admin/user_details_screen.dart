import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserDetailsScreen extends StatelessWidget {
  final String userId;

  const UserDetailsScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'User Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
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
                'User Details লোড করা যায়নি.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'User পাওয়া যায়নি।',
              ),
            );
          }

          final data =
              snapshot.data!.data() ?? {};

          final name =
              data['name']?.toString() ??
                  'নাম নেই';

          final email =
              data['email']?.toString() ??
                  'Email নেই';

          final username =
              data['username']?.toString() ??
                  '';

          final phone =
              data['phone']?.toString() ??
                  '';

          final role =
              data['role']?.toString() ??
                  'user';

          final wallet =
              data['wallet'] ?? 0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const CircleAvatar(
                radius: 50,
                child: Icon(
                  Icons.person,
                  size: 55,
                ),
              ),

              const SizedBox(height: 15),

              Center(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              _infoCard(
                'User ID',
                userId,
                Icons.fingerprint,
              ),

              _infoCard(
                'Email',
                email,
                Icons.email,
              ),

              _infoCard(
                'Username',
                username.isEmpty
                    ? 'নেই'
                    : '@$username',
                Icons.alternate_email,
              ),

              _infoCard(
                'Phone',
                phone.isEmpty
                    ? 'নেই'
                    : phone,
                Icons.phone,
              ),

              _infoCard(
                'Role',
                role,
                Icons.admin_panel_settings,
              ),

              _infoCard(
                'Wallet',
                '৳$wallet',
                Icons.account_balance_wallet,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      margin:
          const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

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
        title: const Text('User Details'),
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

          if (!snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text('User পাওয়া যায়নি।'),
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
                  size: 50,
                ),
              ),

              const SizedBox(height: 15),

              Center(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              _item('Email', email),
              _item('Username', username),
              _item('Role', role),
              _item('Wallet', '৳$wallet'),
              _item('User ID', userId),
            ],
          );
        },
      ),
    );
  }

  Widget _item(
    String title,
    String value,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(value),
      ),
    );
  }
}

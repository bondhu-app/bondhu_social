import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserDetailsScreen extends StatelessWidget {
  final String userId;

  const UserDetailsScreen({
    super.key,
    required this.userId,
  });

  double _money(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }

  int _number(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

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
              child: Text(
                'User লোড করা যায়নি.\n\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final document =
              snapshot.data;

          if (document == null ||
              !document.exists) {
            return const Center(
              child: Text(
                'User পাওয়া যায়নি।',
              ),
            );
          }

          final data =
              document.data() ?? {};

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

          final phone =
              data['phone']?.toString() ??
                  '';

          final bio =
              data['bio']?.toString() ??
                  '';

          final photoUrl =
              data['photoUrl']?.toString();

          final wallet =
              _money(data['wallet']);

          final followers =
              _number(
            data['followersCount'],
          );

          final following =
              _number(
            data['followingCount'],
          );

          final friends =
              _number(
            data['friendsCount'],
          );

          return ListView(
            padding:
                const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage:
                            photoUrl != null &&
                                    photoUrl.isNotEmpty
                                ? NetworkImage(
                                    photoUrl,
                                  )
                                : null,
                        child:
                            photoUrl == null ||
                                    photoUrl.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    size: 50,
                                  )
                                : null,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        name,
                        style:
                            const TextStyle(
                          fontSize: 24,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      if (username.isNotEmpty)
                        Text('@$username'),
                      const SizedBox(height: 8),
                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration:
                            BoxDecoration(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
                          ),
                          border:
                              Border.all(),
                        ),
                        child: Text(
                          role,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _infoCard(
                title: 'Account',
                children: [
                  _info(
                    Icons.email_outlined,
                    'Email',
                    email,
                  ),
                  _info(
                    Icons.phone_outlined,
                    'Phone',
                    phone.isEmpty
                        ? 'নেই'
                        : phone,
                  ),
                  _info(
                    Icons.badge_outlined,
                    'User ID',
                    userId,
                  ),
                  _info(
                    Icons.account_balance_wallet_outlined,
                    'Wallet',
                    '৳${wallet.toStringAsFixed(2)}',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _infoCard(
                title: 'Social',
                children: [
                  _info(
                    Icons.people_outline,
                    'Friends',
                    '$friends',
                  ),
                  _info(
                    Icons.group_outlined,
                    'Followers',
                    '$followers',
                  ),
                  _info(
                    Icons.person_add_outlined,
                    'Following',
                    '$following',
                  ),
                ],
              ),
              if (bio.isNotEmpty) ...[
                const SizedBox(height: 12),
                _infoCard(
                  title: 'Bio',
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.all(16),
                      child: Text(
                        bio,
                        style:
                            const TextStyle(
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _info(
    IconData icon,
    String title,
    String value,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(
        value,
        maxLines: 2,
        overflow:
            TextOverflow.ellipsis,
      ),
    );
  }
}

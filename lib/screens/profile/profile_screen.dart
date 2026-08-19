import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import 'earnings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService.instance;

  bool _loading = false;

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'আপনি কি সত্যিই Logout করতে চান?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('না'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    setState(() {
      _loading = true;
    });

    try {
      await _authService.signOut();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _authService.getAuthErrorMessage(error),
          ),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _openEditProfile(
    Map<String, dynamic> data,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          userData: data,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // EARNINGS
  // ============================================================

  void _openEarnings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const EarningsScreen(),
      ),
    );
  }

  // ============================================================
  // SETTINGS
  // ============================================================

  void _showSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SettingsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'আপনি লগইন করেননি।',
          ),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('আমার প্রোফাইল'),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Profile লোড করা যায়নি.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final data = snapshot.data?.data() ?? {};

        final name =
            data['name'] as String? ??
            user.displayName ??
            'বন্ধু';

        final username =
            data['username'] as String? ?? '';

        final bio =
            data['bio'] as String? ?? '';

        final photoUrl =
            data['photoUrl'] as String?;

        final coverPhotoUrl =
            data['coverPhotoUrl'] as String?;

        final followersCount =
            _numberValue(data['followersCount']);

        final followingCount =
            _numberValue(data['followingCount']);

        final friendsCount =
            _numberValue(data['friendsCount']);

        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: AppBar(
            title: const Text(
              'আমার প্রোফাইল',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Earnings',
                onPressed: _openEarnings,
                icon: const Icon(
                  Icons.account_balance_wallet_outlined,
                ),
              ),
              IconButton(
                tooltip: 'Settings',
                onPressed: _showSettings,
                icon: const Icon(
                  Icons.settings_outlined,
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get();
            },
            child: ListView(
              padding: const EdgeInsets.only(
                bottom: 40,
              ),
              children: [
                _buildHeader(
                  name: name,
                  username: username,
                  bio: bio,
                  photoUrl: photoUrl,
                  coverPhotoUrl: coverPhotoUrl,
                  followersCount: followersCount,
                  followingCount: followingCount,
                  friendsCount: friendsCount,
                ),

                const SizedBox(height: 8),

                _buildProfileActions(data),

                const SizedBox(height: 8),

                _buildEarningsCard(),

                const SizedBox(height: 8),

                _buildSectionTitle('আমার Posts'),

                _buildMyPosts(user.uid),

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed:
                          _loading ? null : _logout,
                      icon: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.logout_rounded,
                              color: Colors.red,
                            ),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader({
    required String name,
    required String username,
    required String bio,
    required String? photoUrl,
    required String? coverPhotoUrl,
    required int followersCount,
    required int followingCount,
    required int friendsCount,
  }) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          SizedBox(
            height: 170,
            width: double.infinity,
            child: coverPhotoUrl != null &&
                    coverPhotoUrl.isNotEmpty
                ? Image.network(
                    coverPhotoUrl,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) {
                      return _defaultCover();
                    },
                  )
                : _defaultCover(),
          ),

          Transform.translate(
            offset: const Offset(0, -55),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 58,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 53,
                    backgroundColor:
                        Colors.blue.shade100,
                    backgroundImage:
                        photoUrl != null &&
                                photoUrl.isNotEmpty
                            ? NetworkImage(photoUrl)
                            : null,
                    child:
                        photoUrl == null ||
                                photoUrl.isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 55,
                                color: Colors.blue,
                              )
                            : null,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (username.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '@$username',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 15,
                    ),
                  ),
                ],

                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                    ),
                    child: Text(
                      bio,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 22),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ProfileStat(
                          count: friendsCount,
                          label: 'Friends',
                        ),
                      ),
                      Expanded(
                        child: _ProfileStat(
                          count: followersCount,
                          label: 'Followers',
                        ),
                      ),
                      Expanded(
                        child: _ProfileStat(
                          count: followingCount,
                          label: 'Following',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultCover() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade700,
            Colors.blue.shade300,
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE ACTIONS
  // ============================================================

  Widget _buildProfileActions(
    Map<String, dynamic> data,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                _openEditProfile(data);
              },
              icon: const Icon(
                Icons.edit_outlined,
              ),
              label: const Text(
                'Edit Profile',
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            tooltip: 'Earnings',
            onPressed: _openEarnings,
            style: IconButton.styleFrom(
              backgroundColor:
                  Colors.green.shade50,
            ),
            icon: Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(width: 5),
          IconButton(
            tooltip: 'Settings',
            onPressed: _showSettings,
            style: IconButton.styleFrom(
              backgroundColor:
                  Colors.grey.shade100,
            ),
            icon: const Icon(
              Icons.settings_outlined,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EARNINGS CARD
  // ============================================================

  Widget _buildEarningsCard() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _openEarnings,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                Colors.green.shade700,
                Colors.green.shade400,
              ],
            ),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white24,
                child: Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Earnings & Wallet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'আপনার আয়, Wallet এবং Withdraw দেখুন',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(String title) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        12,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // MY POSTS
  // ============================================================

  Widget _buildMyPosts(String userId) {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where(
            'userId',
            isEqualTo: userId,
          )
          .orderBy(
            'createdAt',
            descending: true,
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(30),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: const Text(
              'Posts লোড করতে সমস্যা হয়েছে।',
              textAlign: TextAlign.center,
            ),
          );
        }

        final posts =
            snapshot.data?.docs ?? [];

        if (posts.isEmpty) {
          return Container(
            color: Colors.white,
            padding: const EdgeInsets.all(40),
            child: const Column(
              children: [
                Icon(
                  Icons.article_outlined,
                  size: 55,
                  color: Colors.grey,
                ),
                SizedBox(height: 12),
                Text(
                  'আপনার কোনো Post নেই।',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: posts.map((post) {
            final data = post.data();

            final text =
                data['text'] as String? ?? '';

            final imageUrl =
                data['imageUrl'] as String?;

            final timestamp =
                data['createdAt'] as Timestamp?;

            final likeCount =
                _numberValue(data['likeCount']);

            final commentCount =
                _numberValue(data['commentCount']);

            final shareCount =
                _numberValue(data['shareCount']);

            return Container(
              color: Colors.white,
              margin: const EdgeInsets.only(
                bottom: 8,
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            Colors.blue.shade100,
                        child: const Icon(
                          Icons.person,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          data['userName'] ??
                              'বন্ধু',
                          style: const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                      if (timestamp != null)
                        Text(
                          _formatDate(timestamp),
                          style: TextStyle(
                            color:
                                Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),

                  if (text.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                  ],

                  if (imageUrl != null &&
                      imageUrl.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(10),
                      child: Image.network(
                        imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error,
                                stackTrace) {
                          return Container(
                            height: 180,
                            color: Colors.grey.shade200,
                            alignment:
                                Alignment.center,
                            child: const Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      _PostCount(
                        icon: Icons.favorite_border,
                        count: likeCount,
                      ),
                      const SizedBox(width: 20),
                      _PostCount(
                        icon:
                            Icons.comment_outlined,
                        count: commentCount,
                      ),
                      const SizedBox(width: 20),
                      _PostCount(
                        icon: Icons.share_outlined,
                        count: shareCount,
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  static int _numberValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  static String _formatDate(
    Timestamp timestamp,
  ) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'এইমাত্র';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} মিনিট আগে';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} ঘণ্টা আগে';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} দিন আগে';
    }

    return '${date.day}/${date.month}/${date.year}';
  }
}

// ============================================================
// POST COUNT
// ============================================================

class _PostCount extends StatelessWidget {
  final IconData icon;
  final int count;

  const _PostCount({
    required this.icon,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 19,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 5),
        Text(
          count.toString(),
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// PROFILE STAT
// ============================================================

class _ProfileStat extends StatelessWidget {
  final int count;
  final String label;

  const _ProfileStat({
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// EDIT PROFILE
// ============================================================

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({
    super.key,
    required this.userData,
  });

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState
    extends State<EditProfileScreen> {
  final AuthService _authService =
      AuthService.instance;

  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  late final TextEditingController _phoneController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.userData['name'] ?? '',
    );

    _usernameController =
        TextEditingController(
      text: widget.userData['username'] ?? '',
    );

    _bioController = TextEditingController(
      text: widget.userData['bio'] ?? '',
    );

    _phoneController = TextEditingController(
      text: widget.userData['phone'] ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final name =
        _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('নাম লিখুন।'),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await _authService.updateProfile(
        name: name,
        username:
            _usernameController.text.trim(),
        bio: _bioController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile সফলভাবে আপডেট হয়েছে।',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _authService.getAuthErrorMessage(error),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor:
                  Colors.blue.shade100,
              child: const Icon(
                Icons.person,
                size: 50,
                color: Colors.blue,
              ),
            ),

            const SizedBox(height: 12),

            TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Photo upload পরের ধাপে চালু করা হবে।',
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.camera_alt_outlined,
              ),
              label: const Text(
                'Profile Photo পরিবর্তন',
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _nameController,
              textInputAction:
                  TextInputAction.next,
              decoration:
                  const InputDecoration(
                labelText: 'নাম',
                prefixIcon:
                    Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller:
                  _usernameController,
              textInputAction:
                  TextInputAction.next,
              decoration:
                  const InputDecoration(
                labelText: 'Username',
                hintText: 'যেমন: mojidul123',
                prefixIcon:
                    Icon(Icons.alternate_email),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: _bioController,
              maxLines: 4,
              maxLength: 160,
              decoration:
                  const InputDecoration(
                labelText: 'Bio',
                hintText:
                    'নিজের সম্পর্কে কিছু লিখুন...',
                prefixIcon:
                    Icon(Icons.info_outline),
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: _phoneController,
              keyboardType:
                  TextInputType.phone,
              decoration:
                  const InputDecoration(
                labelText: 'মোবাইল নম্বর',
                prefixIcon:
                    Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed:
                    _saving ? null : _saveProfile,
                child: _saving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SETTINGS
// ============================================================

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          _SettingsSection(
            title: 'Account',
            children: [
              ListTile(
                leading:
                    const Icon(Icons.person_outline),
                title: const Text(
                  'Account Information',
                ),
                subtitle: const Text(
                  'নাম, username এবং অন্যান্য তথ্য',
                ),
              ),
              ListTile(
                leading:
                    const Icon(Icons.lock_outline),
                title: const Text('Password'),
                subtitle: const Text(
                  'Password পরিবর্তন করুন',
                ),
                onTap: () {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Password settings পরের ধাপে যুক্ত হবে।',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 8),

          _SettingsSection(
            title: 'Privacy',
            children: [
              SwitchListTile(
                secondary: const Icon(
                  Icons.visibility_outlined,
                ),
                title: const Text(
                  'Profile Public',
                ),
                subtitle: const Text(
                  'অন্যরা আপনার Profile দেখতে পারবে',
                ),
                value: true,
                onChanged: (value) {},
              ),
              SwitchListTile(
                secondary: const Icon(
                  Icons.chat_bubble_outline,
                ),
                title: const Text(
                  'Allow Messages',
                ),
                subtitle: const Text(
                  'অন্যরা আপনাকে Message করতে পারবে',
                ),
                value: true,
                onChanged: (value) {},
              ),
            ],
          ),

          const SizedBox(height: 8),

          _SettingsSection(
            title: 'Notifications',
            children: [
              SwitchListTile(
                secondary: const Icon(
                  Icons.notifications_outlined,
                ),
                title: const Text(
                  'Push Notifications',
                ),
                value: true,
                onChanged: (value) {},
              ),
            ],
          ),

          const SizedBox(height: 8),

          _SettingsSection(
            title: 'App',
            children: [
              ListTile(
                leading:
                    const Icon(Icons.language_outlined),
                title: const Text('Language'),
                subtitle: const Text('বাংলা'),
              ),
              ListTile(
                leading:
                    const Icon(Icons.info_outline),
                title: const Text(
                  'About বন্ধু সোশ্যাল',
                ),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName:
                        'বন্ধু সোশ্যাল',
                    applicationVersion:
                        '1.0.0',
                    applicationLegalese:
                        '© বন্ধু সোশ্যাল',
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 30),

          const Center(
            child: Text(
              'বন্ধু সোশ্যাল • Version 1.0.0',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// ============================================================
// SETTINGS SECTION
// ============================================================

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              8,
            ),
            child: Text(
              title,
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/data_service.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DataService _dataService = DataService.instance;

  int _selectedIndex = 0;

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ProfileScreen(),
      ),
    );
  }

  void _openCreatePost() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const CreatePostSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),

      appBar: AppBar(
        title: const Text(
          'বন্ধু সোশ্যাল',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Search',
            onPressed: () {},
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            tooltip: 'Profile',
            onPressed: _openProfile,
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),

      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeFeed(),
          _buildFriendsPage(),
          _buildNotificationsPage(),
          _buildMenuPage(),
        ],
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Friends',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu),
            selectedIcon: Icon(Icons.menu_rounded),
            label: 'Menu',
          ),
        ],
      ),

      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _openCreatePost,
              icon: const Icon(Icons.add),
              label: const Text('Post'),
            )
          : null,
    );
  }

  // ============================================================
  // HOME FEED
  // ============================================================

  Widget _buildHomeFeed() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _dataService.postsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Feed লোড করতে সমস্যা হয়েছে।\n\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final posts = snapshot.data?.docs ?? [];

        return RefreshIndicator(
          onRefresh: () async {
            await Future<void>.delayed(
              const Duration(milliseconds: 500),
            );
          },
          child: ListView(
            padding: const EdgeInsets.only(
              top: 8,
              bottom: 100,
            ),
            children: [
              _buildCreatePostCard(),
              const SizedBox(height: 8),
              if (posts.isEmpty)
                _buildEmptyFeed()
              else
                ...posts.map(
                  (post) => PostCard(
                    post: post,
                    dataService: _dataService,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCreatePostCard() {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.blue.shade100,
            child: const Icon(
              Icons.person,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: _openCreatePost,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  user?.displayName != null
                      ? 'কী ভাবছেন, ${user!.displayName}?'
                      : 'কী ভাবছেন?',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _openCreatePost,
            icon: const Icon(
              Icons.photo_library_rounded,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFeed() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(50),
      child: const Column(
        children: [
          Icon(
            Icons.dynamic_feed_rounded,
            size: 70,
            color: Colors.grey,
          ),
          SizedBox(height: 18),
          Text(
            'এখনও কোনো Post নেই',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'প্রথম Post তৈরি করে শুরু করুন।',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FRIENDS
  // ============================================================

  Widget _buildFriendsPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'বন্ধু',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'আপনার বন্ধুদের এবং Friend Request এখানে দেখা যাবে।',
        ),
        const SizedBox(height: 25),
        _menuCard(
          icon: Icons.person_add_alt_1,
          title: 'Friend Requests',
          subtitle: 'আসা Friend Request দেখুন',
          onTap: () {},
        ),
        _menuCard(
          icon: Icons.people_alt_outlined,
          title: 'All Friends',
          subtitle: 'আপনার সব বন্ধু দেখুন',
          onTap: () {},
        ),
        _menuCard(
          icon: Icons.person_search_outlined,
          title: 'Find Friends',
          subtitle: 'নতুন বন্ধু খুঁজুন',
          onTap: () {},
        ),
      ],
    );
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  Widget _buildNotificationsPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Column(
            children: [
              Icon(
                Icons.notifications_none,
                size: 70,
                color: Colors.grey,
              ),
              SizedBox(height: 15),
              Text(
                'এখনও কোনো Notification নেই।',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MENU
  // ============================================================

  Widget _buildMenuPage() {
    final user = FirebaseAuth.instance.currentUser;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Menu',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 16),

        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.blue.shade100,
              child: const Icon(
                Icons.person,
                size: 30,
                color: Colors.blue,
              ),
            ),
            title: Text(
              user?.displayName ?? 'বন্ধু',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            subtitle: Text(
              user?.email ?? '',
            ),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: _openProfile,
          ),
        ),

        const SizedBox(height: 12),

        _menuCard(
          icon: Icons.person_outline,
          title: 'My Profile',
          subtitle: 'আপনার Profile দেখুন',
          onTap: _openProfile,
        ),

        _menuCard(
          icon: Icons.article_outlined,
          title: 'My Posts',
          subtitle: 'আপনার সব Post দেখুন',
          onTap: _openProfile,
        ),

        _menuCard(
          icon: Icons.settings_outlined,
          title: 'Settings',
          subtitle: 'Account ও Privacy settings',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SettingsScreen(),
              ),
            );
          },
        ),

        _menuCard(
          icon: Icons.help_outline,
          title: 'Help & Support',
          subtitle: 'সাহায্য এবং Support',
          onTap: () {},
        ),

        _menuCard(
          icon: Icons.info_outline,
          title: 'About',
          subtitle: 'বন্ধু সোশ্যাল সম্পর্কে',
          onTap: () {
            showAboutDialog(
              context: context,
              applicationName: 'বন্ধু সোশ্যাল',
              applicationVersion: '1.0.0',
            );
          },
        ),

        const SizedBox(height: 12),

        Card(
          child: ListTile(
            leading: const Icon(
              Icons.logout_rounded,
              color: Colors.red,
            ),
            title: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: _logout,
          ),
        ),
      ],
    );
  }

  Widget _menuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: Icon(
            icon,
            color: Colors.blue,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(
          Icons.chevron_right,
        ),
        onTap: onTap,
      ),
    );
  }
}


// ============================================================
// CREATE POST
// ============================================================

class CreatePostSheet extends StatefulWidget {
  const CreatePostSheet({super.key});

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final TextEditingController _controller =
      TextEditingController();

  final DataService _dataService =
      DataService.instance;

  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _createPost() async {
    final text = _controller.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post-এর লেখা লিখুন।'),
        ),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await _dataService.createPost(
        text: text,
      );

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Post সফলভাবে প্রকাশ হয়েছে।',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom:
            MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'নতুন Post তৈরি করুন',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: _loading
                    ? null
                    : () {
                        Navigator.of(context).pop();
                      },
                icon: const Icon(Icons.close),
              ),
            ],
          ),

          const Divider(),

          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: const Icon(
                  Icons.person,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                user?.displayName ?? 'বন্ধু',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          TextField(
            controller: _controller,
            maxLines: 6,
            maxLength: 5000,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'কী ভাবছেন?',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _loading
                  ? null
                  : _createPost,
              child: _loading
                  ? const SizedBox(
                      width: 23,
                      height: 23,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Post করুন',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}


// ============================================================
// POST CARD
// ============================================================

class PostCard extends StatelessWidget {
  final DocumentSnapshot<Map<String, dynamic>> post;
  final DataService dataService;

  const PostCard({
    super.key,
    required this.post,
    required this.dataService,
  });

  Future<void> _deletePost(
    BuildContext context,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Post মুছে ফেলবেন?',
          ),
          content: const Text(
            'এই Post স্থায়ীভাবে মুছে যাবে।',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('না'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('মুছে ফেলুন'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await dataService.deletePost(post.id);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Post মুছে ফেলা হয়েছে।',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = post.data() ?? {};

    final userId =
        data['userId'] as String? ?? '';

    final userName =
        data['userName'] as String? ?? 'বন্ধু';

    final text =
        data['text'] as String? ?? '';

    final imageUrl =
        data['imageUrl'] as String?;

    final createdAt =
        data['createdAt'] as Timestamp?;

    final currentUser =
        FirebaseAuth.instance.currentUser;

    final isOwner =
        currentUser != null &&
        currentUser.uid == userId;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      padding: const EdgeInsets.all(14),
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
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(createdAt),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              if (isOwner)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deletePost(context);
                    }
                  },
                  itemBuilder: (context) {
                    return const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ];
                  },
                ),
            ],
          ),

          if (text.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                height: 1.45,
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
                    (context, error, stackTrace) {
                  return Container(
                    height: 180,
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      size: 50,
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 12),

          const Divider(),

          Row(
            children: [
              Expanded(
                child: _LikeButton(
                  postId: post.id,
                  dataService: dataService,
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (_) =>
                          CommentsSheet(
                        postId: post.id,
                        dataService: dataService,
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.comment_outlined,
                  ),
                  label: const Text('Comment'),
                ),
              ),
              Expanded(
                child: _ShareButton(
                  postId: post.id,
                  dataService: dataService,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDate(
    Timestamp? timestamp,
  ) {
    if (timestamp == null) {
      return 'এইমাত্র';
    }

    final date = timestamp.toDate();
    final difference =
        DateTime.now().difference(date);

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
// LIKE
// ============================================================

class _LikeButton extends StatelessWidget {
  final String postId;
  final DataService dataService;

  const _LikeButton({
    required this.postId,
    required this.dataService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream:
          dataService.likeStatusStream(postId),
      builder: (context, snapshot) {
        final liked =
            snapshot.data ?? false;

        return TextButton.icon(
          onPressed: () async {
            try {
              await dataService.likePost(
                postId,
              );
            } catch (error) {
              if (!context.mounted) return;

              ScaffoldMessenger.of(context)
                  .showSnackBar(
                SnackBar(
                  content: Text(
                    error.toString(),
                  ),
                ),
              );
            }
          },
          icon: Icon(
            liked
                ? Icons.favorite
                : Icons.favorite_border,
            color:
                liked ? Colors.red : null,
          ),
          label: Text(
            liked ? 'Liked' : 'Like',
          ),
        );
      },
    );
  }
}


// ============================================================
// SHARE
// ============================================================

class _ShareButton extends StatelessWidget {
  final String postId;
  final DataService dataService;

  const _ShareButton({
    required this.postId,
    required this.dataService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream:
          dataService.shareStatusStream(postId),
      builder: (context, snapshot) {
        final shared =
            snapshot.data ?? false;

        return TextButton.icon(
          onPressed: () async {
            try {
              await dataService.sharePost(
                postId,
              );
            } catch (error) {
              if (!context.mounted) return;

              ScaffoldMessenger.of(context)
                  .showSnackBar(
                SnackBar(
                  content: Text(
                    error.toString(),
                  ),
                ),
              );
            }
          },
          icon: Icon(
            shared
                ? Icons.share
                : Icons.share_outlined,
          ),
          label: Text(
            shared ? 'Shared' : 'Share',
          ),
        );
      },
    );
  }
}


// ============================================================
// COMMENTS
// ============================================================

class CommentsSheet extends StatefulWidget {
  final String postId;
  final DataService dataService;

  const CommentsSheet({
    super.key,
    required this.postId,
    required this.dataService,
  });

  @override
  State<CommentsSheet> createState() =>
      _CommentsSheetState();
}

class _CommentsSheetState
    extends State<CommentsSheet> {
  final TextEditingController _controller =
      TextEditingController();

  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text =
        _controller.text.trim();

    if (text.isEmpty) return;

    setState(() {
      _sending = true;
    });

    try {
      await widget.dataService.addComment(
        postId: widget.postId,
        text: text,
      );

      _controller.clear();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            error.toString(),
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height:
            MediaQuery.of(context).size.height *
                0.75,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Comments',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const Divider(height: 1),

            Expanded(
              child: StreamBuilder<
                  QuerySnapshot<
                      Map<String, dynamic>>>(
                stream: widget.dataService
                    .commentsStream(
                  widget.postId,
                ),
                builder:
                    (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child:
                          CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Comment লোড করা যায়নি।',
                      ),
                    );
                  }

                  final comments =
                      snapshot.data?.docs ??
                          [];

                  if (comments.isEmpty) {
                    return const Center(
                      child: Text(
                        'এখনও কোনো Comment নেই।',
                      ),
                    );
                  }

                  return ListView.builder(
                    padding:
                        const EdgeInsets.all(12),
                    itemCount:
                        comments.length,
                    itemBuilder:
                        (context, index) {
                      final comment =
                          comments[index]
                              .data();

                      return ListTile(
                        leading:
                            CircleAvatar(
                          backgroundColor:
                              Colors.blue
                                  .shade100,
                          child: const Icon(
                            Icons.person,
                            color:
                                Colors.blue,
                          ),
                        ),
                        title: Text(
                          comment['userName'] ??
                              'বন্ধু',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          comment['text'] ??
                              '',
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            Container(
              padding:
                  const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller:
                          _controller,
                      textInputAction:
                          TextInputAction.send,
                      onSubmitted: (_) =>
                          _sendComment(),
                      decoration:
                          InputDecoration(
                        hintText:
                            'Comment লিখুন...',
                        filled: true,
                        fillColor:
                            Colors.grey
                                .shade100,
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(24),
                          borderSide:
                              BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sending
                        ? null
                        : _sendComment,
                    icon: _sending
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

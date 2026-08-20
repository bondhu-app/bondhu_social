// FILE: lib/screens/home/home_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/ad_service.dart';
import '../../services/data_service.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  final DataService _dataService = DataService.instance;
  final AdService _adService = AdService.instance;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _loadAds();
  }

  // ============================================================
  // LOAD ADS
  // ============================================================

  void _loadAds() {
    try {
      _adService.loadBannerAd();
    } catch (_) {}

    try {
      _adService.loadInterstitialAd();
    } catch (_) {}

    try {
      _adService.loadRewardedAd();
    } catch (_) {}

    try {
      _adService.loadRewardedAd2();
    } catch (_) {}

    // Native Ad temporarily disabled.
    //
    // The NativeAd uses factoryId: 'listTile'.
    // Android NativeAdFactory registration will be added
    // separately after confirming the app starts normally.
    //
    // DO NOT enable this yet.
    //
    // try {
    //   _adService.loadNativeAd();
    // } catch (_) {}

    try {
      _adService.loadAppOpenAd();
    } catch (_) {}
  }

  // ============================================================
  // APP LIFECYCLE
  // ============================================================

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.resumed) {
      try {
        _adService.showAppOpenAdIfAvailable();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Logout করা যায়নি: $error',
          ),
        ),
      );
    }
  }

  // ============================================================
  // PROFILE
  // ============================================================

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProfileScreen(),
      ),
    );
  }

  // ============================================================
  // CREATE POST
  // ============================================================

  void _openCreatePost() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const CreatePostSheet(),
    );
  }

  // ============================================================
  // REWARDED AD
  // ============================================================

  void _showRewardedAd() {
    try {
      _adService.showRewardedAd(
        onReward: () {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Reward সফলভাবে পাওয়া গেছে।',
              ),
            ),
          );
        },
        onFinished: () {},
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Rewarded Ad এখন প্রস্তুত নয়।',
          ),
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),

      // ========================================================
      // APP BAR
      // ========================================================

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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Search feature শীঘ্রই আসছে।',
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.search_rounded,
            ),
          ),
          IconButton(
            onPressed: _openProfile,
            icon: const Icon(
              Icons.account_circle_outlined,
            ),
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeFeed(),
          _buildFriendsPage(),
          _buildNotificationsPage(),
          _buildMenuPage(),
        ],
      ),

      // ========================================================
      // BOTTOM NAVIGATION
      // ========================================================

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
            ),
            selectedIcon: Icon(
              Icons.home,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.people_outline,
            ),
            selectedIcon: Icon(
              Icons.people,
            ),
            label: 'Friends',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.notifications_none,
            ),
            selectedIcon: Icon(
              Icons.notifications,
            ),
            label: 'Notifications',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.menu,
            ),
            selectedIcon: Icon(
              Icons.menu_rounded,
            ),
            label: 'Menu',
          ),
        ],
      ),

      // ========================================================
      // CREATE POST BUTTON
      // ========================================================

      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _openCreatePost,
              icon: const Icon(
                Icons.add,
              ),
              label: const Text(
                'Post',
              ),
            )
          : null,
    );
  }

  // ============================================================
  // HOME FEED
  // ============================================================

  Widget _buildHomeFeed() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _dataService.postsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Feed লোড করতে সমস্যা হয়েছে.\n\n'
                '${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final posts = snapshot.data?.docs ?? [];

        return RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(
              const Duration(
                milliseconds: 300,
              ),
            );
          },
          child: ListView(
            padding: const EdgeInsets.only(
              top: 8,
              bottom: 100,
            ),
            children: [
              _buildCreatePostCard(),

              const SizedBox(
                height: 8,
              ),

              // Banner Ad
              _buildBannerAd(),

              const SizedBox(
                height: 8,
              ),

              if (posts.isEmpty)
                _buildEmptyFeed()
              else
                ..._buildPostsWithAds(posts),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // POSTS + ADS
  // ============================================================

  List<Widget> _buildPostsWithAds(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> posts,
  ) {
    final List<Widget> items = [];

    for (int i = 0; i < posts.length; i++) {
      items.add(
        PostCard(
          post: posts[i],
          dataService: _dataService,
        ),
      );

      // প্রতি 3টি Post পর Banner
      if ((i + 1) % 3 == 0) {
        items.add(
          _buildBannerAd(),
        );
      }
    }

    return items;
  }

  // ============================================================
  // BANNER AD
  // ============================================================

  Widget _buildBannerAd() {
    try {
      final banner = _adService.bannerAd;

      if (banner == null) {
        return const SizedBox(
          height: 0,
        );
      }

      return Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        alignment: Alignment.center,
        child: SizedBox(
          width: banner.size.width.toDouble(),
          height: banner.size.height.toDouble(),
          child: _adService.bannerAdWidget(),
        ),
      );
    } catch (_) {
      return const SizedBox(
        height: 0,
      );
    }
  }

  // ============================================================
  // CREATE POST CARD
  // ============================================================

  Widget _buildCreatePostCard() {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            child: Icon(
              Icons.person,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

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

  // ============================================================
  // EMPTY FEED
  // ============================================================

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
          SizedBox(
            height: 18,
          ),
          Text(
            'এখনও কোনো Post নেই',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
            height: 8,
          ),
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

        const SizedBox(
          height: 20,
        ),

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

        const SizedBox(
          height: 20,
        ),

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

              SizedBox(
                height: 15,
              ),

              Text(
                'এখনও কোনো Notification নেই।',
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

        const SizedBox(
          height: 16,
        ),

        Card(
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(
                Icons.person,
              ),
            ),
            title: Text(
              user?.displayName ?? 'বন্ধু',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
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

        const SizedBox(
          height: 12,
        ),

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
          onTap: () {},
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

        const SizedBox(
          height: 12,
        ),

        // ======================================================
        // REWARDED AD
        // ======================================================

        Card(
          child: ListTile(
            leading: const Icon(
              Icons.card_giftcard,
            ),
            title: const Text(
              'Watch Ad & Get Reward',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text(
              'একটি বিজ্ঞাপন দেখে Reward নিন',
            ),
            trailing: const Icon(
              Icons.play_circle_outline,
            ),
            onTap: _showRewardedAd,
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        // ======================================================
        // LOGOUT
        // ======================================================

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

  // ============================================================
  // MENU CARD
  // ============================================================

  Widget _menuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 8,
      ),
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
        subtitle: Text(
          subtitle,
        ),
        trailing: const Icon(
          Icons.chevron_right,
        ),
        onTap: onTap,
      ),
    );
  }
}

// ================================================================
// CREATE POST
// ================================================================

class CreatePostSheet extends StatefulWidget {
  const CreatePostSheet({
    super.key,
  });

  @override
  State<CreatePostSheet> createState() =>
      _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final _controller = TextEditingController();

  final _dataService = DataService.instance;

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
          content: Text(
            'Post-এর লেখা লিখুন।',
          ),
        ),
      );
      return;
    }

    setState(
      () => _loading = true,
    );

    try {
      await _dataService.createPost(
        text: text,
      );

      if (!mounted) return;

      Navigator.pop(context);

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
          content: Text(
            error.toString(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(
          () => _loading = false,
        );
      }
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
                    : () => Navigator.pop(context),
                icon: const Icon(
                  Icons.close,
                ),
              ),
            ],
          ),

          const Divider(),

          Row(
            children: [
              const CircleAvatar(
                child: Icon(
                  Icons.person,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Text(
                user?.displayName ?? 'বন্ধু',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 15,
          ),

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

          const SizedBox(
            height: 8,
          ),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _loading ? null : _createPost,
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

// ================================================================
// POST CARD
// ================================================================

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
      builder: (_) => AlertDialog(
        title: const Text(
          'Post মুছে ফেলবেন?',
        ),
        content: const Text(
          'এই Post স্থায়ীভাবে মুছে যাবে।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              false,
            ),
            child: const Text(
              'না',
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              true,
            ),
            child: const Text(
              'মুছে ফেলুন',
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await dataService.deletePost(
        post.id,
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Post মুছে ফেলা হয়েছে।',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = post.data() ?? {};

    final userId = data['userId'] as String? ?? '';

    final userName = data['userName'] as String? ?? 'বন্ধু';

    final text = data['text'] as String? ?? '';

    final imageUrl = data['imageUrl'] as String?;

    final createdAt = data['createdAt'] as Timestamp?;

    final likeCount =
        (data['likeCount'] as num?)?.toInt() ?? 0;

    final commentCount =
        (data['commentCount'] as num?)?.toInt() ?? 0;

    final shareCount =
        (data['shareCount'] as num?)?.toInt() ?? 0;

    final currentUser =
        FirebaseAuth.instance.currentUser;

    final isOwner =
        currentUser != null &&
        currentUser.uid == userId;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 8,
      ),
      color: Colors.white,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // USER HEADER
          // ======================================================

          Row(
            children: [
              const CircleAvatar(
                child: Icon(
                  Icons.person,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

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
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete',
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // ======================================================
          // TEXT
          // ======================================================

          if (text.isNotEmpty) ...[
            const SizedBox(
              height: 14,
            ),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                height: 1.45,
              ),
            ),
          ],

          // ======================================================
          // IMAGE
          // ======================================================

          if (imageUrl != null &&
              imageUrl.isNotEmpty) ...[
            const SizedBox(
              height: 12,
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (
                  _,
                  __,
                  ___,
                ) =>
                    Container(
                  height: 180,
                  color: Colors.grey.shade200,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    size: 50,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(
            height: 10,
          ),

          // ======================================================
          // COUNTS
          // ======================================================

          Row(
            children: [
              if (likeCount > 0) ...[
                const Icon(
                  Icons.favorite,
                  size: 18,
                  color: Colors.red,
                ),
                const SizedBox(
                  width: 5,
                ),
                Text(
                  '$likeCount',
                ),
              ],

              const Spacer(),

              if (commentCount > 0)
                Text(
                  '$commentCount Comment',
                ),

              if (commentCount > 0 &&
                  shareCount > 0)
                const SizedBox(
                  width: 12,
                ),

              if (shareCount > 0)
                Text(
                  '$shareCount Share',
                ),
            ],
          ),

          const Divider(),

          // ======================================================
          // ACTION BUTTONS
          // ======================================================

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
                      builder: (_) => CommentsSheet(
                        postId: post.id,
                        dataService: dataService,
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.comment_outlined,
                  ),
                  label: Text(
                    commentCount > 0
                        ? 'Comment $commentCount'
                        : 'Comment',
                  ),
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

  // ============================================================
  // DATE FORMAT
  // ============================================================

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

// ================================================================
// LIKE BUTTON
// ================================================================

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
      stream: dataService.likeStatusStream(
        postId,
      ),
      builder: (context, snapshot) {
        final liked = snapshot.data ?? false;

        return TextButton.icon(
          onPressed: () async {
            try {
              await dataService.likePost(
                postId,
              );
            } catch (error) {
              if (!context.mounted) {
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
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
            color: liked ? Colors.red : null,
          ),
          label: Text(
            liked ? 'Liked' : 'Like',
            style: TextStyle(
              color: liked ? Colors.red : null,
              fontWeight:
                  liked ? FontWeight.bold : null,
            ),
          ),
        );
      },
    );
  }
}

// ================================================================
// SHARE BUTTON
// ================================================================

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
      stream: dataService.shareStatusStream(
        postId,
      ),
      builder: (context, snapshot) {
        final shared = snapshot.data ?? false;

        return TextButton.icon(
          onPressed: () async {
            try {
              await dataService.sharePost(
                postId,
              );

              if (!context.mounted) {
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    shared
                        ? 'Share সরিয়ে দেওয়া হয়েছে।'
                        : 'Post Share হয়েছে।',
                  ),
                  duration: const Duration(
                    seconds: 1,
                  ),
                ),
              );
            } catch (error) {
              if (!context.mounted) {
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
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
                ? Icons.check_circle
                : Icons.share_outlined,
            color: shared ? Colors.green : null,
          ),
          label: Text(
            shared ? 'Shared' : 'Share',
            style: TextStyle(
              color: shared ? Colors.green : null,
              fontWeight:
                  shared ? FontWeight.bold : null,
            ),
          ),
        );
      },
    );
  }
}

// ================================================================
// COMMENTS SHEET
// ================================================================

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
  final _controller = TextEditingController();

  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _controller.text.trim();

    if (text.isEmpty || _sending) {
      return;
    }

    setState(
      () => _sending = true,
    );

    try {
      await widget.dataService.addComment(
        postId: widget.postId,
        text: text,
      );

      _controller.clear();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(
          () => _sending = false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height:
            MediaQuery.of(context).size.height * .75,
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

            const Divider(
              height: 1,
            ),

            // ==================================================
            // COMMENTS LIST
            // ==================================================

            Expanded(
              child: StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>>(
                stream: widget.dataService.commentsStream(
                  widget.postId,
                ),
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
                        'Comment লোড করা যায়নি.\n'
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  final comments =
                      snapshot.data?.docs ?? [];

                  if (comments.isEmpty) {
                    return const Center(
                      child: Text(
                        'এখনও কোনো Comment নেই।',
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: comments.length,
                    itemBuilder: (
                      context,
                      index,
                    ) {
                      final doc = comments[index];

                      final comment = doc.data();

                      final currentUser =
                          FirebaseAuth.instance.currentUser;

                      final isMine =
                          currentUser != null &&
                          comment['userId'] ==
                              currentUser.uid;

                      return Card(
                        margin: const EdgeInsets.only(
                          bottom: 8,
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(
                              Icons.person,
                            ),
                          ),
                          title: Text(
                            comment['userName'] ??
                                'বন্ধু',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            comment['text'] ?? '',
                          ),
                          trailing: isMine
                              ? IconButton(
                                  onPressed: () async {
                                    try {
                                      await widget
                                          .dataService
                                          .deleteComment(
                                        postId:
                                            widget.postId,
                                        commentId:
                                            doc.id,
                                      );
                                    } catch (error) {
                                      if (!context.mounted) {
                                        return;
                                      }

                                      ScaffoldMessenger.of(
                                              context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            error.toString(),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.delete_outline,
                                  ),
                                )
                              : null,
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // ==================================================
            // COMMENT INPUT
            // ==================================================

            Container(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction:
                          TextInputAction.send,
                      onSubmitted: (_) =>
                          _sendComment(),
                      decoration: InputDecoration(
                        hintText: 'Comment লিখুন...',
                        filled: true,
                        fillColor:
                            Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(24),
                          borderSide:
                              BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  IconButton(
                    onPressed:
                        _sending ? null : _sendComment,
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

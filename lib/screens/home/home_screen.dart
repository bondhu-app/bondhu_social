import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

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

  BannerAd? _bannerAd;
  bool _bannerLoaded = false;

  NativeAd? _nativeAd;
  bool _nativeLoaded = false;

  DateTime? _lastInterstitialTime;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _loadBannerAd();
    _loadNativeAd();

    _adService.loadInterstitialAd();
    _adService.loadRewardedAd();
    _adService.loadRewardedAd2();
    _adService.loadAppOpenAd();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _bannerAd?.dispose();
    _nativeAd?.dispose();

    super.dispose();
  }

  // ============================================================
  // APP LIFECYCLE
  // ============================================================

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.resumed) {
      _adService.showAppOpenAdIfAvailable();
    }
  }

  // ============================================================
  // BANNER AD
  // ============================================================

  void _loadBannerAd() {
    final banner = _adService.createBannerAd(
      onLoaded: () {
        if (!mounted) return;

        setState(() {
          _bannerLoaded = true;
        });
      },
      onFailed: () {
        if (!mounted) return;

        setState(() {
          _bannerLoaded = false;
        });
      },
    );

    _bannerAd = banner;
  }

  // ============================================================
  // NATIVE ADVANCED AD
  // ============================================================

  void _loadNativeAd() {
    final native = _adService.createNativeAd(
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;

          setState(() {
            _nativeLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();

          if (!mounted) return;

          setState(() {
            _nativeLoaded = false;
          });
        },
      ),
    );

    _nativeAd = native;
  }

  // ============================================================
  // INTERSTITIAL
  // ============================================================

  void _maybeShowInterstitial() {
    final now = DateTime.now();

    if (_lastInterstitialTime != null) {
      final difference =
          now.difference(_lastInterstitialTime!);

      if (difference.inMinutes < 5) {
        return;
      }
    }

    if (!_adService.isInterstitialReady) {
      _adService.loadInterstitialAd();
      return;
    }

    _lastInterstitialTime = now;

    _adService.showInterstitialAd();
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    final shouldLogout =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'আপনি কি আপনার Account থেকে Logout করতে চান?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('না'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    await FirebaseAuth.instance.signOut();
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
    ).then((_) {
      // নতুন Post করার পরে Interstitial
      // দেখানোর চেষ্টা করা হবে।
      _maybeShowInterstitial();
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF0F2F5),

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
              _showSearchDialog();
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

      bottomNavigationBar:
          NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected:
            (index) {
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

      floatingActionButton:
          _selectedIndex == 0
              ? FloatingActionButton.extended(
                  onPressed:
                      _openCreatePost,
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
        QuerySnapshot<
            Map<String, dynamic>>>(
      stream:
          _dataService.postsStream(),
      builder: (
        context,
        snapshot,
      ) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding:
                  const EdgeInsets.all(24),
              child: Text(
                'Feed লোড করতে সমস্যা হয়েছে।\n\n'
                '${snapshot.error}',
                textAlign:
                    TextAlign.center,
              ),
            ),
          );
        }

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child:
                CircularProgressIndicator(),
          );
        }

        final posts =
            snapshot.data?.docs ?? [];

        return RefreshIndicator(
          onRefresh: () async {
            await Future<void>.delayed(
              const Duration(
                milliseconds: 300,
              ),
            );
          },
          child: ListView.builder(
            padding:
                const EdgeInsets.only(
              top: 8,
              bottom: 100,
            ),
            itemCount:
                _feedItemCount(posts.length),
            itemBuilder:
                (context, index) {
              return _buildFeedItem(
                posts,
                index,
              );
            },
          ),
        );
      },
    );
  }

  // ============================================================
  // FEED ITEM COUNT
  // ============================================================

  int _feedItemCount(int postCount) {
    if (postCount == 0) {
      return 2;
    }

    int count = 1;

    for (int i = 0;
        i < postCount;
        i++) {
      count++;

      // Native Ad after every 5 posts
      if ((i + 1) % 5 == 0) {
        count++;
      }

      // Banner after every 8 posts
      if ((i + 1) % 8 == 0) {
        count++;
      }
    }

    return count;
  }

  // ============================================================
  // FEED ITEM
  // ============================================================

  Widget _buildFeedItem(
    List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        posts,
    int index,
  ) {
    if (index == 0) {
      return Column(
        children: [
          _buildCreatePostCard(),
          const SizedBox(height: 8),
          if (_bannerLoaded &&
              _bannerAd != null)
            _buildBannerAd(),
        ],
      );
    }

    if (posts.isEmpty) {
      return _buildEmptyFeed();
    }

    int postIndex = 0;

    for (int i = 1;
        i <= posts.length;
        i++) {
      if (postIndex >= posts.length) {
        break;
      }

      if (index == i) {
        return PostCard(
          post: posts[postIndex],
          dataService: _dataService,
        );
      }

      postIndex++;
    }

    int currentPosition = 1;

    for (int i = 0;
        i < posts.length;
        i++) {
      currentPosition++;

      if ((i + 1) % 5 == 0) {
        if (index == currentPosition) {
          if (_nativeLoaded &&
              _nativeAd != null) {
            return _buildNativeAd();
          }

          return const SizedBox.shrink();
        }

        currentPosition++;
      }

      if ((i + 1) % 8 == 0) {
        if (index == currentPosition) {
          if (_bannerLoaded &&
              _bannerAd != null) {
            return _buildBannerAd();
          }

          return const SizedBox.shrink();
        }

        currentPosition++;
      }
    }

    return const SizedBox.shrink();
  }

  // ============================================================
  // BANNER WIDGET
  // ============================================================

  Widget _buildBannerAd() {
    final banner = _bannerAd;

    if (banner == null ||
        !_bannerLoaded) {
      return const SizedBox.shrink();
    }

    return Container(
      margin:
          const EdgeInsets.symmetric(
        vertical: 8,
      ),
      color: Colors.white,
      width: double.infinity,
      height: banner.size.height.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(
        ad: banner,
      ),
    );
  }

  // ============================================================
  // NATIVE AD WIDGET
  // ============================================================

  Widget _buildNativeAd() {
    final native = _nativeAd;

    if (native == null ||
        !_nativeLoaded) {
      return const SizedBox.shrink();
    }

    return Container(
      margin:
          const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 4,
      ),
      height: 320,
      width: double.infinity,
      color: Colors.white,
      child: AdWidget(
        ad: native,
      ),
    );
  }

  // ============================================================
  // CREATE POST CARD
  // ============================================================

  Widget _buildCreatePostCard() {
    final user =
        FirebaseAuth.instance.currentUser;

    return Container(
      color: Colors.white,
      padding:
          const EdgeInsets.all(14),
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
              borderRadius:
                  BorderRadius.circular(
                24,
              ),
              onTap:
                  _openCreatePost,
              child: Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.grey.shade100,
                  borderRadius:
                      BorderRadius.circular(
                    24,
                  ),
                ),
                child: Text(
                  user?.displayName != null
                      ? 'কী ভাবছেন, ${user!.displayName}?'
                      : 'কী ভাবছেন?',
                  style: TextStyle(
                    color:
                        Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed:
                _openCreatePost,
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
      padding:
          const EdgeInsets.all(50),
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
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          SizedBox(
            height: 8,
          ),
          Text(
            'প্রথম Post তৈরি করে শুরু করুন।',
            textAlign:
                TextAlign.center,
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
      padding:
          const EdgeInsets.all(16),
      children: [
        const Text(
          'বন্ধু',
          style: TextStyle(
            fontSize: 26,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        _menuCard(
          icon:
              Icons.person_add_alt_1,
          title:
              'Friend Requests',
          subtitle:
              'আসা Friend Request দেখুন',
          onTap: () {
            _showComingSoon(
              'Friend Requests',
            );
          },
        ),
        _menuCard(
          icon:
              Icons.people_alt_outlined,
          title:
              'All Friends',
          subtitle:
              'আপনার সব বন্ধু দেখুন',
          onTap: () {
            _showComingSoon(
              'All Friends',
            );
          },
        ),
        _menuCard(
          icon:
              Icons.person_search_outlined,
          title:
              'Find Friends',
          subtitle:
              'নতুন বন্ধু খুঁজুন',
          onTap: () {
            _showComingSoon(
              'Find Friends',
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  Widget _buildNotificationsPage() {
    return ListView(
      padding:
          const EdgeInsets.all(16),
      children: [
        const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 26,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        Container(
          padding:
              const EdgeInsets.all(40),
          decoration:
              BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(
              14,
            ),
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
    final user =
        FirebaseAuth.instance.currentUser;

    return ListView(
      padding:
          const EdgeInsets.all(16),
      children: [
        const Text(
          'Menu',
          style: TextStyle(
            fontSize: 26,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        const SizedBox(
          height: 16,
        ),
        Card(
          child: ListTile(
            leading:
                const CircleAvatar(
              child: Icon(
                Icons.person,
              ),
            ),
            title: Text(
              user?.displayName ??
                  'বন্ধু',
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            subtitle: Text(
              user?.email ?? '',
            ),
            trailing:
                const Icon(
              Icons.chevron_right,
            ),
            onTap:
                _openProfile,
          ),
        ),
        const SizedBox(
          height: 12,
        ),
        _menuCard(
          icon:
              Icons.person_outline,
          title:
              'My Profile',
          subtitle:
              'আপনার Profile দেখুন',
          onTap:
              _openProfile,
        ),
        _menuCard(
          icon:
              Icons.article_outlined,
          title:
              'My Posts',
          subtitle:
              'আপনার সব Post দেখুন',
          onTap:
              _openProfile,
        ),
        _menuCard(
          icon:
              Icons.settings_outlined,
          title:
              'Settings',
          subtitle:
              'Account ও Privacy settings',
          onTap: () {
            _showComingSoon(
              'Settings',
            );
          },
        ),
        _menuCard(
          icon:
              Icons.help_outline,
          title:
              'Help & Support',
          subtitle:
              'সাহায্য এবং Support',
          onTap: () {
            _showComingSoon(
              'Help & Support',
            );
          },
        ),
        _menuCard(
          icon:
              Icons.info_outline,
          title:
              'About',
          subtitle:
              'বন্ধু সোশ্যাল সম্পর্কে',
          onTap: () {
            showAboutDialog(
              context: context,
              applicationName:
                  'বন্ধু সোশ্যাল',
              applicationVersion:
                  '1.0.0',
            );
          },
        ),
        const SizedBox(
          height: 12,
        ),
        Card(
          child: ListTile(
            leading:
                const Icon(
              Icons.logout_rounded,
              color: Colors.red,
            ),
            title:
                const Text(
              'Logout',
              style:
                  TextStyle(
                color: Colors.red,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            onTap:
                _logout,
          ),
        ),

        const SizedBox(
          height: 25,
        ),

        // ======================================================
        // REWARDED AD
        // ======================================================

        Card(
          child: ListTile(
            leading:
                const CircleAvatar(
              child: Icon(
                Icons.card_giftcard,
              ),
            ),
            title:
                const Text(
              'Watch Rewarded Ad',
              style:
                  TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            subtitle:
                const Text(
              'বিজ্ঞাপন দেখুন এবং Reward পান',
            ),
            trailing:
                const Icon(
              Icons.play_arrow,
            ),
            onTap:
                _showRewardedAd,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // REWARDED AD
  // ============================================================

  void _showRewardedAd() {
    if (!_adService.isRewardedReady) {
      _adService.loadRewardedAd();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Rewarded Ad প্রস্তুত হচ্ছে। একটু পরে চেষ্টা করুন।',
          ),
        ),
      );

      return;
    }

    _adService.showRewardedAd(
      onReward: (reward) {
        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              'আপনি ${reward.amount} ${reward.type} Reward পেয়েছেন।',
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void _showSearchDialog() {
    final controller =
        TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
              const Text(
            'Search',
          ),
          content:
              TextField(
            controller:
                controller,
            autofocus: true,
            decoration:
                const InputDecoration(
              hintText:
                  'User বা Post Search করুন...',
              prefixIcon:
                  Icon(
                Icons.search,
              ),
              border:
                  OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text(
                'বন্ধ করুন',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );

                _showComingSoon(
                  'Search',
                );
              },
              child:
                  const Text(
                'Search',
              ),
            ),
          ],
        );
      },
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
      margin:
          const EdgeInsets.only(
        bottom: 8,
      ),
      child: ListTile(
        leading:
            CircleAvatar(
          backgroundColor:
              Colors.blue.shade50,
          child:
              Icon(
            icon,
            color: Colors.blue,
          ),
        ),
        title:
            Text(
          title,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.w600,
          ),
        ),
        subtitle:
            Text(
          subtitle,
        ),
        trailing:
            const Icon(
          Icons.chevron_right,
        ),
        onTap:
            onTap,
      ),
    );
  }

  // ============================================================
  // COMING SOON
  // ============================================================

  void _showComingSoon(
    String feature,
  ) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          '$feature feature শীঘ্রই আসছে।',
        ),
      ),
    );
  }
}

// ==================================================================
// CREATE POST SHEET
// ==================================================================

class CreatePostSheet
    extends StatefulWidget {
  const CreatePostSheet({
    super.key,
  });

  @override
  State<CreatePostSheet> createState() =>
      _CreatePostSheetState();
}

class _CreatePostSheetState
    extends State<CreatePostSheet> {
  final _controller =
      TextEditingController();

  final _dataService =
      DataService.instance;

  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _createPost() async {
    final text =
        _controller.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Post-এর লেখা লিখুন।',
          ),
        ),
      );
      return;
    }

    if (_loading) return;

    setState(() {
      _loading = true;
    });

    try {
      await _dataService.createPost(
        text: text,
      );

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Post সফলভাবে প্রকাশ হয়েছে।',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content:
              Text(
            error.toString(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final user =
        FirebaseAuth.instance.currentUser;

    return Padding(
      padding:
          EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom:
            MediaQuery.of(
                  context,
                )
                    .viewInsets
                    .bottom +
                16,
      ),
      child:
          Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(
                child:
                    Text(
                  'নতুন Post তৈরি করুন',
                  style:
                      TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed:
                    _loading
                        ? null
                        : () =>
                            Navigator.pop(
                              context,
                            ),
                icon:
                    const Icon(
                  Icons.close,
                ),
              ),
            ],
          ),
          const Divider(),
          Row(
            children: [
              const CircleAvatar(
                child:
                    Icon(
                  Icons.person,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Text(
                user?.displayName ??
                    'বন্ধু',
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 15,
          ),
          TextField(
            controller:
                _controller,
            maxLines: 6,
            maxLength: 5000,
            autofocus: true,
            decoration:
                InputDecoration(
              hintText:
                  'কী ভাবছেন?',
              filled: true,
              fillColor:
                  Colors.grey.shade100,
              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
                borderSide:
                    BorderSide.none,
              ),
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          SizedBox(
            width:
                double.infinity,
            height: 50,
            child:
                FilledButton(
              onPressed:
                  _loading
                      ? null
                      : _createPost,
              child:
                  _loading
                      ? const SizedBox(
                          width: 23,
                          height: 23,
                          child:
                              CircularProgressIndicator(
                            strokeWidth:
                                2,
                          ),
                        )
                      : const Text(
                          'Post করুন',
                          style:
                              TextStyle(
                            fontSize:
                                16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// POST CARD
// ==================================================================

class PostCard
    extends StatelessWidget {
  final DocumentSnapshot<
      Map<String, dynamic>> post;

  final DataService dataService;

  const PostCard({
    super.key,
    required this.post,
    required this.dataService,
  });

  Future<void> _deletePost(
    BuildContext context,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (_) =>
          AlertDialog(
        title:
            const Text(
          'Post মুছে ফেলবেন?',
        ),
        content:
            const Text(
          'এই Post স্থায়ীভাবে মুছে যাবে।',
        ),
        actions: [
          TextButton(
            onPressed:
                () => Navigator.pop(
              context,
              false,
            ),
            child:
                const Text(
              'না',
            ),
          ),
          FilledButton(
            onPressed:
                () => Navigator.pop(
              context,
              true,
            ),
            child:
                const Text(
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content:
              Text(
            'Post মুছে ফেলা হয়েছে।',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content:
              Text(
            error.toString(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final data =
        post.data() ?? {};

    final userId =
        data['userId']
                ?.toString() ??
            '';

    final userName =
        data['userName']
                ?.toString() ??
            'বন্ধু';

    final text =
        data['text']
                ?.toString() ??
            '';

    final imageUrl =
        data['imageUrl']
            ?.toString();

    final createdAt =
        data['createdAt']
            as Timestamp?;

    final likeCount =
        (data['likeCount']
                    as num?)
                ?.toInt() ??
            0;

    final commentCount =
        (data['commentCount']
                    as num?)
                ?.toInt() ??
            0;

    final shareCount =
        (data['shareCount']
                    as num?)
                ?.toInt() ??
            0;

    final currentUser =
        FirebaseAuth
            .instance
            .currentUser;

    final isOwner =
        currentUser != null &&
        currentUser.uid ==
            userId;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 8,
      ),
      color:
          Colors.white,
      padding:
          const EdgeInsets.all(
        14,
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                child:
                    Icon(
                  Icons.person,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      userName,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatDate(
                        createdAt,
                      ),
                      style:
                          TextStyle(
                        color: Colors
                            .grey
                            .shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isOwner)
                PopupMenuButton<
                    String>(
                  onSelected:
                      (value) {
                    if (value ==
                        'delete') {
                      _deletePost(
                        context,
                      );
                    }
                  },
                  itemBuilder:
                      (_) =>
                          const [
                    PopupMenuItem(
                      value:
                          'delete',
                      child:
                          Text(
                        'Delete',
                      ),
                    ),
                  ],
                ),
            ],
          ),

          if (text.isNotEmpty) ...[
            const SizedBox(
              height: 14,
            ),
            Text(
              text,
              style:
                  const TextStyle(
                fontSize: 16,
                height: 1.45,
              ),
            ),
          ],

          if (imageUrl != null &&
              imageUrl.isNotEmpty) ...[
            const SizedBox(
              height: 12,
            ),
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
              child:
                  Image.network(
                imageUrl,
                width:
                    double.infinity,
                fit:
                    BoxFit.cover,
                errorBuilder:
                    (
                  _,
                  __,
                  ___,
                ) =>
                        Container(
                  height: 180,
                  color: Colors
                      .grey
                      .shade200,
                  alignment:
                      Alignment.center,
                  child:
                      const Icon(
                    Icons
                        .broken_image_outlined,
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
                  color:
                      Colors.red,
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
                child:
                    _LikeButton(
                  postId:
                      post.id,
                  dataService:
                      dataService,
                ),
              ),
              Expanded(
                child:
                    TextButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context:
                          context,
                      isScrollControlled:
                          true,
                      showDragHandle:
                          true,
                      builder:
                          (_) =>
                              CommentsSheet(
                        postId:
                            post.id,
                        dataService:
                            dataService,
                      ),
                    );
                  },
                  icon:
                      const Icon(
                    Icons
                        .comment_outlined,
                  ),
                  label:
                      Text(
                    commentCount >
                            0
                        ? 'Comment $commentCount'
                        : 'Comment',
                  ),
                ),
              ),
              Expanded(
                child:
                    _ShareButton(
                  postId:
                      post.id,
                  dataService:
                      dataService,
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

    final date =
        timestamp.toDate();

    final difference =
        DateTime.now()
            .difference(date);

    if (difference
            .inMinutes <
        1) {
      return 'এইমাত্র';
    }

    if (difference
            .inMinutes <
        60) {
      return '${difference.inMinutes} মিনিট আগে';
    }

    if (difference.inHours <
        24) {
      return '${difference.inHours} ঘণ্টা আগে';
    }

    if (difference.inDays <
        7) {
      return '${difference.inDays} দিন আগে';
    }

    return '${date.day}/${date.month}/${date.year}';
  }
}

// ==================================================================
// LIKE BUTTON
// ==================================================================

class _LikeButton
    extends StatelessWidget {
  final String postId;
  final DataService dataService;

  const _LikeButton({
    required this.postId,
    required this.dataService,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return StreamBuilder<bool>(
      stream:
          dataService.likeStatusStream(
        postId,
      ),
      builder:
          (
        context,
        snapshot,
      ) {
        final liked =
            snapshot.data ??
                false;

        return TextButton.icon(
          onPressed:
              () async {
            try {
              await dataService
                  .likePost(
                postId,
              );
            } catch (error) {
              if (!context.mounted) {
                return;
              }

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(
                SnackBar(
                  content:
                      Text(
                    error.toString(),
                  ),
                ),
              );
            }
          },
          icon:
              Icon(
            liked
                ? Icons.favorite
                : Icons.favorite_border,
            color: liked
                ? Colors.red
                : null,
          ),
          label:
              Text(
            liked
                ? 'Liked'
                : 'Like',
            style:
                TextStyle(
              color: liked
                  ? Colors.red
                  : null,
              fontWeight:
                  liked
                      ? FontWeight.bold
                      : null,
            ),
          ),
        );
      },
    );
  }
}

// ==================================================================
// SHARE BUTTON
// ==================================================================

class _ShareButton
    extends StatelessWidget {
  final String postId;
  final DataService dataService;

  const _ShareButton({
    required this.postId,
    required this.dataService,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return StreamBuilder<bool>(
      stream:
          dataService.shareStatusStream(
        postId,
      ),
      builder:
          (
        context,
        snapshot,
      ) {
        final shared =
            snapshot.data ??
                false;

        return TextButton.icon(
          onPressed:
              () async {
            try {
              await dataService
                  .sharePost(
                postId,
              );

              if (!context.mounted) {
                return;
              }

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(
                SnackBar(
                  content:
                      Text(
                    shared
                        ? 'Share সরিয়ে দেওয়া হয়েছে।'
                        : 'Post Share হয়েছে।',
                  ),
                  duration:
                      const Duration(
                    seconds: 1,
                  ),
                ),
              );
            } catch (error) {
              if (!context.mounted) {
                return;
              }

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(
                SnackBar(
                  content:
                      Text(
                    error.toString(),
                  ),
                ),
              );
            }
          },
          icon:
              Icon(
            shared
                ? Icons.check_circle
                : Icons.share_outlined,
            color:
                shared
                    ? Colors.green
                    : null,
          ),
          label:
              Text(
            shared
                ? 'Shared'
                : 'Share',
            style:
                TextStyle(
              color:
                  shared
                      ? Colors.green
                      : null,
              fontWeight:
                  shared
                      ? FontWeight.bold
                      : null,
            ),
          ),
        );
      },
    );
  }
}

// ==================================================================
// COMMENTS SHEET
// ==================================================================

class CommentsSheet
    extends StatefulWidget {
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
  final _controller =
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

    if (text.isEmpty ||
        _sending) {
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      await widget.dataService
          .addComment(
        postId:
            widget.postId,
        text: text,
      );

      _controller.clear();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content:
              Text(
            error.toString(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return SafeArea(
      child:
          SizedBox(
        height:
            MediaQuery.of(
                  context,
                )
                    .size
                    .height *
                .75,
        child:
            Column(
          children: [
            const Padding(
              padding:
                  EdgeInsets.all(
                16,
              ),
              child:
                  Text(
                'Comments',
                style:
                    TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
            const Divider(
              height: 1,
            ),
            Expanded(
              child: StreamBuilder<
                  QuerySnapshot<
                      Map<String,
                          dynamic>>>(
                stream: widget
                    .dataService
                    .commentsStream(
                  widget.postId,
                ),
                builder:
                    (
                  context,
                  snapshot,
                ) {
                  if (snapshot
                          .connectionState ==
                      ConnectionState
                          .waiting) {
                    return const Center(
                      child:
                          CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child:
                          Text(
                        'Comment লোড করা যায়নি।\n'
                        '${snapshot.error}',
                        textAlign:
                            TextAlign.center,
                      ),
                    );
                  }

                  final comments =
                      snapshot.data?.docs ??
                          [];

                  if (comments
                      .isEmpty) {
                    return const Center(
                      child:
                          Text(
                        'এখনও কোনো Comment নেই।',
                      ),
                    );
                  }

                  return ListView.builder(
                    padding:
                        const EdgeInsets
                            .all(
                      12,
                    ),
                    itemCount:
                        comments.length,
                    itemBuilder:
                        (
                      context,
                      index,
                    ) {
                      final doc =
                          comments[
                              index];

                      final comment =
                          doc.data();

                      final currentUser =
                          FirebaseAuth
                              .instance
                              .currentUser;

                      final isMine =
                          currentUser !=
                              null &&
                          comment[
                                  'userId'] ==
                              currentUser.uid;

                      return Card(
                        margin:
                            const EdgeInsets
                                .only(
                          bottom: 8,
                        ),
                        child:
                            ListTile(
                          leading:
                              const CircleAvatar(
                            child:
                                Icon(
                              Icons.person,
                            ),
                          ),
                          title:
                              Text(
                            comment[
                                    'userName'] ??
                                'বন্ধু',
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          subtitle:
                              Text(
                            comment[
                                    'text'] ??
                                '',
                          ),
                          trailing:
                              isMine
                                  ? IconButton(
                                      onPressed:
                                          () async {
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
                                          if (!context
                                              .mounted) {
                                            return;
                                          }

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content:
                                                  Text(
                                                error.toString(),
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      icon:
                                          const Icon(
                                        Icons
                                            .delete_outline,
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
            Container(
              padding:
                  const EdgeInsets
                      .all(
                10,
              ),
              child:
                  Row(
                children: [
                  Expanded(
                    child:
                        TextField(
                      controller:
                          _controller,
                      textInputAction:
                          TextInputAction
                              .send,
                      onSubmitted:
                          (_) =>
                              _sendComment(),
                      decoration:
                          InputDecoration(
                        hintText:
                            'Comment লিখুন...',
                        filled:
                            true,
                        fillColor:
                            Colors.grey
                                .shade100,
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            24,
                          ),
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
                        _sending
                            ? null
                            : _sendComment,
                    icon:
                        _sending
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                ),
                              )
                            : const Icon(
                                Icons
                                    .send_rounded,
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

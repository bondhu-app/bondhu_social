import 'package:flutter/material.dart';

void main() {
  runApp(const BondhuApp());
}

class BondhuApp extends StatelessWidget {
  const BondhuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bondhu',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        scaffoldBackgroundColor: Colors.grey.shade100,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  final List<Map<String, dynamic>> posts = [
    {
      'name': 'Bondhu User',
      'text': 'Bondhu Social Media-তে সবাইকে স্বাগতম! ❤️',
      'likes': 12,
      'liked': false,
    },
    {
      'name': 'Mahim',
      'text': 'আজকের দিনটা সুন্দর হোক। 😊',
      'likes': 8,
      'liked': false,
    },
  ];

  void likePost(int index) {
    setState(() {
      posts[index]['liked'] = !posts[index]['liked'];
      posts[index]['likes'] += posts[index]['liked'] ? 1 : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'bondhu',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 26,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),

      body: selectedIndex == 0
          ? HomeFeed(posts: posts, onLike: likePost)
          : selectedIndex == 1
              ? const Center(
                  child: Text(
                    'বন্ধু খুঁজুন 🔎',
                    style: TextStyle(fontSize: 22),
                  ),
                )
              : const Center(
                  child: Text(
                    'আপনার প্রোফাইল 👤',
                    style: TextStyle(fontSize: 22),
                  ),
                ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              final controller = TextEditingController();

              return AlertDialog(
                title: const Text('নতুন পোস্ট'),
                content: TextField(
                  controller: controller,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'আপনি কী ভাবছেন?',
                    border: OutlineInputBorder(),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('বাতিল'),
                  ),
                  FilledButton(
                    onPressed: () {
                      if (controller.text.trim().isNotEmpty) {
                        setState(() {
                          posts.insert(0, {
                            'name': 'You',
                            'text': controller.text.trim(),
                            'likes': 0,
                            'liked': false,
                          });
                        });
                      }
                      Navigator.pop(context);
                    },
                    child: const Text('পোস্ট'),
                  ),
                ],
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'হোম',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'বন্ধু',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'প্রোফাইল',
          ),
        ],
      ),
    );
  }
}

class HomeFeed extends StatelessWidget {
  final List<Map<String, dynamic>> posts;
  final Function(int) onLike;

  const HomeFeed({
    super.key,
    required this.posts,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.green.shade100,
                  child: const Icon(
                    Icons.person,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'আপনি কী ভাবছেন?',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        ...List.generate(
          posts.length,
          (index) => PostCard(
            post: posts[index],
            onLike: () => onLike(index),
          ),
        ),
      ],
    );
  }
}

class PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback onLike;

  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    final bool liked = post['liked'] as bool;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                const SizedBox(width: 10),
                Text(
                  post['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Text(
              post['text'],
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                IconButton(
                  onPressed: onLike,
                  icon: Icon(
                    liked ? Icons.favorite : Icons.favorite_border,
                    color: liked ? Colors.red : null,
                  ),
                ),
                Text('${post['likes']}'),

                const SizedBox(width: 15),

                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.comment_outlined),
                ),
                const Text('মন্তব্য'),

                const Spacer(),

                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.share_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

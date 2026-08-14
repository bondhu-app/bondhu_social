import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(const BondhuApp());

class BondhuApp extends StatelessWidget {
  const BondhuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bondhu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

class Post {
  Post({required this.text, this.image, this.likes = 0});
  final String text;
  final File? image;
  int likes;
}

class AppState extends ChangeNotifier {
  final List<Post> posts = [
    Post(text: 'Bondhu-তে স্বাগতম! 🎉'),
  ];

  String userName = 'MD Mojidul';
  String email = 'user@example.com';
  File? profileImage;

  void addPost(String text, File? image) {
    if (text.trim().isEmpty && image == null) return;
    posts.insert(0, Post(text: text.trim(), image: image));
    notifyListeners();
  }

  void like(Post post) {
    post.likes++;
    notifyListeners();
  }

  void setProfile(File? file) {
    profileImage = file;
    notifyListeners();
  }
}

final appState = AppState();

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();

  void login() {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email ও Password দিন')),
      );
      return;
    }
    appState.email = email.text.trim();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.people_alt_rounded, size: 80, color: Colors.blue),
                const SizedBox(height: 12),
                const Text('Bondhu', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Connect with your friends'),
                const SizedBox(height: 32),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: login,
                    child: const Padding(
                      padding: EdgeInsets.all(13),
                      child: Text('Log In'),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Registration পরের ভার্সনে যোগ করা হবে')),
                  ),
                  child: const Text('Create new account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomePage(),
      const ProfilePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bondhu', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
        ],
      ),
      body: pages[index],
      floatingActionButton: index == 0
          ? FloatingActionButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => const CreatePostSheet(),
              ),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    appState.addListener(_refresh);
  }

  @override
  void dispose() {
    appState.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 90),
      children: [
        const StoryBar(),
        const Divider(height: 1),
        ...appState.posts.map((p) => PostCard(post: p)),
      ],
    );
  }
}

class StoryBar extends StatelessWidget {
  const StoryBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 105,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(10),
        children: const [
          _Story(icon: Icons.add, title: 'Your story'),
          _Story(icon: Icons.person, title: 'Rahim'),
          _Story(icon: Icons.person, title: 'Karim'),
          _Story(icon: Icons.person, title: 'Sadia'),
        ],
      ),
    );
  }
}

class _Story extends StatelessWidget {
  const _Story({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 75,
      margin: const EdgeInsets.only(right: 10),
      child: Column(
        children: [
          CircleAvatar(radius: 30, child: Icon(icon)),
          const SizedBox(height: 5),
          Text(title, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class PostCard extends StatefulWidget {
  const PostCard({super.key, required this.post});
  final Post post;
  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final comment = TextEditingController();
  bool liked = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(appState.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
              ],
            ),
            if (widget.post.text.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(widget.post.text, style: const TextStyle(fontSize: 16)),
            ],
            if (widget.post.image != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(widget.post.image!, width: double.infinity, fit: BoxFit.cover),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Text('${widget.post.likes} likes'),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() => liked = !liked);
                    if (liked) appState.like(widget.post);
                  },
                  icon: Icon(liked ? Icons.favorite : Icons.favorite_border),
                  label: const Text('Like'),
                ),
                TextButton.icon(
                  onPressed: () => _commentDialog(context),
                  icon: const Icon(Icons.comment_outlined),
                  label: const Text('Comment'),
                ),
                IconButton(onPressed: () {}, icon: const Icon(Icons.share_outlined)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _commentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Comment'),
        content: TextField(
          controller: comment,
          decoration: const InputDecoration(hintText: 'Write a comment...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (comment.text.trim().isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Comment added (local demo)')),
                );
              }
              comment.clear();
              Navigator.pop(context);
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }
}

class CreatePostSheet extends StatefulWidget {
  const CreatePostSheet({super.key});
  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final controller = TextEditingController();
  File? image;

  Future<void> pickImage() async {
    final result = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (result != null) setState(() => image = File(result.path));
  }

  void publish() {
    appState.addPost(controller.text, image);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Create Post', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: "What's on your mind?",
                border: OutlineInputBorder(),
              ),
            ),
            if (image != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(image!, height: 180, width: double.infinity, fit: BoxFit.cover),
              ),
            ],
            Row(
              children: [
                IconButton(onPressed: pickImage, icon: const Icon(Icons.photo, color: Colors.green)),
                const Text('Photo'),
                const Spacer(),
                FilledButton.icon(
                  onPressed: publish,
                  icon: const Icon(Icons.send),
                  label: const Text('Post'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<void> changePhoto() async {
    final result = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (result != null) {
      appState.setProfile(File(result.path));
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = appState.profileImage;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: GestureDetector(
            onTap: changePhoto,
            child: CircleAvatar(
              radius: 55,
              backgroundImage: photo != null ? FileImage(photo) : null,
              child: photo == null ? const Icon(Icons.person, size: 60) : null,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(child: Text(appState.userName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
        Center(child: Text(appState.email)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            _Stat(number: '0', label: 'Friends'),
            _Stat(number: '0', label: 'Followers'),
            _Stat(number: '0', label: 'Following'),
          ],
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: changePhoto,
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text('Change Profile Photo'),
        ),
        const SizedBox(height: 10),
        const ListTile(leading: Icon(Icons.info_outline), title: Text('About'), subtitle: Text('Your profile information')),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.number, required this.label});
  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(number, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label),
      ],
    );
  }
}

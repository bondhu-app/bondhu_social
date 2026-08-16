import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          backgroundColor: Colors.teal,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people), text: "Users"),
              Tab(icon: Icon(Icons.article), text: "Posts"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUserList(),
            _buildPostList(),
          ],
        ),
      ),
    );
  }

  // ১. ইউজার কন্ট্রোল লিস্ট
  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var users = snapshot.data!.docs;
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            var userData = users[index].data() as Map<String, dynamic>;
            String userId = users[index].id;
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(userData['name'] ?? 'No Name'),
              subtitle: Text(userData['email'] ?? 'No Email'),
              trailing: IconButton(
                icon: const Icon(Icons.block, color: Colors.red),
                onPressed: () {
                  // ইউজার ডিলিট/ব্লক লজিক
                  FirebaseFirestore.instance.collection('users').doc(userId).delete();
                },
              ),
            );
          },
        );
      },
    );
  }

  // ২. পোস্ট মডারেশন লিস্ট
  Widget _buildPostList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('posts').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var posts = snapshot.data!.docs;
        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            var postData = posts[index].data() as Map<String, dynamic>;
            String postId = posts[index].id;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                title: Text(postData['text'] ?? ''),
                subtitle: Text("Posted by: ${postData['userName'] ?? 'Unknown'}"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    // পোস্ট মুছে ফেলার লজিক
                    FirebaseFirestore.instance.collection('posts').doc(postId).delete();
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PostDetailsScreen extends StatelessWidget {
  final String postId;

  const PostDetailsScreen({
    super.key,
    required this.postId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
      ),
      body: StreamBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
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
              child: Text('Post পাওয়া যায়নি।'),
            );
          }

          final data =
              snapshot.data!.data() ?? {};

          final text =
              data['text']?.toString() ?? '';

          final userName =
              data['userName']?.toString() ??
                  'বন্ধু';

          final likes =
              data['likeCount'] ?? 0;

          final comments =
              data['commentCount'] ?? 0;

          final shares =
              data['shareCount'] ?? 0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      Text(
                        text.isEmpty
                            ? 'কোনো Text নেই'
                            : text,
                        style: const TextStyle(
                          fontSize: 17,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceAround,
                        children: [
                          Text('❤️ $likes'),
                          Text('💬 $comments'),
                          Text('↗ $shares'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('posts')
                        .doc(postId)
                        .delete();

                    if (!context.mounted) return;

                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.delete,
                  ),
                  label: const Text(
                    'Delete Post',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

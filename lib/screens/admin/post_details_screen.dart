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
        title: const Text(
          'Post Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
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

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Post লোড করা যায়নি.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Post পাওয়া যায়নি।',
              ),
            );
          }

          final data =
              snapshot.data!.data() ?? {};

          final userName =
              data['userName']?.toString() ??
                  'বন্ধু';

          final text =
              data['text']?.toString() ??
                  '';

          final imageUrl =
              data['imageUrl']?.toString();

          final likes =
              data['likeCount'] ?? 0;

          final comments =
              data['commentCount'] ?? 0;

          final shares =
              data['shareCount'] ?? 0;

          final userId =
              data['userId']?.toString() ??
                  '';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            child: Icon(
                              Icons.person,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              userName,
                              style:
                                  const TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Divider(
                        height: 30,
                      ),

                      if (text.isNotEmpty)
                        Text(
                          text,
                          style:
                              const TextStyle(
                            fontSize: 17,
                            height: 1.5,
                          ),
                        ),

                      if (imageUrl != null &&
                          imageUrl.isNotEmpty) ...[
                        const SizedBox(height: 15),
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                          child: Image.network(
                            imageUrl,
                            width:
                                double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (
                              context,
                              error,
                              stackTrace,
                            ) {
                              return Container(
                                height: 200,
                                color: Colors
                                    .grey
                                    .shade200,
                                alignment:
                                    Alignment.center,
                                child:
                                    const Icon(
                                  Icons
                                      .broken_image,
                                  size: 60,
                                ),
                              );
                            },
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceAround,
                        children: [
                          _count(
                            Icons.favorite,
                            'Likes',
                            likes,
                          ),
                          _count(
                            Icons.comment,
                            'Comments',
                            comments,
                          ),
                          _count(
                            Icons.share,
                            'Shares',
                            shares,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.person_search,
                  ),
                  title: const Text(
                    'Author User ID',
                  ),
                  subtitle: Text(
                    userId.isEmpty
                        ? 'নেই'
                        : userId,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              FilledButton.icon(
                onPressed: () {
                  _confirmDelete(
                    context,
                    postId,
                  );
                },
                icon: const Icon(
                  Icons.delete,
                ),
                label: const Text(
                  'Delete Post',
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _count(
    IconData icon,
    String title,
    dynamic value,
  ) {
    return Column(
      children: [
        Icon(icon),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  static Future<void> _confirmDelete(
    BuildContext context,
    String postId,
  ) async {
    final result =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Post?',
          ),
          content: const Text(
            'এই Post স্থায়ীভাবে Delete করবেন?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .delete();

    if (!context.mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Post Delete করা হয়েছে।',
        ),
      ),
    );
  }
}

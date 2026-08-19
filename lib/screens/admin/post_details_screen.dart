import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PostDetailsScreen extends StatelessWidget {
  final String postId;

  const PostDetailsScreen({
    super.key,
    required this.postId,
  });

  int _number(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  Future<void> _deletePost(
    BuildContext context,
  ) async {
    final confirm =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Post',
          ),
          content: const Text(
            'আপনি কি এই Post Delete করতে চান?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'না',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
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
            'Post Delete হয়েছে।',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Post Delete করা যায়নি: $error',
          ),
        ),
      );
    }
  }

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
        actions: [
          IconButton(
            onPressed: () {
              _deletePost(context);
            },
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.red,
            ),
          ),
        ],
      ),
      body: StreamBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .snapshots(),
        builder: (
          context,
          snapshot,
        ) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Post লোড করা যায়নি.\n\n${snapshot.error}',
                textAlign:
                    TextAlign.center,
              ),
            );
          }

          final document =
              snapshot.data;

          if (document == null ||
              !document.exists) {
            return const Center(
              child: Text(
                'Post পাওয়া যায়নি।',
              ),
            );
          }

          final data =
              document.data() ?? {};

          final userName =
              data['userName']?.toString() ??
                  'বন্ধু';

          final userId =
              data['userId']?.toString() ??
                  '';

          final text =
              data['text']?.toString() ??
                  '';

          final imageUrl =
              data['imageUrl']?.toString();

          final likes =
              _number(
            data['likeCount'],
          );

          final comments =
              _number(
            data['commentCount'],
          );

          final shares =
              _number(
            data['shareCount'],
          );

          return ListView(
            padding:
                const EdgeInsets.all(16),
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  userName,
                                  style:
                                      const TextStyle(
                                    fontSize: 17,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                if (userId.isNotEmpty)
                                  Text(
                                    'User ID: $userId',
                                    style:
                                        TextStyle(
                                      fontSize: 11,
                                      color:
                                          Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (text.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text(
                          text,
                          style:
                              const TextStyle(
                            fontSize: 17,
                            height: 1.5,
                          ),
                        ),
                      ],
                      if (imageUrl != null &&
                          imageUrl.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius:
                              BorderRadius
                                  .circular(12),
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
                                    .grey.shade200,
                                alignment:
                                    Alignment.center,
                                child:
                                    const Icon(
                                  Icons
                                      .broken_image,
                                  size: 50,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _count(
                              Icons
                                  .favorite_border,
                              'Likes',
                              likes,
                            ),
                          ),
                          Expanded(
                            child: _count(
                              Icons
                                  .comment_outlined,
                              'Comments',
                              comments,
                            ),
                          ),
                          Expanded(
                            child: _count(
                              Icons.share_outlined,
                              'Shares',
                              shares,
                            ),
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
                    Icons.info_outline,
                  ),
                  title: const Text(
                    'Post ID',
                  ),
                  subtitle: Text(
                    postId,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _deletePost(context);
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  label: const Text(
                    'Delete Post',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
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
    int value,
  ) {
    return Column(
      children: [
        Icon(icon),
        const SizedBox(height: 5),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 17,
            fontWeight:
                FontWeight.bold,
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
}

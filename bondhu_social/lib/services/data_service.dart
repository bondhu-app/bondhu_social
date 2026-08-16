import 'package:cloud_firestore/cloud_firestore.dart';

class DataService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // Create User
  Future<void> createUser({
    required String uid,
    required String name,
    required String email,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'bio': '',
      'photoUrl': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get User
  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(
    String uid,
  ) async {
    return await _firestore
        .collection('users')
        .doc(uid)
        .get();
  }

  // Create Post
  Future<DocumentReference<Map<String, dynamic>>> createPost({
    required String uid,
    required String text,
    String imageUrl = '',
  }) async {
    return await _firestore.collection('posts').add({
      'uid': uid,
      'text': text,
      'imageUrl': imageUrl,
      'likes': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get Posts
  Stream<QuerySnapshot<Map<String, dynamic>>> getPosts() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Like Post
  Future<void> likePost({
    required String postId,
    required String uid,
  }) async {
    await _firestore
        .collection('posts')
        .doc(postId)
        .update({
      'likes': FieldValue.arrayUnion([uid]),
    });
  }

  // Unlike Post
  Future<void> unlikePost({
    required String postId,
    required String uid,
  }) async {
    await _firestore
        .collection('posts')
        .doc(postId)
        .update({
      'likes': FieldValue.arrayRemove([uid]),
    });
  }

  // Delete Post
  Future<void> deletePost(String postId) async {
    await _firestore
        .collection('posts')
        .doc(postId)
        .delete();
  }
}

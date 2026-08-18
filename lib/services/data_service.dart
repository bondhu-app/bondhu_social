import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DataService {
  DataService._();

  static final DataService instance = DataService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('posts');

  User? get currentUser => _auth.currentUser;

  // ============================================================
  // USER PROFILE
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>> currentUserStream() {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('ব্যবহারকারী লগইন করেননি।');
    }

    return _users.doc(user.uid).snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(
    String userId,
  ) async {
    return _users.doc(userId).get();
  }

  Future<void> updateUserProfile({
    required String name,
    String? bio,
    String? phone,
    String? username,
    String? photoUrl,
    String? coverPhotoUrl,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('প্রথমে লগইন করুন।');
    }

    final data = <String, dynamic>{
      'name': name.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (bio != null) {
      data['bio'] = bio.trim();
    }

    if (phone != null) {
      data['phone'] = phone.trim();
    }

    if (username != null) {
      data['username'] = username.trim().toLowerCase();
    }

    if (photoUrl != null) {
      data['photoUrl'] = photoUrl;
    }

    if (coverPhotoUrl != null) {
      data['coverPhotoUrl'] = coverPhotoUrl;
    }

    await _users.doc(user.uid).set(
      data,
      SetOptions(merge: true),
    );
  }

  // ============================================================
  // POSTS
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> postsStream() {
    return _posts
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<DocumentReference<Map<String, dynamic>>> createPost({
    required String text,
    String? imageUrl,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Post করতে প্রথমে লগইন করুন।');
    }

    final userDoc = await _users.doc(user.uid).get();
    final userData = userDoc.data();

    final post = <String, dynamic>{
      'userId': user.uid,
      'userName':
          userData?['name'] ?? user.displayName ?? 'বন্ধু',
      'userPhotoUrl':
          userData?['photoUrl'] ?? user.photoURL,
      'text': text.trim(),
      'imageUrl': imageUrl,
      'likeCount': 0,
      'commentCount': 0,
      'shareCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    return _posts.add(post);
  }

  Future<void> updatePost({
    required String postId,
    required String text,
    String? imageUrl,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('প্রথমে লগইন করুন।');
    }

    final postRef = _posts.doc(postId);
    final post = await postRef.get();

    if (!post.exists) {
      throw Exception('Post পাওয়া যায়নি।');
    }

    final data = post.data();

    if (data?['userId'] != user.uid) {
      throw Exception('এই Post পরিবর্তন করার অনুমতি নেই।');
    }

    await postRef.update({
      'text': text.trim(),
      'imageUrl': imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePost(String postId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('প্রথমে লগইন করুন।');
    }

    final postRef = _posts.doc(postId);
    final post = await postRef.get();

    if (!post.exists) {
      throw Exception('Post পাওয়া যায়নি।');
    }

    if (post.data()?['userId'] != user.uid) {
      throw Exception('এই Post মুছে ফেলার অনুমতি নেই।');
    }

    await postRef.delete();
  }

  // ============================================================
  // LIKES
  // ============================================================

  Stream<bool> likeStatusStream(String postId) {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.value(false);
    }

    return _posts
        .doc(postId)
        .collection('likes')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Future<void> likePost(String postId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Like করতে লগইন করুন।');
    }

    final likeRef = _posts
        .doc(postId)
        .collection('likes')
        .doc(user.uid);

    final existing = await likeRef.get();

    if (existing.exists) {
      await likeRef.delete();
    } else {
      await likeRef.set({
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ============================================================
  // COMMENTS
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> commentsStream(
    String postId,
  ) {
    return _posts
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Future<void> addComment({
    required String postId,
    required String text,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Comment করতে লগইন করুন।');
    }

    final cleanText = text.trim();

    if (cleanText.isEmpty) {
      throw Exception('Comment খালি রাখা যাবে না।');
    }

    final userDoc = await _users.doc(user.uid).get();
    final userData = userDoc.data();

    await _posts.doc(postId).collection('comments').add({
      'userId': user.uid,
      'userName':
          userData?['name'] ?? user.displayName ?? 'বন্ধু',
      'userPhotoUrl':
          userData?['photoUrl'] ?? user.photoURL,
      'text': cleanText,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('প্রথমে লগইন করুন।');
    }

    final commentRef = _posts
        .doc(postId)
        .collection('comments')
        .doc(commentId);

    final comment = await commentRef.get();

    if (!comment.exists) {
      throw Exception('Comment পাওয়া যায়নি।');
    }

    if (comment.data()?['userId'] != user.uid) {
      throw Exception('এই Comment মুছে ফেলার অনুমতি নেই।');
    }

    await commentRef.delete();
  }

  // ============================================================
  // SHARES
  // ============================================================

  Stream<bool> shareStatusStream(String postId) {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.value(false);
    }

    return _posts
        .doc(postId)
        .collection('shares')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Future<void> sharePost(String postId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Share করতে লগইন করুন।');
    }

    final shareRef = _posts
        .doc(postId)
        .collection('shares')
        .doc(user.uid);

    final existing = await shareRef.get();

    if (existing.exists) {
      await shareRef.delete();
    } else {
      await shareRef.set({
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ============================================================
  // SEARCH USERS
  // ============================================================

  Future<QuerySnapshot<Map<String, dynamic>>> searchUsers(
    String text,
  ) async {
    final query = text.trim();

    if (query.isEmpty) {
      return _users.limit(20).get();
    }

    return _users
        .orderBy('name')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .limit(20)
        .get();
  }
}

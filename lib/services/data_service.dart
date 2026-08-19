import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DataService {
  DataService._();

  static final DataService instance = DataService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('posts');

  User? get currentUser => _auth.currentUser;

  // ============================================================
  // USER PROFILE
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      currentUserStream() {
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
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots();
  }

  Future<DocumentReference<Map<String, dynamic>>> createPost({
    required String text,
    String? imageUrl,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Post করতে প্রথমে লগইন করুন।',
      );
    }

    final userDoc = await _users.doc(user.uid).get();

    final userData = userDoc.data();

    final post = <String, dynamic>{
      'userId': user.uid,
      'userName':
          userData?['name'] ??
          user.displayName ??
          'বন্ধু',
      'userPhotoUrl':
          userData?['photoUrl'] ??
          user.photoURL,
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
      throw Exception(
        'এই Post পরিবর্তন করার অনুমতি নেই।',
      );
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
      throw Exception(
        'এই Post মুছে ফেলার অনুমতি নেই।',
      );
    }

    await postRef.delete();
  }

  // ============================================================
  // LIKE
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
        .map(
          (snapshot) => snapshot.exists,
        );
  }

  Future<void> likePost(String postId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Like করতে লগইন করুন।',
      );
    }

    final postRef = _posts.doc(postId);

    final likeRef = postRef
        .collection('likes')
        .doc(user.uid);

    await _firestore.runTransaction(
      (transaction) async {
        final postSnapshot =
            await transaction.get(postRef);

        if (!postSnapshot.exists) {
          throw Exception(
            'Post পাওয়া যায়নি।',
          );
        }

        final likeSnapshot =
            await transaction.get(likeRef);

        final postData =
            postSnapshot.data() ?? {};

        final currentCount =
            (postData['likeCount'] as num?)?.toInt() ?? 0;

        if (likeSnapshot.exists) {
          transaction.delete(likeRef);

          transaction.update(
            postRef,
            {
              'likeCount':
                  currentCount > 0
                      ? currentCount - 1
                      : 0,
              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
          );
        } else {
          transaction.set(
            likeRef,
            {
              'userId': user.uid,
              'createdAt':
                  FieldValue.serverTimestamp(),
            },
          );

          transaction.update(
            postRef,
            {
              'likeCount': currentCount + 1,
              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
          );
        }
      },
    );
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
        .orderBy(
          'createdAt',
          descending: false,
        )
        .snapshots();
  }

  Future<void> addComment({
    required String postId,
    required String text,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Comment করতে লগইন করুন।',
      );
    }

    final cleanText = text.trim();

    if (cleanText.isEmpty) {
      throw Exception(
        'Comment খালি রাখা যাবে না।',
      );
    }

    final userDoc = await _users.doc(user.uid).get();

    final userData = userDoc.data();

    final postRef = _posts.doc(postId);

    final commentRef =
        postRef.collection('comments').doc();

    await _firestore.runTransaction(
      (transaction) async {
        final postSnapshot =
            await transaction.get(postRef);

        if (!postSnapshot.exists) {
          throw Exception(
            'Post পাওয়া যায়নি।',
          );
        }

        final postData =
            postSnapshot.data() ?? {};

        final currentCount =
            (postData['commentCount'] as num?)
                ?.toInt() ??
            0;

        transaction.set(
          commentRef,
          {
            'userId': user.uid,
            'userName':
                userData?['name'] ??
                user.displayName ??
                'বন্ধু',
            'userPhotoUrl':
                userData?['photoUrl'] ??
                user.photoURL,
            'text': cleanText,
            'createdAt':
                FieldValue.serverTimestamp(),
          },
        );

        transaction.update(
          postRef,
          {
            'commentCount': currentCount + 1,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }

  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'প্রথমে লগইন করুন।',
      );
    }

    final postRef = _posts.doc(postId);

    final commentRef = postRef
        .collection('comments')
        .doc(commentId);

    await _firestore.runTransaction(
      (transaction) async {
        final commentSnapshot =
            await transaction.get(commentRef);

        if (!commentSnapshot.exists) {
          throw Exception(
            'Comment পাওয়া যায়নি।',
          );
        }

        final commentData =
            commentSnapshot.data() ?? {};

        if (commentData['userId'] != user.uid) {
          throw Exception(
            'এই Comment মুছে ফেলার অনুমতি নেই।',
          );
        }

        final postSnapshot =
            await transaction.get(postRef);

        final postData =
            postSnapshot.data() ?? {};

        final currentCount =
            (postData['commentCount'] as num?)
                ?.toInt() ??
            0;

        transaction.delete(commentRef);

        transaction.update(
          postRef,
          {
            'commentCount':
                currentCount > 0
                    ? currentCount - 1
                    : 0,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }

  // ============================================================
  // SHARE
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
        .map(
          (snapshot) => snapshot.exists,
        );
  }

  Future<bool> sharePost(String postId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Share করতে লগইন করুন।',
      );
    }

    final postRef = _posts.doc(postId);

    final shareRef = postRef
        .collection('shares')
        .doc(user.uid);

    final result =
        await _firestore.runTransaction<bool>(
      (transaction) async {
        final postSnapshot =
            await transaction.get(postRef);

        if (!postSnapshot.exists) {
          throw Exception(
            'Post পাওয়া যায়নি।',
          );
        }

        final shareSnapshot =
            await transaction.get(shareRef);

        final postData =
            postSnapshot.data() ?? {};

        final currentCount =
            (postData['shareCount'] as num?)
                ?.toInt() ??
            0;

        if (shareSnapshot.exists) {
          transaction.delete(shareRef);

          transaction.update(
            postRef,
            {
              'shareCount':
                  currentCount > 0
                      ? currentCount - 1
                      : 0,
              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
          );

          return false;
        } else {
          transaction.set(
            shareRef,
            {
              'userId': user.uid,
              'createdAt':
                  FieldValue.serverTimestamp(),
            },
          );

          transaction.update(
            postRef,
            {
              'shareCount': currentCount + 1,
              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
          );

          return true;
        }
      },
    );

    return result;
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

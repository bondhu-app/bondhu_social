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

  CollectionReference<Map<String, dynamic>> get _earningEvents =>
      _firestore.collection('earning_events');

  CollectionReference<Map<String, dynamic>> get _settings =>
      _firestore.collection('settings');

  User? get currentUser => _auth.currentUser;

  // ============================================================
  // EARNING SETTINGS
  // ============================================================

  // মোট earning-এর 20% Admin Revenue
  static const double adminRevenuePercent = 0.20;

  // User-এর gross earning rate
  static const double postGrossEarning = 1.00;
  static const double likeGrossEarning = 0.10;
  static const double commentGrossEarning = 0.20;
  static const double shareGrossEarning = 0.25;

  // ============================================================
  // MONEY HELPERS
  // ============================================================

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }

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
  // USER WALLET
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      currentUserWalletStream() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.empty();
    }

    return _users.doc(user.uid).snapshots();
  }

  Future<double> getCurrentUserWallet() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('প্রথমে লগইন করুন।');
    }

    final snapshot =
        await _users.doc(user.uid).get();

    final data =
        snapshot.data() ?? {};

    return _toDouble(data['wallet']);
  }

  // ============================================================
  // ADMIN OWNER WALLET
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      ownerWalletStream() {
    return _settings
        .doc('owner_wallet')
        .snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>>
      getOwnerWallet() async {
    return _settings
        .doc('owner_wallet')
        .get();
  }

  // ============================================================
  // ADD EARNING
  //
  // Example:
  // Gross earning = ৳1.00
  //
  // User gets 80% = ৳0.80
  // Admin gets 20% = ৳0.20
  //
  // একই Firestore transaction-এর মধ্যে হিসাব হবে।
  // ============================================================

  Future<void> _addEarning({
    required String action,
    required String referenceId,
    required double grossAmount,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('প্রথমে লগইন করুন।');
    }

    if (grossAmount <= 0) {
      return;
    }

    final eventId =
        '${user.uid}_${action}_$referenceId';

    final eventRef =
        _earningEvents.doc(eventId);

    final userRef =
        _users.doc(user.uid);

    final ownerRef =
        _settings.doc('owner_wallet');

    await _firestore.runTransaction(
      (transaction) async {
        // ------------------------------------------------------
        // READ
        // ------------------------------------------------------

        final eventSnapshot =
            await transaction.get(eventRef);

        final userSnapshot =
            await transaction.get(userRef);

        final ownerSnapshot =
            await transaction.get(ownerRef);

        // একই কাজের earning আগে দেওয়া হয়ে থাকলে
        // দ্বিতীয়বার টাকা দেবে না।
        if (eventSnapshot.exists) {
          return;
        }

        final userData =
            userSnapshot.data() ?? {};

        final ownerData =
            ownerSnapshot.data() ?? {};

        // ------------------------------------------------------
        // CALCULATION
        // ------------------------------------------------------

        final adminAmount =
            double.parse(
          (grossAmount *
                  adminRevenuePercent)
              .toStringAsFixed(2),
        );

        final userAmount =
            double.parse(
          (grossAmount -
                  adminAmount)
              .toStringAsFixed(2),
        );

        // ------------------------------------------------------
        // CURRENT USER VALUES
        // ------------------------------------------------------

        final currentWallet =
            _toDouble(
          userData['wallet'],
        );

        final currentTotalEarned =
            _toDouble(
          userData['totalEarned'],
        );

        // ------------------------------------------------------
        // CURRENT ADMIN VALUES
        // ------------------------------------------------------

        final currentOwnerBalance =
            _toDouble(
          ownerData['balance'],
        );

        final currentOwnerRevenue =
            _toDouble(
          ownerData['totalEarned'],
        );

        final currentAdminRevenue =
            _toDouble(
          ownerData['adminRevenue'],
        );

        // ------------------------------------------------------
        // USER UPDATE
        // ------------------------------------------------------

        transaction.set(
          userRef,
          {
            'wallet':
                currentWallet +
                    userAmount,
            'totalEarned':
                currentTotalEarned +
                    grossAmount,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        // ------------------------------------------------------
        // ADMIN OWNER WALLET UPDATE
        // ------------------------------------------------------

        transaction.set(
          ownerRef,
          {
            'balance':
                currentOwnerBalance +
                    adminAmount,
            'totalEarned':
                currentOwnerRevenue +
                    adminAmount,
            'adminRevenue':
                currentAdminRevenue +
                    adminAmount,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        // ------------------------------------------------------
        // EARNING EVENT
        // ------------------------------------------------------

        transaction.set(
          eventRef,
          {
            'userId': user.uid,
            'action': action,
            'referenceId': referenceId,
            'grossAmount': grossAmount,
            'userAmount': userAmount,
            'adminAmount': adminAmount,
            'adminPercent':
                adminRevenuePercent,
            'createdAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }

  // ============================================================
  // POST EARNING
  // ============================================================

  Future<void> rewardPostEarning(
    String postId,
  ) async {
    await _addEarning(
      action: 'post',
      referenceId: postId,
      grossAmount: postGrossEarning,
    );
  }

  // ============================================================
  // LIKE EARNING
  // ============================================================

  Future<void> rewardLikeEarning(
    String postId,
  ) async {
    await _addEarning(
      action: 'like',
      referenceId: postId,
      grossAmount: likeGrossEarning,
    );
  }

  // ============================================================
  // COMMENT EARNING
  // ============================================================

  Future<void> rewardCommentEarning(
    String commentId,
  ) async {
    await _addEarning(
      action: 'comment',
      referenceId: commentId,
      grossAmount: commentGrossEarning,
    );
  }

  // ============================================================
  // SHARE EARNING
  // ============================================================

  Future<void> rewardShareEarning(
    String postId,
  ) async {
    await _addEarning(
      action: 'share',
      referenceId: postId,
      grossAmount: shareGrossEarning,
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

    final userDoc =
        await _users.doc(user.uid).get();

    final userData =
        userDoc.data();

    final postRef =
        _posts.doc();

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
      'createdAt':
          FieldValue.serverTimestamp(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    };

    await postRef.set(post);

    // Post তৈরি হলে earning
    await rewardPostEarning(
      postRef.id,
    );

    return postRef;
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

    final postRef =
        _posts.doc(postId);

    final post =
        await postRef.get();

    if (!post.exists) {
      throw Exception('Post পাওয়া যায়নি।');
    }

    final data =
        post.data();

    if (data?['userId'] != user.uid) {
      throw Exception(
        'এই Post পরিবর্তন করার অনুমতি নেই।',
      );
    }

    await postRef.update({
      'text': text.trim(),
      'imageUrl': imageUrl,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePost(
    String postId,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'প্রথমে লগইন করুন।',
      );
    }

    final postRef =
        _posts.doc(postId);

    final post =
        await postRef.get();

    if (!post.exists) {
      throw Exception(
        'Post পাওয়া যায়নি।',
      );
    }

    if (post.data()?['userId'] !=
        user.uid) {
      throw Exception(
        'এই Post মুছে ফেলার অনুমতি নেই।',
      );
    }

    await postRef.delete();
  }

  // ============================================================
  // LIKE
  // ============================================================

  Stream<bool> likeStatusStream(
    String postId,
  ) {
    final user =
        _auth.currentUser;

    if (user == null) {
      return Stream.value(false);
    }

    return _posts
        .doc(postId)
        .collection('likes')
        .doc(user.uid)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.exists,
        );
  }

  Future<void> likePost(
    String postId,
  ) async {
    final user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Like করতে লগইন করুন।',
      );
    }

    final postRef =
        _posts.doc(postId);

    final likeRef =
        postRef
            .collection('likes')
            .doc(user.uid);

    bool addedLike = false;

    await _firestore.runTransaction(
      (transaction) async {
        final postSnapshot =
            await transaction.get(
          postRef,
        );

        if (!postSnapshot.exists) {
          throw Exception(
            'Post পাওয়া যায়নি।',
          );
        }

        final likeSnapshot =
            await transaction.get(
          likeRef,
        );

        final postData =
            postSnapshot.data() ?? {};

        final currentCount =
            (postData['likeCount']
                        as num?)
                    ?.toInt() ??
                0;

        if (likeSnapshot.exists) {
          transaction.delete(
            likeRef,
          );

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
              'likeCount':
                  currentCount + 1,
              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
          );

          addedLike = true;
        }
      },
    );

    // প্রথমবার Like করলে earning
    if (addedLike) {
      await rewardLikeEarning(
        postId,
      );
    }
  }

  // ============================================================
  // COMMENTS
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      commentsStream(
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
    final user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Comment করতে লগইন করুন।',
      );
    }

    final cleanText =
        text.trim();

    if (cleanText.isEmpty) {
      throw Exception(
        'Comment খালি রাখা যাবে না।',
      );
    }

    final userDoc =
        await _users.doc(user.uid).get();

    final userData =
        userDoc.data();

    final postRef =
        _posts.doc(postId);

    final commentRef =
        postRef
            .collection('comments')
            .doc();

    await _firestore.runTransaction(
      (transaction) async {
        final postSnapshot =
            await transaction.get(
          postRef,
        );

        if (!postSnapshot.exists) {
          throw Exception(
            'Post পাওয়া যায়নি।',
          );
        }

        final postData =
            postSnapshot.data() ?? {};

        final currentCount =
            (postData['commentCount']
                        as num?)
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
            'commentCount':
                currentCount + 1,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );

    // Comment earning
    await rewardCommentEarning(
      commentRef.id,
    );
  }

  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    final user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'প্রথমে লগইন করুন।',
      );
    }

    final postRef =
        _posts.doc(postId);

    final commentRef =
        postRef
            .collection('comments')
            .doc(commentId);

    await _firestore.runTransaction(
      (transaction) async {
        final commentSnapshot =
            await transaction.get(
          commentRef,
        );

        if (!commentSnapshot.exists) {
          throw Exception(
            'Comment পাওয়া যায়নি।',
          );
        }

        final commentData =
            commentSnapshot.data() ?? {};

        if (commentData['userId'] !=
            user.uid) {
          throw Exception(
            'এই Comment মুছে ফেলার অনুমতি নেই।',
          );
        }

        final postSnapshot =
            await transaction.get(
          postRef,
        );

        final postData =
            postSnapshot.data() ?? {};

        final currentCount =
            (postData['commentCount']
                        as num?)
                    ?.toInt() ??
                0;

        transaction.delete(
          commentRef,
        );

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

  Stream<bool> shareStatusStream(
    String postId,
  ) {
    final user =
        _auth.currentUser;

    if (user == null) {
      return Stream.value(false);
    }

    return _posts
        .doc(postId)
        .collection('shares')
        .doc(user.uid)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.exists,
        );
  }

  Future<bool> sharePost(
    String postId,
  ) async {
    final user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Share করতে লগইন করুন।',
      );
    }

    final postRef =
        _posts.doc(postId);

    final shareRef =
        postRef
            .collection('shares')
            .doc(user.uid);

    final result =
        await _firestore
            .runTransaction<bool>(
      (transaction) async {
        final postSnapshot =
            await transaction.get(
          postRef,
        );

        if (!postSnapshot.exists) {
          throw Exception(
            'Post পাওয়া যায়নি।',
          );
        }

        final shareSnapshot =
            await transaction.get(
          shareRef,
        );

        final postData =
            postSnapshot.data() ?? {};

        final currentCount =
            (postData['shareCount']
                        as num?)
                    ?.toInt() ??
                0;

        if (shareSnapshot.exists) {
          transaction.delete(
            shareRef,
          );

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
              'shareCount':
                  currentCount + 1,
              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
          );

          return true;
        }
      },
    );

    // Share করলে earning
    if (result) {
      await rewardShareEarning(
        postId,
      );
    }

    return result;
  }

  // ============================================================
  // SEARCH USERS
  // ============================================================

  Future<QuerySnapshot<Map<String, dynamic>>>
      searchUsers(
    String text,
  ) async {
    final query =
        text.trim();

    if (query.isEmpty) {
      return _users
          .limit(20)
          .get();
    }

    return _users
        .orderBy('name')
        .startAt([query])
        .endAt([
          '$query\uf8ff',
        ])
        .limit(20)
        .get();
  }
}

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DataService {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> postsStream() {
    return db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> createPost({
    required String uid,
    required String name,
    required String text,
    File? image,
  }) async {
    String? imageUrl;

    if (image != null) {
      final ref = storage
          .ref()
          .child('posts')
          .child(uid)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      await ref.putFile(image);
      imageUrl = await ref.getDownloadURL();
    }

    await db.collection('posts').add({
      'uid': uid,
      'name': name,
      'text': text.trim(),
      'imageUrl': imageUrl,
      'likes': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleLike({
    required String postId,
    required String uid,
    required List<dynamic> likes,
  }) async {
    final ref = db.collection('posts').doc(postId);
    final updated = List<String>.from(likes.map((e) => e.toString()));

    if (updated.contains(uid)) {
      updated.remove(uid);
    } else {
      updated.add(uid);
    }

    await ref.update({'likes': updated});
  }

  Future<void> saveProfile({
    required String uid,
    required String name,
    required String bio,
  }) async {
    await db.collection('users').doc(uid).set({
      'name': name.trim(),
      'bio': bio.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class DataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addData({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    await _firestore
        .collection(collection)
        .doc(documentId)
        .set(data);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getData({
    required String collection,
    required String documentId,
  }) async {
    return await _firestore
        .collection(collection)
        .doc(documentId)
        .get();
  }

  Future<void> updateData({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    await _firestore
        .collection(collection)
        .doc(documentId)
        .update(data);
  }

  Future<void> deleteData({
    required String collection,
    required String documentId,
  }) async {
    await _firestore
        .collection(collection)
        .doc(documentId)
        .delete();
  }
}

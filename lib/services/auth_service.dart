import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();

    if (cleanName.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-name',
        message: 'নাম লিখুন।',
      );
    }

    if (cleanEmail.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'ইমেইল লিখুন।',
      );
    }

    if (password.length < 6) {
      throw FirebaseAuthException(
        code: 'weak-password',
        message: 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে।',
      );
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-created',
        message: 'অ্যাকাউন্ট তৈরি করা যায়নি।',
      );
    }

    await user.updateDisplayName(cleanName);

    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': cleanName,
      'email': cleanEmail,
      'photoUrl': null,
      'coverPhotoUrl': null,
      'bio': '',
      'phone': '',
      'username': '',
      'followersCount': 0,
      'followingCount': 0,
      'friendsCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
    });

    return credential;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    if (cleanEmail.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'ইমেইল লিখুন।',
      );
    }

    if (password.isEmpty) {
      throw FirebaseAuthException(
        code: 'empty-password',
        message: 'পাসওয়ার্ড লিখুন।',
      );
    }

    final credential = await _auth.signInWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    final user = credential.user;

    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return credential;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();

    if (cleanEmail.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'ইমেইল লিখুন।',
      );
    }

    await _auth.sendPasswordResetEmail(email: cleanEmail);
  }

  Future<void> signOut() async {
    final user = _auth.currentUser;

    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await _auth.signOut();
  }

  Future<void> updateProfile({
    String? name,
    String? photoUrl,
    String? bio,
    String? phone,
    String? username,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'প্রথমে লগইন করুন।',
      );
    }

    final data = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) {
      final cleanName = name.trim();

      if (cleanName.isNotEmpty) {
        data['name'] = cleanName;
        await user.updateDisplayName(cleanName);
      }
    }

    if (photoUrl != null) {
      data['photoUrl'] = photoUrl;
    }

    if (bio != null) {
      data['bio'] = bio.trim();
    }

    if (phone != null) {
      data['phone'] = phone.trim();
    }

    if (username != null) {
      data['username'] = username.trim().toLowerCase();
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(data, SetOptions(merge: true));
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getCurrentUserData() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'ব্যবহারকারী লগইন করেননি।',
      );
    }

    return _firestore.collection('users').doc(user.uid).get();
  }

  String getAuthErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'সঠিক ইমেইল ঠিকানা দিন।';

        case 'user-not-found':
          return 'এই ইমেইল দিয়ে কোনো অ্যাকাউন্ট পাওয়া যায়নি।';

        case 'wrong-password':
        case 'invalid-credential':
          return 'ইমেইল অথবা পাসওয়ার্ড সঠিক নয়।';

        case 'email-already-in-use':
          return 'এই ইমেইল দিয়ে ইতিমধ্যে অ্যাকাউন্ট আছে।';

        case 'weak-password':
          return 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে।';

        case 'too-many-requests':
          return 'অনেকবার চেষ্টা করা হয়েছে। কিছুক্ষণ পরে আবার চেষ্টা করুন।';

        case 'network-request-failed':
          return 'ইন্টারনেট সংযোগ পরীক্ষা করুন।';

        case 'user-disabled':
          return 'এই অ্যাকাউন্টটি নিষ্ক্রিয় করা হয়েছে।';

        default:
          return error.message ?? 'একটি সমস্যা হয়েছে। আবার চেষ্টা করুন।';
      }
    }

    return 'একটি অপ্রত্যাশিত সমস্যা হয়েছে। আবার চেষ্টা করুন।';
  }
}

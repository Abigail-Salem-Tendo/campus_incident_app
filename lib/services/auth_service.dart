import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import 'auth_exception.dart';

/// All Firebase Authentication and user-profile logic lives here.
/// Screens never talk to Firebase directly; they go through a provider.
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  /// Emits on sign-in, sign-out and when the user is reloaded
  /// (for example after verifying their email).
  Stream<User?> get userChanges => _auth.userChanges();

  User? get currentUser => _auth.currentUser;

  /// Creates the account, saves the profile (always as a student),
  /// and sends the verification email.
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (!AppConstants.isAllowedEmail(email)) {
      throw const AuthException(
        'Use your ALU email (@alustudent.com or @alueducation.com).',
      );
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;

      await user.updateDisplayName(name.trim());

      final profile = UserModel(
        uid: user.uid,
        email: user.email ?? email.trim(),
        name: name.trim(),
        role: UserRole.student,
      );
      await _users.doc(user.uid).set(profile.toMap());

      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    } on FirebaseException {
      throw const AuthException('Could not save your profile. Try again.');
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    }
  }

  Future<void> logout() => _auth.signOut();

  Future<void> sendVerificationEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    }
  }

  /// Refreshes the user from Firebase and returns whether the email
  /// is now verified.
  Future<bool> reloadAndCheckVerified() async {
    try {
      await _auth.currentUser?.reload();
      return _auth.currentUser?.emailVerified ?? false;
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    }
  }

  /// Reads the profile document (including the role) for a user.
  /// Returns null if the document does not exist.
  Future<UserModel?> fetchProfile(String uid) async {
    try {
      final doc = await _users.doc(uid).get();
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      return UserModel.fromMap(doc.id, data);
    } on FirebaseException {
      throw const AuthException('Could not load your profile. Try again.');
    }
  }
}

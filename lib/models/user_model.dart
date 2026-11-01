import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { student, staff }

/// A user's profile, stored in Firestore at users/{uid}.
class UserModel {
  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.createdAt,
  });

  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final DateTime? createdAt;

  bool get isStaff => role == UserRole.staff;

  /// Builds a user from a Firestore document. The uid is the document id.
  /// Any unknown or missing role falls back to student (the safe default).
  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      role: map['role'] == 'staff' ? UserRole.staff : UserRole.student,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Used when creating the profile document at registration.
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role.name,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

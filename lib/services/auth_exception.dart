import 'package:firebase_auth/firebase_auth.dart';

/// A readable error that screens can show directly to the user.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  /// Turns Firebase error codes into friendly messages.
  factory AuthException.fromFirebase(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return const AuthException('An account with this email already exists.');
      case 'invalid-email':
        return const AuthException('Enter a valid email address.');
      case 'weak-password':
        return const AuthException('Password must be at least 6 characters.');
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return const AuthException('Incorrect email or password.');
      case 'user-disabled':
        return const AuthException('This account has been disabled.');
      case 'too-many-requests':
        return const AuthException('Too many attempts. Please try again later.');
      case 'network-request-failed':
        return const AuthException('No internet connection. Check your network.');
      default:
        return const AuthException('Something went wrong. Please try again.');
    }
  }

  @override
  String toString() => message;
}

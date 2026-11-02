import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_exception.dart';
import '../services/auth_service.dart';

/// Where the user is in the sign-in flow. The AuthGate (next step)
/// picks the screen to show from this value.
enum AuthStatus {
  loading, // checking the session or loading the profile
  unauthenticated, // signed out
  unverified, // signed in, email not verified yet
  authenticated, // signed in, verified, profile (and role) loaded
  profileError, // verified, but the profile could not be loaded
}

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? service}) : _service = service ?? AuthService() {
    _subscription = _service.userChanges.listen(_onUserChanged);
  }

  final AuthService _service;
  late final StreamSubscription<User?> _subscription;

  AuthStatus _status = AuthStatus.loading;
  UserModel? _profile;
  String? _errorMessage;
  bool _isBusy = false;

  // Used to ignore results from outdated profile loads.
  int _requestId = 0;

  AuthStatus get status => _status;
  UserModel? get profile => _profile;
  String? get errorMessage => _errorMessage;

  /// True while a register, login or similar action is running.
  bool get isBusy => _isBusy;

  bool get isStaff => _profile?.isStaff ?? false;
  String? get email => _service.currentUser?.email;

  /// Runs whenever Firebase reports a sign-in, sign-out or user reload.
  Future<void> _onUserChanged(User? user) async {
    final requestId = ++_requestId;

    if (user == null) {
      _profile = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    if (!user.emailVerified) {
      _profile = null;
      _status = AuthStatus.unverified;
      notifyListeners();
      return;
    }

    // Verified and the profile for this user is already loaded.
    if (_profile?.uid == user.uid) {
      _status = AuthStatus.authenticated;
      notifyListeners();
      return;
    }

    // Verified: load the profile to learn the user's role.
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final profile = await _service.fetchProfile(user.uid);
      if (requestId != _requestId) return;

      if (profile == null) {
        _profile = null;
        _status = AuthStatus.profileError;
        _errorMessage = 'Your profile could not be found.';
      } else {
        _profile = profile;
        _status = AuthStatus.authenticated;
      }
    } on AuthException catch (e) {
      if (requestId != _requestId) return;
      _profile = null;
      _status = AuthStatus.profileError;
      _errorMessage = e.message;
    }
    notifyListeners();
  }

  /// Runs an action with a loading flag and error handling.
  /// Returns true if it succeeded.
  Future<bool> _run(Future<void> Function() action) async {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _run(
      () => _service.register(name: name, email: email, password: password),
    );
  }

  Future<bool> login({required String email, required String password}) {
    return _run(() => _service.login(email: email, password: password));
  }

  Future<bool> logout() => _run(_service.logout);

  Future<bool> resendVerification() => _run(_service.sendVerificationEmail);

  /// Called by the "I've verified" button. Returns true if the email is
  /// now verified (the status then moves on automatically).
  Future<bool> checkVerified() async {
    var verified = false;
    final ok = await _run(() async {
      verified = await _service.reloadAndCheckVerified();
      if (verified) await _onUserChanged(_service.currentUser);
    });
    return ok && verified;
  }

  /// Tries again to load the profile after a profileError.
  Future<void> retryProfile() => _onUserChanged(_service.currentUser);

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
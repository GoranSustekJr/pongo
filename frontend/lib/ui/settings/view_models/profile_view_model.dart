import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../domain/models/auth/user_profile.dart';
import '../../../utils/result.dart';

/// The signed-in user's profile and account actions.
class ProfileViewModel extends ChangeNotifier {
  /// Creates a view model and loads the profile.
  ProfileViewModel({required this._auth}) {
    unawaited(load());
  }

  final AuthRepository _auth;
  UserProfile? _profile;

  /// The profile, or `null` until it loads or if loading failed.
  UserProfile? get profile => _profile;

  /// Loads the profile.
  Future<void> load() async {
    if (await _auth.fetchProfile() case Ok(:final value)) {
      _profile = value;
      notifyListeners();
    }
  }

  /// Deletes the account, which also signs out.
  Future<void> deleteAccount() => _auth.deleteAccount();

  /// Signs out.
  Future<void> signOut() => _auth.signOut();
}

import 'package:flutter/foundation.dart';

import '../../../domain/models/auth/user_profile.dart';
import '../../../utils/result.dart';

/// The sign in providers the app supports.
enum SignInProvider {
  /// Google on a phone.
  google,

  /// Apple on a phone.
  apple,

  /// Google in the browser on a computer.
  googleDesktop,
}

/// Source of truth for the signed in session.
abstract class AuthRepository extends ChangeNotifier {
  /// Whether a user is signed in.
  bool get isSignedIn;

  /// The token authorizing audio streams.
  String get streamToken;

  /// Emits when the server reports the account as disabled.
  Stream<void> get onAccountDisabled;

  /// Restores the saved session. Call once at startup.
  Future<void> load();

  /// Signs in with [provider]. Completes with `false` if the user cancelled.
  Future<Result<bool>> signIn(SignInProvider provider);

  /// Renews the access token, signing out if the session expired.
  ///
  /// Returns whether a new token was issued.
  Future<bool> refreshSession();

  /// Signs the user out on this device.
  Future<void> signOut();

  /// Deletes the account on the server and signs out.
  Future<Result<void>> deleteAccount();

  /// The account details of the signed in user.
  ///
  /// Signs out if the server no longer accepts the session.
  Future<Result<UserProfile>> fetchProfile();
}

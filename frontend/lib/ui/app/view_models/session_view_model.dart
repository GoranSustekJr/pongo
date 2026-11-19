import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../core/messages/app_message.dart';
import '../../core/messages/message_center.dart';

/// Tracks whether the user is signed in.
class SessionViewModel extends ChangeNotifier {
  /// Creates a view model for [_authRepository].
  SessionViewModel({required this._authRepository, required this._messages}) {
    _authRepository.addListener(notifyListeners);
    _disabled = _authRepository.onAccountDisabled.listen(
      (_) => _messages.show(const AccountDisabledMessage()),
    );
  }

  final AuthRepository _authRepository;
  final MessageCenter _messages;
  late final StreamSubscription<void> _disabled;

  /// Whether a user is signed in.
  bool get isSignedIn => _authRepository.isSignedIn;

  /// Signs in with [provider]; the app switches screens once it succeeds.
  Future<void> signIn(SignInProvider provider) async {
    await _authRepository.signIn(provider);
  }

  @override
  void dispose() {
    _authRepository.removeListener(notifyListeners);
    unawaited(_disabled.cancel());
    super.dispose();
  }
}

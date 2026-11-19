import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/view_models/app_settings_view_model.dart';
import '../../../app/view_models/session_view_model.dart';
import '../../../shell/widgets/phone/bottom_navigation_screen_phone.dart';
import 'sign_in_phone.dart';

/// Shows the app when signed in and the sign in screen otherwise.
class AuthRedirectPhone extends StatelessWidget {
  /// Creates the redirect.
  const AuthRedirectPhone({super.key});

  @override
  Widget build(BuildContext context) {
    final signedIn = context.select<SessionViewModel, bool>(
      (session) => session.isSignedIn,
    );
    return AnimatedSwitcher(
      duration: Duration(
        milliseconds: context.readSettings.useAnimations ? 500 : 0,
      ),
      switchInCurve: Curves.easeInOut,
      child: signedIn
          ? const BottomNavigationScreenPhone(key: ValueKey(true))
          : const SignInPhone(key: ValueKey(false)),
    );
  }
}

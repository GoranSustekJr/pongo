import 'package:pongo/exports.dart';
import 'package:pongo/phone/views/main/bottom_navigation_screen_phone.dart';

class AuthRedirectScreen extends StatelessWidget {
  const AuthRedirectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: isUserSignedIn,
        builder: (context, signedIn, child) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeInOut,
            child: signedIn
                ? const BottomNavigationScreenPhone(
                    key: ValueKey(true),
                  )
                : const SignInPhone(
                    key: ValueKey(false),
                  ),
          );
        });
  }
}

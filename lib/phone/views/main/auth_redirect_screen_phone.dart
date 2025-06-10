import 'package:pongo/exports.dart';
import 'package:pongo/phone/views/main/bottom_navigation_screen_phone.dart';

class AuthRedirectPhone extends StatelessWidget {
  const AuthRedirectPhone({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: isUserSignedIn,
        builder: (context, signedIn, child) {
          return AnimatedSwitcher(
            duration: Duration(milliseconds: animations ? 500 : 0),
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

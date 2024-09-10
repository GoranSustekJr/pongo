import '../../../exports.dart';

class SignInPhone extends StatefulWidget {
  const SignInPhone({super.key});

  @override
  State<SignInPhone> createState() => _SignInPhoneState();
}

class _SignInPhoneState extends State<SignInPhone> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        // decoration: Constants().backgroundBoxDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            razh(AppBar().preferredSize.height * 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context)!.signin,
                  style: TextStyle(
                    fontSize: kIsApple ? 30 : 40,
                    fontWeight: kIsApple ? FontWeight.w700 : FontWeight.w800,
                  ),
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context)!.klemen,
                  style: TextStyle(
                    fontSize: kIsApple ? 17 : 18,
                    fontWeight: kIsApple ? FontWeight.w400 : FontWeight.w500,
                  ),
                ),
              ],
            ),
            Expanded(
              child: Container(),
            ),
            signInButtonPhone(context, GoogleLogoPainter(),
                "${AppLocalizations.of(context)!.signinwith} Google", "Google"),
            Row(
              children: [
                const Expanded(
                  child: Divider(
                    indent: 10,
                    endIndent: 5,
                    thickness: 1.5,
                    //  color: Col.fadeIcon,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.or,
                  //      style: TextStyle(color: Col.fadeIcon),
                ),
                const Expanded(
                  child: Divider(
                    // color: Col.fadeIcon,
                    indent: 5,
                    endIndent: 10,
                    thickness: 1.5,
                  ),
                ),
              ],
            ),
            signInButtonPhone(context, GoogleLogoPainter(),
                "${AppLocalizations.of(context)!.signinwith} Apple", "Apple"),
            Expanded(
              child: Container(),
            ),
            Padding(
              padding: EdgeInsets.only(
                  left: 15,
                  right: 15,
                  bottom: MediaQuery.of(context).padding.bottom),
              child: Text(
                AppLocalizations.of(context)!.bysigninginyou,
                textAlign: TextAlign.left,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

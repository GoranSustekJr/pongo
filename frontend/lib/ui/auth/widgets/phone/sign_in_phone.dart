import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../utils/platform.dart';
import '../../../core/themes/colors.dart';
import '../../../core/ui/space.dart';
import 'google_logo.dart';
import 'sign_in_button_phone.dart';

class SignInPhone extends StatefulWidget {
  const SignInPhone({super.key});

  @override
  State<SignInPhone> createState() => _SignInPhoneState();
}

class _SignInPhoneState extends State<SignInPhone> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: context.colors.backgroundBoxDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            razh(AppBar().preferredSize.height * 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context).signin,
                  style: TextStyle(
                    fontSize: kIsApple ? 30 : 40,
                    fontWeight: kIsApple ? FontWeight.w700 : FontWeight.w800,
                    color: context.colors.text,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context).klemen,
                  style: TextStyle(
                    fontSize: kIsApple ? 17 : 18,
                    fontWeight: kIsApple ? FontWeight.w400 : FontWeight.w500,
                    color: context.colors.text,
                  ),
                ),
              ],
            ),
            Expanded(child: Container()),
            signInButtonPhone(
              context,
              GoogleLogoPainter(),
              '${AppLocalizations.of(context).signinwith} Google',
              'Google',
            ),
            Row(
              children: [
                Expanded(
                  child: Divider(
                    indent: 10,
                    endIndent: 5,
                    thickness: 1.5,
                    color: context.colors.text,
                  ),
                ),
                Text(
                  AppLocalizations.of(context).or,
                  style: TextStyle(color: context.colors.text),
                ),
                Expanded(
                  child: Divider(
                    color: context.colors.text,
                    indent: 5,
                    endIndent: 10,
                    thickness: 1.5,
                  ),
                ),
              ],
            ),
            signInButtonPhone(
              context,
              GoogleLogoPainter(),
              '${AppLocalizations.of(context).signinwith} Apple',
              'Apple',
            ),
            Expanded(child: Container()),
            Padding(
              padding: EdgeInsets.only(
                left: 15,
                right: 15,
                bottom: MediaQuery.of(context).padding.bottom,
              ),
              child: Text(
                AppLocalizations.of(context).bysigninginyou,
                textAlign: TextAlign.left,
                style: TextStyle(color: context.colors.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

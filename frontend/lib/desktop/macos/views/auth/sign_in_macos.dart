import 'package:pongo/exports.dart';

class SignInMacos extends StatefulWidget {
  const SignInMacos({super.key});

  @override
  State<SignInMacos> createState() => _SignInMacosState();
}

class _SignInMacosState extends State<SignInMacos> {
  @override
  Widget build(BuildContext context) {
    return MacosWindow(
      child: MacosScaffold(
        children: [
          ContentArea(
            builder: (context, scrollController) {
              Size size = MediaQuery.of(context).size;
              return Container(
                height: size.height,
                width: size.width,
                decoration: AppConstants().backgroundBoxDecoration,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    razh(AppBar().preferredSize.height),
                    Text(
                      AppLocalizations.of(context).signin,
                      style: TextStyle(
                        fontSize: kIsApple ? 30 : 40,
                        fontWeight:
                            kIsApple ? FontWeight.w700 : FontWeight.w800,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context).klemen,
                      style: TextStyle(
                        fontSize: kIsApple ? 17 : 18,
                        fontWeight:
                            kIsApple ? FontWeight.w500 : FontWeight.w600,
                      ),
                    ),
                    Expanded(
                      child: Container(),
                    ),
                    Material(
                      color: Col.transp,
                      child: signInButtonPhone(
                          context,
                          GoogleLogoPainter(),
                          "${AppLocalizations.of(context).signinwith} Google",
                          "Google"),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            indent: 10,
                            endIndent: 5,
                            thickness: 1.5,
                            color: Col.fadeIcon,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context).or,
                          style: TextStyle(color: Col.fadeIcon),
                        ),
                        Expanded(
                          child: Divider(
                            color: Col.fadeIcon,
                            indent: 5,
                            endIndent: 10,
                            thickness: 1.5,
                          ),
                        ),
                      ],
                    ),
                    Material(
                      color: Col.transp,
                      child: signInButtonPhone(
                          context,
                          GoogleLogoPainter(),
                          "${AppLocalizations.of(context).signinwith} Apple",
                          "Apple"),
                    ),
                    Expanded(
                      child: Container(),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 15,
                        right: 15,
                        bottom: 20,
                      ),
                      child: Text(
                        AppLocalizations.of(context).bysigninginyou,
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
    );
  }
}

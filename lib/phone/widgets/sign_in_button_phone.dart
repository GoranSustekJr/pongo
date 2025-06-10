import 'package:flutter/cupertino.dart';
import 'package:pongo/phone/widgets/special/liquid_glass_background.dart';

import '../../exports.dart';

signInButtonPhone(context, CustomPainter? painter, String txt, String who) {
  return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Col.text)),
        child: kIsApple
            ? LiquidGlass(
                blur: AppConstants().liquidGlassBlur,
                tint: kIsApple ? Colors.white : Col.transp,
                borderRadius: kIsApple
                    ? const BorderRadius.all(Radius.circular(15))
                    : BorderRadius.zero,
                child: CupertinoButton(
                  padding: const EdgeInsets.only(),
                  onPressed: () {
                    if (who == "Google") {
                      if (kIsMobile) {
                        OAuth2().mobileSignInGoogle(context);
                      } else {
                        OAuth2().computerSignInGoogle(context);
                      }
                    } else {
                      //SignInApple()
                      if (kIsIOS) {
                        OAuth2().mobileSignInApple(context);
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: 1000,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Col.primaryCard.withAlpha(150),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 45,
                          decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(15),
                                bottomLeft: Radius.circular(15),
                                topRight: Radius.circular(5),
                                bottomRight: Radius.circular(5),
                              )),
                          child: Center(
                            child: who == "Google"
                                ? CustomPaint(
                                    painter: painter,
                                    size: const Size.square(25),
                                  )
                                : const Icon(
                                    Icons.apple_outlined,
                                    size: 45,
                                    color: Colors.black,
                                  ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              txt,
                              style: TextStyle(color: Col.text),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () {
                  if (who == "Google") {
                    OAuth2().mobileSignInGoogle(context);
                  } else {
                    //SignInApple();
                    OAuth2().mobileSignInApple(context);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: 1000,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Col.primaryCard.withAlpha(150),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 45,
                        decoration: BoxDecoration(
                            color: Col.icon,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(15),
                              bottomLeft: Radius.circular(15),
                              topRight: Radius.circular(5),
                              bottomRight: Radius.circular(5),
                            )),
                        child: Center(
                          child: who == "Google"
                              ? CustomPaint(
                                  painter: painter,
                                  size: const Size.square(25),
                                )
                              : const Icon(
                                  Icons.apple_outlined,
                                  size: 45,
                                  color: Colors.black,
                                ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            txt,
                            style: TextStyle(color: Col.text),
                            //     style: Styles().signinButton,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ));
}

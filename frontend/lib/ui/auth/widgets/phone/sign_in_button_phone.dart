import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/auth/auth_repository.dart';
import '../../../../utils/platform.dart';
import '../../../app/view_models/session_view_model.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/dimens.dart';
import '../../../core/ui/phone/liquid_glass_background.dart';

Padding signInButtonPhone(
  BuildContext context,
  CustomPainter? painter,
  String txt,
  String who,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: context.colors.text),
      ),
      child: kIsApple
          ? GlassSurface(
              blur: Dimens.liquidGlassBlur,
              tint: kIsApple ? Colors.white : Col.transp,
              borderRadius: kIsApple
                  ? const BorderRadius.all(Radius.circular(15))
                  : BorderRadius.zero,
              child: CupertinoButton(
                padding: const EdgeInsets.only(),
                onPressed: () {
                  if (who == 'Google') {
                    if (kIsMobile) {
                      context.read<SessionViewModel>().signIn(
                        SignInProvider.google,
                      );
                    } else {
                      context.read<SessionViewModel>().signIn(
                        SignInProvider.googleDesktop,
                      );
                    }
                  } else {
                    //SignInApple()
                    if (kIsIOS) {
                      context.read<SessionViewModel>().signIn(
                        SignInProvider.apple,
                      );
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: 1000,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: context.colors.primaryCard.withAlpha(150),
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
                          ),
                        ),
                        child: Center(
                          child: who == 'Google'
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
                            style: TextStyle(color: context.colors.text),
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
                if (who == 'Google') {
                  context.read<SessionViewModel>().signIn(
                    SignInProvider.google,
                  );
                } else {
                  //SignInApple();
                  context.read<SessionViewModel>().signIn(SignInProvider.apple);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                width: 1000,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: context.colors.primaryCard.withAlpha(150),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 45,
                      decoration: BoxDecoration(
                        color: context.colors.icon,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(15),
                          bottomLeft: Radius.circular(15),
                          topRight: Radius.circular(5),
                          bottomRight: Radius.circular(5),
                        ),
                      ),
                      child: Center(
                        child: who == 'Google'
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
                          style: TextStyle(color: context.colors.text),
                          //     style: Styles().signinButton,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    ),
  );
}

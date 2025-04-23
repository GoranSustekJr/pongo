import 'package:pongo/exports.dart';
import 'package:flutter/cupertino.dart';

class Trailing extends StatelessWidget {
  final bool show;
  final bool showThis;
  final bool forceWhite;
  final Widget trailing;

  const Trailing(
      {super.key,
      required this.show,
      required this.showThis,
      required this.trailing,
      required this.forceWhite});

  @override
  Widget build(BuildContext context) {
    return show
        ? AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: showThis
                ? SizedBox(
                    width: 20,
                    height: 40,
                    child: Center(
                      child: Icon(
                        CupertinoIcons.circle_filled,
                        color: forceWhite ? Colors.white : Col.icon,
                      ),
                    ))
                : const SizedBox(),
          )
        : trailing;
  }
}

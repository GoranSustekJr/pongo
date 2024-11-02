import 'package:pongo/exports.dart';
import 'package:flutter/cupertino.dart';

class Trailing extends StatelessWidget {
  final bool show;
  final bool showThis;
  final Widget trailing;
  const Trailing(
      {super.key,
      required this.show,
      required this.showThis,
      required this.trailing});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: show
          ? AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: showThis
                  ? const SizedBox(
                      width: 20,
                      height: 40,
                      child: Center(
                        child: Icon(
                          CupertinoIcons.circle_filled,
                          color: Colors.white,
                        ),
                      ))
                  : const SizedBox(),
            )
          : trailing,
    );
  }
}

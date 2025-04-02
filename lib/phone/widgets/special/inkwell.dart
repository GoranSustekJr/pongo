import 'package:pongo/exports.dart';

Widget inkWell(
  Widget child,
  Function() function,
) {
  return Material(
    color: Col.transp,
    child: InkWell(
      highlightColor: Colors.white.withAlpha(50),
      splashColor: Colors.white.withAlpha(75),
      onTap: function,
      child: child,
    ),
  );
}

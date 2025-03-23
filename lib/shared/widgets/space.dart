import 'package:pongo/exports.dart';

Widget razh(double x) {
  return SizedBox(
    height: x,
  );
}

razw(double x) {
  return SizedBox(
    width: x,
  );
}

divider(double x) {
  return Container(
    width: x,
    height: 1,
    color: Col.onIcon,
  );
}

dividerVertical(double y, double x, double padding) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: padding),
    child: Container(
      width: x,
      height: y,
      color: Colors.white,
    ),
  );
}

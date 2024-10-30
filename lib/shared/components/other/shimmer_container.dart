import '../../../exports.dart';

Widget shimmContainer(double width, double height, double radius) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: Col.onIcon,
      ),
    ),
  );
}

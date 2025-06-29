import 'package:pongo/exports.dart';

searchResultText(String txt, TextStyle style) {
  return Padding(
    padding: const EdgeInsets.only(left: 20, right: 20),
    child: Row(
      children: [
        Text(
          txt,
          style: style,
        )
      ],
    ),
  );
}

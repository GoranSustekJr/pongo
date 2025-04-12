import 'package:pongo/exports.dart';

settingsText(String text) {
  return Row(
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 20, bottom: 5),
        child: Text(
          text,
          style: TextStyle(color: Col.text.withAlpha(150)),
        ),
      ),
    ],
  );
}

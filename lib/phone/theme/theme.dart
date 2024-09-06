import 'package:pongo/exports.dart';

class AppTheme {
  final dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.transparent,
    colorScheme: const ColorScheme.dark(), // Set brightness to dark
    useMaterial3: true,
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        textStyle: MaterialStateProperty.all(
          const TextStyle(color: Colors.white),
        ),
      ),
    ),
    textTheme: const TextTheme().apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    primarySwatch: Colors.blue,
    primaryColor: Col.primary,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      surfaceTintColor: Col.transp,
      centerTitle: true,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    splashColor: Col.fadeIcon.withAlpha(0),
    highlightColor: Col.fadeIcon.withAlpha(0),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: Col.onIcon),
  );
}

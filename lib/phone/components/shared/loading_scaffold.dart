import 'package:pongo/exports.dart';

loadingScaffold(context, ValueKey key) {
  return Scaffold(
    key: key,
    backgroundColor: Colors.black,
    appBar: AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          backButton(context),
          Expanded(
            child: Container(),
          ),
        ],
      ),
    ),
    /* body: Center(
      child: textButton("Sign Out", () {
        SignInHandler().signOut(context);
        Navigator.of(context).pop();
      }, TextStyle(color: Colors.white, fontSize: 18)),
    ), */
  );
}

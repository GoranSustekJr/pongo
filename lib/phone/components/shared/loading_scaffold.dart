import 'package:pongo/exports.dart';

loadingScaffold(context, ValueKey key) {
  Size size = MediaQuery.of(context).size;
  return SizedBox(
    width: kIsDesktop ? 800 : size.width,
    height: kIsDesktop ? 500 : size.height,
    child: ClipRRect(
      borderRadius: kIsDesktop ? BorderRadius.circular(15) : BorderRadius.zero,
      child: Scaffold(
        key: key,
        backgroundColor: Colors.black,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.black,
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
      ),
    ),
  );
}

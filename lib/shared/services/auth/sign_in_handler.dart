import 'package:pongo/exports.dart';

class SignInHandler {
  updateSystemWide(bool signedIn) async {
    await Storage().writeSignedIn(signedIn);
    isUserSignedIn.value = signedIn;
  }

  signOut(context) async {
    print("system wide signin");
    updateSystemWide(false);
    print("Sistem wide access token");
    AccessTokenhandler().updateSystemWide(context, null);

    RefreshTokenhandler().updateSystemWide(context, null);
  }
}

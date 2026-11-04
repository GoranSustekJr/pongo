import 'package:pongo/exports.dart';

class SignInHandler {
  updateSystemWide(bool signedIn) async {
    await Storage().writeSignedIn(signedIn);
    isUserSignedIn.value = signedIn;
  }

  signOut(context) async {
    updateSystemWide(false);

    AccessTokenhandler().updateSystemWide(context, null);

    RefreshTokenhandler().updateSystemWide(context, null);
  }
}

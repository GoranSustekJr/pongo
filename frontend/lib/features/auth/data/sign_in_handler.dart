import 'package:pongo/core/state/globals.dart';
import 'package:pongo/core/storage/secure_storage.dart';
import 'package:pongo/features/auth/data/access_token_handler.dart';
import 'package:pongo/features/auth/data/refresh_token_handler.dart';

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

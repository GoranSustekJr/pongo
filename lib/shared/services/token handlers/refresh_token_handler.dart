import 'package:pongo/exports.dart';

class RefreshTokenhandler {
  updateSystemWide(context, refreshToken) async {
    await Storage().writeRefreshToken(refreshToken);
  }
}

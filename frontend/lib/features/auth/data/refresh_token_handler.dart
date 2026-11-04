import 'package:pongo/exports.dart';

class RefreshTokenhandler {
  Future<void> updateSystemWide(context, refreshToken) async {
    await Storage().writeRefreshToken(refreshToken);
  }
}

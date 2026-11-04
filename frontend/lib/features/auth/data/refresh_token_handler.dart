import 'package:pongo/core/storage/secure_storage.dart';

class RefreshTokenhandler {
  Future<void> updateSystemWide(context, refreshToken) async {
    await Storage().writeRefreshToken(refreshToken);
  }
}

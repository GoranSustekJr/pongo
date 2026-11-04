import 'package:pongo/core/storage/secure_storage.dart';

class RefreshTokenHandler {
  Future<void> updateSystemWide(context, refreshToken) async {
    await Storage().writeRefreshToken(refreshToken);
  }
}

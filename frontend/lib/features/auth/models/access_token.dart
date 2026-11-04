import 'package:pongo/exports.dart';

class AccessToken {
  String? _accessToken;

  String? get accessToken => _accessToken;

  Future<void> initializeAccessToken() async {
    _accessToken = await Storage().getAccessToken();
  }

  Future<void> setAccessToken(String? accessToken) async {
    await Storage().writeAccessToken(accessToken);
    _accessToken = accessToken;
  }
}

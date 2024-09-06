import 'package:pongo/exports.dart';

class AccessToken {
  String? _accessToken;

  String? get accessToken => _accessToken;

  Future<void> initializeAccessToken() async {
    _accessToken = await Storage().getAccessToken();
  }

  Future<void> setAccessToken(String? accessToken) async {
    print(2.1);

    await Storage().writeAccessToken(accessToken);
    print(2.2);
    _accessToken = accessToken;
  }
}

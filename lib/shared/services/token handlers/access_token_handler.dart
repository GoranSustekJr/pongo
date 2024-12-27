import 'package:http/http.dart' as http;
import 'package:pongo/exports.dart';

class AccessTokenhandler {
  updateSystemWide(context, accessToken) async {
    await Storage().writeAccessToken(accessToken);
    final accessTokenProvided =
        Provider.of<AccessToken>(context, listen: false);
    await accessTokenProvided.setAccessToken(accessToken);
  }

  renew(context) async {
    final refreshToken = await Storage().getRefreshToken();
    print(refreshToken);
    final response =
        await http.post(Uri.parse("${AppConstants.SERVER_URL}renew_at"),
            body: jsonEncode({
              "jwt": refreshToken,
            }));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await updateSystemWide(context, data["at"]);
    } else if (response.statusCode == 401) {
      SignInHandler().signOut(context);
      //TODO: Bas refresh token!
    }
  }
}

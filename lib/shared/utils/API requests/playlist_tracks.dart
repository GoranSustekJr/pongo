import 'package:pongo/exports.dart';
import 'package:http/http.dart' as http;

class PlaylistSpotify {
  // REMOVED     REMOVED

  // Initialize the API

  Future<Map> get(context, String spid) async {
    int tries = 0;

    try {
      while (tries < 2) {
        tries++;
        final accessTokenHandler =
            Provider.of<AccessToken>(context, listen: false);

        print(accessTokenHandler.accessToken);
        final response = await http.post(
          Uri.parse("${AppConstants.SERVER_URL}get_playlist"),
          body: jsonEncode(
            {
              "at+JWT": accessTokenHandler.accessToken,
              "spid": spid,
            },
          ),
        );

        if (response.statusCode == 200) {
          Map<String, dynamic> data = jsonDecode(response.body);

          return data;
        } else if (response.statusCode == 401) {
          if (tries < 2) {
            await AccessTokenhandler().renew(context);
          } else {
            break; // Exit the loop after the second attempt
          }
        } else {
          return {}; // Handle other status codes as needed
        }
      }
    } catch (e) {
      print(e);

      return {};
    }
    return {};
  }
}

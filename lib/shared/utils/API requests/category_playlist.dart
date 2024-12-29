/* import 'package:pongo/exports.dart';
import 'package:http/http.dart' as http;

class CategoryPlaylist {
  // REMOVED     REMOVED

  Future<Map> get(context, String categoryId) async {
    int tries = 0;

    try {
      while (tries < 2) {
        tries++;
        final accessTokenHandler =
            Provider.of<AccessToken>(context, listen: false);

        final response = await http.post(
          Uri.parse("${AppConstants.SERVER_URL}search_category"),
          body: jsonEncode(
            {
              "at+JWT": accessTokenHandler.accessToken,
              "category_id": categoryId,
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
 */
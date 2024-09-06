import 'package:http/http.dart' as http;
import 'package:pongo/exports.dart';

class UserData {
  Future<Map?> get(context) async {
    int tries = 0;

    while (tries < 2) {
      tries++;
      final accessTokenHandler =
          Provider.of<AccessToken>(context, listen: false);
      print(accessTokenHandler.accessToken);
      final response = await http.post(
        Uri.parse("${AppConstants.SERVER_URL}user_data"),
        body: jsonEncode(
          {"jwt": accessTokenHandler.accessToken},
        ),
      );

      if (response.statusCode == 200) {
        Map data = jsonDecode(response.body);
        return data;
      } else if (response.statusCode == 401) {
        if (tries < 2) {
          await AccessTokenhandler().renew(context);
        } else {
          break; // Exit the loop after the second attempt
        }
      } else {
        print("HEEEE");
        SignInHandler().signOut(context);
        return null; // Handle other status codes as needed
      }
    }
    print("HEEEE33333");
    SignInHandler().signOut(context);
    return null; // Return null if it fails after the retry
  }
}

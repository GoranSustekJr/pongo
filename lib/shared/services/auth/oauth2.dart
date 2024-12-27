import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:pongo/exports.dart';

class OAuth2 {
  //TODO: Make all API client IDs ( oauth2 and spotify ) gotten from server so rate limit is not exceeded

  final String oauth2APIClientID = kIsApple
      ? "REMOVED"
      : "REMOVED";
  //final String oauth2APISecret = "REMOVED";

  mobileSignIn(context) async {
    // Create mobile sign in session
    final GoogleSignIn googleSignInMobile = GoogleSignIn(
      scopes: ['email', 'profile', 'openid'],
      clientId: oauth2APIClientID,
    );

    // Sign in to an account
    final GoogleSignInAccount? googleSignInAccount =
        await googleSignInMobile.signOut().then((_) async {
      final l = await googleSignInMobile.signIn();
      return l;
    });

    // If account not null, authorize the user
    if (googleSignInAccount != null) {
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;

      String? idToken = googleSignInAuthentication.idToken;
      print("token: ");
      print(idToken);
      if (idToken != null) {
        DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

        String? deviceId;
        if (kIsIOS) {
          IosDeviceInfo iosDeviceInfo = await deviceInfo.iosInfo;
          deviceId = iosDeviceInfo.identifierForVendor;
        } else if (kIsAndroid) {
          AndroidDeviceInfo androidDeviceInfo = await deviceInfo.androidInfo;
          deviceId = androidDeviceInfo.id;
        } // TODO: Other platforms

        // Send it to my server
        print("great");
        final response = await http.post(
          Uri.parse(
              "${AppConstants.SERVER_URL}bed1684d6d16802154bba513a5f0980dd3dc4b612aeb6a05433c28f55936ca7d"),
          body: jsonEncode({
            "id_token": idToken,
            "platform": kIsApple ? "ios" : kPlatform,
            "device_id": deviceId,
          }),
        );
        print(response.statusCode);
        if (response.statusCode == 200) {
          print("NICE");
          final data = jsonDecode(response.body);
          final accessToken = data["at+JWT"];
          final refreshToken = data["rt+JWT"];
          if (accessToken != null && refreshToken != null) {
            SignInHandler().updateSystemWide(true);

            AccessTokenhandler().updateSystemWide(context, accessToken);

            RefreshTokenhandler().updateSystemWide(context, refreshToken);
          } else if (response.statusCode == 401) {
            print("SHIIIIT");
            AccessTokenhandler().renew(context);
            // TODO: Auth failed
          }
        }
      }
    }
  }
}

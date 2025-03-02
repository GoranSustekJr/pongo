import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:pongo/exports.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class OAuth2 {
  final String oauth2APIClientID = kIsApple
      ? "REMOVED"
      : "REMOVED";
  //final String oauth2APISecret = "REMOVED";

  mobileSignInGoogle(context) async {
    // Create mobile sign in session
    final GoogleSignIn googleSignInMobile = GoogleSignIn(
      scopes: ['email', 'profile', 'openid'],
      clientId: kIsApple ? oauth2APIClientID : null,
      serverClientId: !kIsApple ? oauth2APIClientID : null,
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
        final response = await http.post(
          Uri.parse(
              "${AppConstants.SERVER_URL}bed1684d6d16802154bba513a5f0980dd3dc4b612aeb6a05433c28f55936ca7d"),
          body: jsonEncode({
            "apple": false,
            "id_token": idToken,
            "platform": kIsApple ? "ios" : kPlatform,
            "device_id": deviceId,
          }),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final accessToken = data["at+JWT"];
          final refreshToken = data["rt+JWT"];
          if (accessToken != null && refreshToken != null) {
            SignInHandler().updateSystemWide(true);

            AccessTokenhandler().updateSystemWide(context, accessToken);

            RefreshTokenhandler().updateSystemWide(context, refreshToken);

            bool premim = (await Premium().isPremium(mainContext.value,
                accessToken: accessToken))["premium"];
            premium.value = premim;
          } else if (response.statusCode == 401) {
            // Auth failed
            AccessTokenhandler().renew(context);
          }
        }
      }
    }
  }

  mobileSignInApple(context) async {
    // Get the code
    AuthorizationCredentialAppleID credential =
        await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    // Device id
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    String? deviceId;
    if (kIsIOS) {
      IosDeviceInfo iosDeviceInfo = await deviceInfo.iosInfo;
      deviceId = iosDeviceInfo.identifierForVendor;
    } else if (kIsAndroid) {
      AndroidDeviceInfo androidDeviceInfo = await deviceInfo.androidInfo;
      deviceId = androidDeviceInfo.id;
    } // TODO: Other platforms

    // Send to server
    final response = await http.post(
      Uri.parse(
          "${AppConstants.SERVER_URL}bed1684d6d16802154bba513a5f0980dd3dc4b612aeb6a05433c28f55936ca7d"),
      body: jsonEncode({
        "apple": true,
        "id_token": credential.authorizationCode,
        "platform": kIsApple ? "ios" : kPlatform,
        "device_id": deviceId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final accessToken = data["at+JWT"];
      final refreshToken = data["rt+JWT"];
      if (accessToken != null && refreshToken != null) {
        SignInHandler().updateSystemWide(true);

        await AccessTokenhandler().updateSystemWide(context, accessToken);

        await RefreshTokenhandler().updateSystemWide(context, refreshToken);

        bool premim = (await Premium()
            .isPremium(context, accessToken: accessToken))["premium"];
        premium.value = premim;
      } else if (response.statusCode == 401) {
        // Auth failed
        AccessTokenhandler().renew(context);
      }
    }
  }
}

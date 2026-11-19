import 'package:device_info_plus/device_info_plus.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/app_config.dart';
import '../../../utils/platform.dart';

/// Proof of identity from a sign in provider, sent to the Pongo API.
typedef IdentityCredential = ({
  String idToken,
  bool apple,
  String platform,
  String? deviceId,
});

/// Signs the user in with Google or Apple and identifies the device.
class IdentityService {
  /// Creates a service using the OAuth clients in [_config].
  IdentityService({required this._config});

  final AppConfig _config;

  // GoogleSignIn may only be initialized once per app run.
  Future<void>? _googleInitialized;

  /// Signs in with Google on a phone, or returns `null` if the user cancels.
  Future<IdentityCredential?> signInWithGoogle() async {
    final clientId = kIsApple ? _config.appleClientId : _config.androidClientId;
    _googleInitialized ??= GoogleSignIn.instance.initialize(
      clientId: kIsApple ? clientId : null,
      serverClientId: kIsApple ? null : clientId,
    );
    await _googleInitialized;
    await GoogleSignIn.instance.signOut();

    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate(
        scopeHint: ['email', 'profile', 'openid'],
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) return null;
    return (
      idToken: idToken,
      apple: false,
      platform: kIsApple ? 'ios' : kPlatform,
      deviceId: await _phoneDeviceId(),
    );
  }

  /// Signs in with Apple on a phone.
  Future<IdentityCredential> signInWithApple() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    return (
      idToken: credential.authorizationCode,
      apple: true,
      platform: kIsApple ? 'ios' : kPlatform,
      deviceId: await _phoneDeviceId(),
    );
  }

  /// Signs in with Google in the browser on a computer, or returns `null` if
  /// no ID token was granted.
  Future<IdentityCredential?> signInWithGoogleOnDesktop() async {
    final client = await clientViaUserConsent(
      ClientId(_config.desktopClientId, _config.desktopClientSecret),
      ['email', 'profile'],
      (url) => launchUrl(Uri.parse(url)),
    );
    final idToken = client.credentials.idToken;
    if (idToken == null) return null;
    return (
      idToken: idToken,
      apple: false,
      platform: 'web',
      deviceId: await _desktopDeviceId(),
    );
  }

  Future<String?> _phoneDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (kIsIOS) return (await deviceInfo.iosInfo).identifierForVendor;
    if (kIsAndroid) return (await deviceInfo.androidInfo).id;
    return null;
  }

  Future<String?> _desktopDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (kIsMacOS) return (await deviceInfo.macOsInfo).systemGUID;
    if (kIsWindows) return (await deviceInfo.windowsInfo).deviceId;
    if (kIsLinux) return (await deviceInfo.linuxInfo).machineId;
    return null;
  }
}

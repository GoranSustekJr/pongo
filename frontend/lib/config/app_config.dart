import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment values the app is built against, read from the `.env` asset.
final class AppConfig {
  /// Creates a config with explicit values, such as for tests.
  const AppConfig({
    required this.serverUrl,
    required this.socketUrl,
    required this.appleClientId,
    required this.androidClientId,
    required this.desktopClientId,
    required this.desktopClientSecret,
  });

  /// Reads the config from the loaded `.env` file.
  factory AppConfig.fromEnvironment() => AppConfig(
    serverUrl: dotenv.get('SERVER_URL'),
    socketUrl: dotenv.get('SERVER_URL_WSS'),
    appleClientId: dotenv.get('iosClientID'),
    androidClientId: dotenv.get('androidClientID'),
    desktopClientId: dotenv.get('desktopClientID'),
    desktopClientSecret: dotenv.get('desktopClientSecred'),
  );

  /// Base URL of the Pongo API, ending with a slash.
  final String serverUrl;

  /// Base WebSocket URL of the Pongo API, ending with a slash.
  final String socketUrl;

  /// Google OAuth client ID for iOS and macOS.
  final String appleClientId;

  /// Google OAuth server client ID for Android.
  final String androidClientId;

  /// Google OAuth client ID for desktop sign in.
  final String desktopClientId;

  /// Google OAuth client secret for desktop sign in.
  final String desktopClientSecret;
}

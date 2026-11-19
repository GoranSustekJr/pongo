import 'package:pongo/config/app_config.dart';

/// A config pointing at a fake server.
const testConfig = AppConfig(
  serverUrl: 'http://api.test/',
  socketUrl: 'wss://api.test/',
  appleClientId: '',
  androidClientId: '',
  desktopClientId: '',
  desktopClientSecret: '',
);

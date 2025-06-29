import '../../exports.dart';

final kIsDesktop = kIsLinux || kIsWindows || kIsMacOS;

final kIsMobile = kIsAndroid || kIsIOS;

final kIsFlatpak = kIsWeb ? false : Platform.environment["FLATPAK_ID"] != null;

final kIsMacOS = kIsWeb ? false : Platform.isMacOS;
final kIsLinux = kIsWeb ? false : Platform.isLinux;
final kIsAndroid = kIsWeb ? false : Platform.isAndroid;
final kIsIOS = kIsWeb ? false : Platform.isIOS;
final kIsWindows = kIsWeb ? false : Platform.isWindows;

final kIsApple = Platform.isIOS || Platform.isMacOS;

final kPlatform = Platform.isIOS
    ? 'ios'
    : Platform.isMacOS
        ? 'maco0'
        : Platform.isWindows
            ? "windows"
            : Platform.isAndroid
                ? "android"
                : "linux";

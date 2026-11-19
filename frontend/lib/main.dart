import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:window_manager/legacy.dart';

import 'config/app_config.dart';
import 'config/dependencies.dart';
import 'ui/app/desktop_app.dart';
import 'ui/app/phone_app.dart';
import 'ui/app/view_models/app_view_models.dart';
import 'utils/platform.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await dotenv.load();

  if (kIsMacOS) {
    await const MacosWindowUtilsConfig(
      toolbarStyle: NSWindowToolbarStyle.expanded,
      autoHideToolbarAndMenuBarInFullScreenMode: false,
    ).apply();
  }

  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  final providers = await createProviders(AppConfig.fromEnvironment());

  if (kIsAndroid) await FlutterDisplayMode.setHighRefreshRate();
  if (kIsDesktop && !kIsMacOS) await _showDesktopWindow();

  await LiquidGlassWidgets.initialize();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [...providers, ...appViewModelProviders],
      child: LiquidGlassWidgets.wrap(
        theme: const GlassThemeData.ios27(),
        brightnessResolver: Theme.maybeBrightnessOf,
        child: kIsMobile ? const PhoneApp() : const DesktopApp(),
      ),
    ),
  );
}

Future<void> _showDesktopWindow() async {
  await windowManager.ensureInitialized();
  await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
  const options = WindowOptions(
    size: Size(938, 550),
    minimumSize: Size(938, 550),
    center: true,
  );
  unawaited(
    windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    }),
  );
}

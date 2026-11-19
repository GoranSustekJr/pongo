import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:in_app_notification_desktop/in_app_notification.dart' as iand;
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/library/library_sync.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n.dart';
import '../../utils/platform.dart';
import '../auth/widgets/desktop/sign_in_macos.dart';
import '../core/messages/message_listener.dart';
import '../core/themes/colors.dart';
import '../core/themes/dimens.dart';
import '../player/view_models/player_view_model.dart';
import '../player/widgets/desktop/full_screen/full_screen_macos.dart';
import '../shell/view_models/shell_view_model.dart';
import '../shell/widgets/desktop/home_macos.dart';
import 'view_models/app_settings_view_model.dart';
import 'view_models/session_view_model.dart';

/// The app on desktops.
class DesktopApp extends StatefulWidget {
  /// Creates the desktop app.
  const DesktopApp({super.key});

  @override
  State<DesktopApp> createState() => _DesktopAppState();
}

class _DesktopAppState extends State<DesktopApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onInactive: () {
        unawaited(context.read<PlayerViewModel>().saveState());
        // Sends the latest changes before the app may close
        unawaited(context.read<LibrarySync>().sync());
      },
      onResume: () => unawaited(context.read<LibrarySync>().sync()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsMacOS) return const Placeholder();
    final signedIn = context.select<SessionViewModel, bool>(
      (session) => session.isSignedIn,
    );
    final fullscreenPlaying = context.shell.fullscreenPlaying;
    return iand.InAppNotification(
      child: MacosApp(
        themeMode: ThemeMode.dark,
        color: Col.transp,
        darkTheme: MacosThemeData.dark(accentColor: AccentColor.graphite),
        debugShowCheckedModeBanner: false,
        supportedLocales: L10n.all,
        locale: Locale(context.settings.locale),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        scrollBehavior: CustomScrollBehaviour(),
        // Only the app palette is themed; Material widgets keep their defaults.
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            extensions: [AppColors.of(darkMode: context.settings.darkMode)],
          ),
          child: child!,
        ),
        home: MessageListener(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeInOut,
            child: signedIn
                ? ValueListenableBuilder(
                    key: const ValueKey(false),
                    valueListenable: fullscreenPlaying,
                    builder: (context, fullscreen, _) => fullscreen
                        ? const FullScreenMacos()
                        : const MainMacos(key: ValueKey(false)),
                  )
                : const SignInMacos(key: ValueKey(true)),
          ),
        ),
      ),
    );
  }
}

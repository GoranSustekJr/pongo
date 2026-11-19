import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:in_app_notification/in_app_notification.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/l10n.dart';
import '../auth/widgets/phone/auth_redirect_screen_phone.dart';
import '../core/messages/message_listener.dart';
import '../core/themes/theme.dart';
import '../core/ui/blurhash/background.dart';
import '../player/view_models/player_view_model.dart';
import 'view_models/app_settings_view_model.dart';

/// The app on phones.
class PhoneApp extends StatefulWidget {
  /// Creates the phone app.
  const PhoneApp({super.key});

  @override
  State<PhoneApp> createState() => _PhoneAppState();
}

class _PhoneAppState extends State<PhoneApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // The queue is saved whenever the app may be about to close.
    _lifecycle = AppLifecycleListener(
      onInactive: () => unawaited(context.read<PlayerViewModel>().saveState()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.settings;
    return InAppNotification(
      child: MaterialApp(
        title: 'Pongo',
        debugShowCheckedModeBanner: false,
        supportedLocales: L10n.all,
        locale: Locale(settings.locale),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
        home: const SafeArea(
          bottom: false,
          top: false,
          child: MessageListener(child: Background(child: AuthRedirectPhone())),
        ),
      ),
    );
  }
}

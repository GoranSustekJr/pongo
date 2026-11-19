// ignore_for_file: avoid_function_literals_in_foreach_calls

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:in_app_notification/in_app_notification.dart';
import 'package:provider/provider.dart';

import 'package:pongo/app/theme/theme.dart';
import 'package:pongo/core/audio/audio_service_handler.dart';
import 'package:pongo/core/state/globals.dart';
import 'package:pongo/core/storage/secure_storage.dart';
import 'package:pongo/features/auth/presentation/phone/auth_redirect_screen_phone.dart';
import 'package:pongo/l10n/app_localizations.dart';
import 'package:pongo/l10n/l10n.dart';
import 'package:pongo/shared/widgets/blurhash/background.dart';

class PhoneApp extends StatefulWidget {
  const PhoneApp({super.key});

  @override
  State<PhoneApp> createState() => _MyAppPhoneState();
  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppPhoneState? state =
        context.findAncestorStateOfType<_MyAppPhoneState>();
    state?.setLocale(newLocale);
  }
}

class _MyAppPhoneState extends State<PhoneApp> with WidgetsBindingObserver {
  // Locale
  Locale? locale;

  @override
  void initState() {
    super.initState();
    // Init the globals
    mainContext.value = context;
    WidgetsBinding.instance.addObserver(this);

    // Init functions
    getLocale();
  }

  // Set locale
  setLocale(Locale local) {
    setState(() {
      locale = local;
    });
  }

  getLocale() async {
    String? local = await Storage().getLocale();

    setState(() {
      locale = Locale(local.toString());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      // Perform the required functions before the app closes
      performBeforeCloseActions();
    }
  }

  void performBeforeCloseActions() async {
    // Save the state
    final audioServiceHandler =
        Provider.of<AudioHandler>(context, listen: false)
            as AudioServiceHandler;

    // Loop mode
    await Storage().writeLoopMode(audioServiceHandler.audioPlayer.loopMode);

    // Shuffle mode
    bool enabled = audioServiceHandler.audioPlayer.shuffleModeEnabled;
    await Storage().writeShuffleMode(
        enabled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none);

    // Current queue
    List<MediaItem> queue = audioServiceHandler.queue.value;
    await Storage().writeQueue(queue);

    // Queue current playing index
    int queueIndex = audioServiceHandler.audioPlayer.currentIndex ?? -1;
    await Storage().writeQueueIndex(queueIndex);

    // Current playing position
    Duration currentPlayingPosition = audioServiceHandler.audioPlayer.position;
    await Storage().writeCurrentPlayingPosition(currentPlayingPosition);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InAppNotification(
      child: MaterialApp(
        title: 'Pongo',
        debugShowCheckedModeBanner: false,
        supportedLocales: L10n.all,
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme().dark.copyWith(
            brightness: Brightness.light, platform: TargetPlatform.iOS),
        darkTheme: AppTheme().dark,
        themeMode: darkMode.value ? ThemeMode.dark : ThemeMode.light,
        showSemanticsDebugger: false,
        home: const SafeArea(
          bottom: false,
          top: false,
          child: Background(
            child: AuthRedirectPhone(),
          ),
        ),
      ),
    );
  }
}

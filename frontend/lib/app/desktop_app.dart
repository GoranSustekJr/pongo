import 'package:pongo/features/auth/presentation/desktop/sign_in_macos.dart';
import 'package:pongo/features/player/presentation/desktop/full_screen/full_screen_macos.dart';
import 'package:pongo/features/shell/presentation/desktop/home_macos.dart';
import 'package:pongo/exports.dart';
import 'package:in_app_notification_desktop/in_app_notification.dart' as iand;

class MyAppDesktop extends StatefulWidget {
  const MyAppDesktop({super.key});

  @override
  State<MyAppDesktop> createState() => _MyAppDesktopState();
  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppDesktopState? state =
        context.findAncestorStateOfType<_MyAppDesktopState>();
    state?.setLocale(newLocale);
  }
}

class _MyAppDesktopState extends State<MyAppDesktop>
    with WidgetsBindingObserver {
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
    return iand.InAppNotification(
      child: kIsMacOS
          ? MacosApp(
              themeMode: ThemeMode.dark,
              color: Col.transp,
              darkTheme: MacosThemeData.dark(accentColor: AccentColor.graphite),
              debugShowCheckedModeBanner: false,
              supportedLocales: L10n.all,
              locale: locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              showSemanticsDebugger: false,
              scrollBehavior: CustomScrollBehaviour(),
              home: ValueListenableBuilder(
                  valueListenable: isUserSignedIn,
                  builder: (context, signedIn, child) {
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      switchInCurve: Curves.easeInOut,
                      child: signedIn
                          ? ValueListenableBuilder(
                              key: const ValueKey(false),
                              valueListenable: fullscreenPlaying,
                              builder: (context, _, __) {
                                return fullscreenPlaying.value
                                    ? const FullScreenMacos()
                                    : const MainMacos(
                                        key: ValueKey(false),
                                      );
                              })
                          : const SignInMacos(
                              key: ValueKey(true),
                            ),
                    );
                  }),
            )
          : const Placeholder(),
    );
  }
}

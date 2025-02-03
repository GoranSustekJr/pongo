import 'package:pongo/exports.dart';

class MyAppPhone extends StatefulWidget {
  const MyAppPhone({super.key});

  @override
  State<MyAppPhone> createState() => _MyAppPhoneState();
  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppPhoneState? state =
        context.findAncestorStateOfType<_MyAppPhoneState>();
    state?.setLocale(newLocale);
  }
}

class _MyAppPhoneState extends State<MyAppPhone> with WidgetsBindingObserver {
  // Locale
  Locale? locale;

  @override
  void initState() {
    super.initState();
    // Init the globals
    mainContext.value = context;
    WidgetsBinding.instance.addObserver(this);

    // Init functions
    checkIfPremium();
    getLocale();
  }

  // Premium
  void checkIfPremium() async {
    // Premium
    bool premim = await Premium().isPremium(context);
    premium.value = premim;
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
        theme: AppTheme().dark,
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

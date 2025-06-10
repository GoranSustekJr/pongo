// ignore_for_file: avoid_function_literals_in_foreach_calls

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

  final InAppPurchase inAppPurchase = InAppPurchase.instance; // InAppPurchase
  final String premiumId =
      "pongoo1810premium"; // Premium subscription identifier

  bool storeAvailable = true; // Check if store is available for the device
  List<ProductDetails> products = []; // List of product details
  List<PurchaseDetails> purchases = []; // List of purchase details
  late StreamSubscription<List<PurchaseDetails>>
      subscription; // Listen for updates that are betrift mit purchases
  bool isPurchaseInProgress = false; // is a purchase in progress

  @override
  void initState() {
    super.initState();
    // Init the globals
    mainContext.value = context;
    WidgetsBinding.instance.addObserver(this);

    // Init the subscription
    //inAppPurchaseInstance = inAppPurchase;
    //final Stream<List<PurchaseDetails>> purchaseUpdated =
    //  inAppPurchase.purchaseStream;

    /* subscription = purchaseUpdated.listen((purchaseDetails) {
      setState(() {
        purchases.addAll(purchaseDetails);
        listenPurchaseUpdated(purchaseDetails);
      });
    }, onDone: () {
      subscription.cancel();
    }, onError: (error) {
      subscription.cancel();
    }); */

    // Init functions
    initialize();
    checkIfPremium();
    getLocale();
  }

// Init the app/google play store products
  void initialize() async {
    storeAvailable = await inAppPurchase.isAvailable();

    List<ProductDetails> productss = await getProducts(
      productIds: <String>{premiumId},
    );

    subscriptionModels = productss;
    setState(() {
      products = productss;
    });
  }

  // Listener for changes in the purchase stream
  void listenPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (isPurchaseInProgress) return; // If in progress stop

      isPurchaseInProgress = true; // If the first one isolate it

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          // Show pending
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (purchaseDetails.pendingCompletePurchase && isUserSignedIn.value) {
            await inAppPurchase.completePurchase(purchaseDetails);
            // Call your method to handle the purchase
            await Premium().buyPremium(
                context,
                purchaseDetails.verificationData.serverVerificationData,
                purchaseDetails.purchaseID);
          }
          break;

        case PurchaseStatus.error:
//          print("error");
          // handleError(purchaseDetails);
          break;

        default:
          break;
      }

      if (purchaseDetails.pendingCompletePurchase && isUserSignedIn.value) {
        try {
          await inAppPurchase.completePurchase(purchaseDetails);
        } catch (e) {
          //        print("DIGGA; $e");
        }
      }

      isPurchaseInProgress = false; // Reset the flag after processing
    });
  }

  // Get the available products
  Future<List<ProductDetails>> getProducts(
      {required Set<String> productIds}) async {
    ProductDetailsResponse response =
        await inAppPurchase.queryProductDetails(productIds);

    return response.productDetails;
  }

  // Premium
  void checkIfPremium() async {
    // Premium
    Map response = await Premium().isPremium(context);

    if (response["error"] == null) {
      if (response["expires"] != null) {
        await Storage().writeSubscriptionEnd(response["expires"]);
      }
      premium.value = response["premium"];
    } else {
      bool subscription = await Storage().getSubscription();
      DateTime expiresIn = await Storage().getSubscriptionEnd();

      if (DateTime.now().isBefore(expiresIn)) {
        premium.value = subscription;
      }
    }
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
    subscription.cancel();
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

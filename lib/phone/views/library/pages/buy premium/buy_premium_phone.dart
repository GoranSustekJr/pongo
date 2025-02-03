import 'package:pongo/exports.dart';

class BuyPremiumPhone extends StatefulWidget {
  const BuyPremiumPhone({super.key});

  @override
  State<BuyPremiumPhone> createState() => _BuyPremiumPhoneState();
}

class _BuyPremiumPhoneState extends State<BuyPremiumPhone>
    with WidgetsBindingObserver {
  // Premium
  final InAppPurchase inAppPurchase = InAppPurchase.instance; // InAppPurchase
  final String premiumId =
      "pongoo1810premium"; // Premium subscription identifier

  bool storeAvailable = true; // Check if store is available for the device
  List<ProductDetails> products = []; // List of product details
  List<PurchaseDetails> purchases = []; // List of purchase details
  late StreamSubscription<List<PurchaseDetails>>
      subscription; // Listen for updates that are betrift mit purchases

// Init
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showBottomNavBar.value = false;
    });

    // Init the subscription
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        inAppPurchase.purchaseStream;

    subscription = purchaseUpdated.listen((purchaseDetails) {
      setState(() {
        purchases.addAll(purchaseDetails);
        listenPurchaseUpdated(purchaseDetails);
      });
    }, onDone: () {
      subscription.cancel();
    }, onError: (error) {
      subscription.cancel();
    });

    // Init the specials
    initialize();
  }

  // Init the app/google play store products
  void initialize() async {
    storeAvailable = await inAppPurchase.isAvailable();

    List<ProductDetails> productss = await getProducts(
      productIds: <String>{premiumId},
    );

    setState(() {
      products = productss;
    });
  }

  // Listener for changes in the purchase stream
  void listenPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          // Show pending
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (purchaseDetails.pendingCompletePurchase) {
            await inAppPurchase.completePurchase(purchaseDetails);

            // Call your method to handle the purchase
            await Premium().buyPremium(
                context,
                purchaseDetails.verificationData.serverVerificationData,
                purchaseDetails.purchaseID);
          }
          break;

        case PurchaseStatus.error:
          // handleError(purchaseDetails);
          break;

        default:
          break;
      }

      if (purchaseDetails.pendingCompletePurchase) {
        await inAppPurchase.completePurchase(purchaseDetails);
      }
    });
  }

  // Get the available products
  Future<List<ProductDetails>> getProducts(
      {required Set<String> productIds}) async {
    ProductDetailsResponse response =
        await inAppPurchase.queryProductDetails(productIds);

    return response.productDetails;
  }

  // subscribe
  void subscribe({required ProductDetails product}) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  @override
  void dispose() {
    subscription.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showBottomNavBar.value = true;
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      decoration: AppConstants().backgroundBoxDecoration,
      child: Scaffold(
        body: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(child: Container()),
            Image.asset("assets/images/your_image_transparent.png"),
            Container(
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(35)),
              child: textButton(
                  "${AppLocalizations.of(context)!.buypremium}: ${products.isNotEmpty ? products[0].price : ""} ${products.isNotEmpty ? products[0].currencyCode : ""}",
                  () {
                subscribe(product: products[0]);
              }, const TextStyle(color: Colors.white)),
            ),
            Expanded(child: Container()),
            textButton(AppLocalizations.of(context)!.cancel, () {
              Navigator.of(context).pop();
            }, const TextStyle(color: Colors.white)),
            razh(kBottomNavigationBarHeight)
          ],
        ),
      ),
    );
  }
}

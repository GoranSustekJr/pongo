import 'package:pongo/exports.dart';

class BuyPremiumPhone extends StatefulWidget {
  const BuyPremiumPhone({super.key});

  @override
  State<BuyPremiumPhone> createState() => _BuyPremiumPhoneState();
}

class _BuyPremiumPhoneState extends State<BuyPremiumPhone>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showBottomNavBar.value = false;
    });
  }

  // subscribe
  void subscribe({required ProductDetails product}) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    if (inAppPurchaseInstance != null) {
      try {
        await inAppPurchaseInstance!
            .buyNonConsumable(purchaseParam: purchaseParam);
      } catch (e) {
        Notifications().showWarningNotification(context,
            "An error has occured. Try buying premium later. If the problems continue, contact us at pongo.group@gmail.com");
      }
    }
  }

  @override
  void dispose() {
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
                  "${AppLocalizations.of(context)!.buypremium}: ${subscriptionModels.isNotEmpty ? subscriptionModels[0].price : ""} ${subscriptionModels.isNotEmpty ? subscriptionModels[0].currencyCode : ""}",
                  () {
                Notifications()
                    .showDisabledNotification(notificationsContext.value!);
              }, const TextStyle(color: Colors.white)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                AppLocalizations.of(context)!
                    .pleaseleavethepageafterasuccessfullpurchase,
                textAlign: TextAlign.center,
              ),
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

import '../../../../exports.dart';

class ProfilePhone extends StatefulWidget {
  const ProfilePhone({super.key});

  @override
  State<ProfilePhone> createState() => _ProfilePhoneState();
}

class _ProfilePhoneState extends State<ProfilePhone>
    with WidgetsBindingObserver {
  // User data
  String email = "";
  String name = "";
  String image = "";

  // Show Body
  bool showBody = false;

  // Locale
  String locale = "en";

  // Ad
  InterstitialAd? interstitialAd;

  String adUnitId =
      "ca-app-pub-3940256099942544/4411468910"; // "ca-app-pub-3931049547680648/4444030128";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showBottomNavBar.value = false;
    });
    loadAdd();
    initUserData();
    initLocale();
  }

  void loadAdd() async {
    await InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          // Called when an ad is successfully received.
          onAdLoaded: (ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
                // Called when the ad showed the full screen content.
                onAdShowedFullScreenContent: (ad) {},
                // Called when an impression occurs on the ad.
                onAdImpression: (ad) {},
                // Called when the ad failed to show full screen content.
                onAdFailedToShowFullScreenContent: (ad, err) {
                  // Dispose the ad here to free resources.
                  ad.dispose();
                },
                // Called when the ad dismissed full screen content.
                onAdDismissedFullScreenContent: (ad) {
                  // Dispose the ad here to free resources.
                  ad.dispose();
                },
                // Called when a click is recorded for an ad.
                onAdClicked: (ad) {});

            debugPrint('$ad loaded.');
            // Keep a reference to the ad so you can show it later.
            interstitialAd = ad;
          },
          // Called when an ad request failed.
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('InterstitialAd failed to load: $error');
          },
        ));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showBottomNavBar.value = true;
    });
    super.dispose();
  }

  initUserData() async {
    final data = await UserData().get(context);

    if (data != null) {
      setState(() {
        email = data["email"];
        name = data["name"];
        image = data["picture"];
        showBody = true;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  initLocale() async {
    final loc = await Storage().getLocale();
    setState(() {
      locale = loc ?? "en";
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return ValueListenableBuilder(
        valueListenable: isUserSignedIn,
        builder: (context, _, child) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: showBody
                ? Container(
                    key: const ValueKey(true),
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    decoration: AppConstants().backgroundBoxDecoration,
                    child: Scaffold(
                      appBar: AppBar(
                        automaticallyImplyLeading: false,
                        title: Row(
                          children: [
                            backButton(context),
                            Expanded(
                              child: Container(),
                            ),
                            kIsApple
                                ? appleLocalePopup(
                                    locale,
                                    (loc) {
                                      setState(() {
                                        locale = loc;
                                      });
                                    },
                                  )
                                : appleLocalePopup(
                                    "en",
                                    (loc) {
                                      setState(() {
                                        locale = loc;
                                      });
                                    },
                                  ), //TODO: non apple implement
                          ],
                        ),
                      ),
                      body: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            razw(size.width),
                            razh(AppBar().preferredSize.height / 2),
                            Text(
                              AppLocalizations.of(context)!.profile,
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            razh(AppBar().preferredSize.height / 2),
                            CircleAvatar(
                              radius: 80,
                              backgroundColor: Col.primaryCard.withAlpha(150),
                              child: image != ""
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(360),
                                      child: ImageCompatible(
                                        image: image,
                                        width: 160,
                                        height: 160,
                                      ),
                                    )
                                  : const SizedBox(),
                            ),
                            razh(AppBar().preferredSize.height),
                            settingsTile(
                                context,
                                true,
                                false,
                                AppIcons.profile,
                                null,
                                name,
                                AppLocalizations.of(context)!.name,
                                () {}),
                            settingsTile(
                                context,
                                false,
                                false,
                                AppIcons.mail,
                                null,
                                email,
                                AppLocalizations.of(context)!.email,
                                () {}),
                            settingsTile(
                              context,
                              false,
                              true,
                              AppIcons.premium,
                              null,
                              AppLocalizations.of(context)!.subscribed,
                              AppLocalizations.of(context)!.premium,
                              () {},
                            ),
                            settingsTile(
                              context,
                              false,
                              true,
                              AppIcons.trash,
                              null,
                              AppLocalizations.of(context)!.delete,
                              AppLocalizations.of(context)!.deleteyouraccount,
                              () async {
                                final ok = await deleteAccountAlert(context);
                                if (ok == CustomButton.positiveButton) {
                                  await DeleteAccount().delete(context);
                                }
                              },
                            ),
                            razh(25),
                            textButton(AppLocalizations.of(context)!.signout,
                                () {
                              SignInHandler().signOut(context);
                              Navigator.of(context).pop();
                            },
                                const TextStyle(
                                    color: Colors.white, fontSize: 18)),
                            textButton(
                              "Get an ad",
                              () async {
                                // Ad

                                await interstitialAd!.show();
                              },
                              const TextStyle(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : loadingScaffold(context, const ValueKey(false)),
          );
        });
  }
}

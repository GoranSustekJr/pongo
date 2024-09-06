import '../../../../exports.dart';

class PreferencesPhone extends StatefulWidget {
  const PreferencesPhone({super.key});

  @override
  State<PreferencesPhone> createState() => _PreferencesPhoneState();
}

class _PreferencesPhoneState extends State<PreferencesPhone> {
  // Show body
  bool showBody = false;

  // Market
  String market = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showBottomNavBar.value = false;
    });
    initPreferences();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showBottomNavBar.value = true;
    });
    super.dispose();
  }

  initPreferences() async {
    final mark = await Storage().getMarket();
    setState(() {
      market = mark ?? 'US';
      showBody = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
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
                    ],
                  ),
                ),
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    razw(size.width),
                    razh(AppBar().preferredSize.height / 2),
                    Text(
                      AppLocalizations.of(context)!.preferences,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    razh(AppBar().preferredSize.height),
                    settingsText(
                        AppLocalizations.of(context)!.searchpreferences),
                    settingTile(
                      context,
                      true,
                      true,
                      AppIcons.world,
                      AppIcons.edit,
                      "${marketsCountryNames[market]} - $market",
                      AppLocalizations.of(context)!.searchmarket,
                      () {
                        kIsApple
                            ? appleMarketPopup(
                                context,
                                market,
                                (mark) async {
                                  Storage().writeMarket(mark);
                                  setState(() {
                                    market = mark;
                                  });
                                },
                              )
                            : appleMarketPopup(
                                //TODO: Implement this for Android
                                context,
                                market,
                                (mark) async {
                                  Storage().writeMarket(mark);
                                  setState(() {
                                    market = mark;
                                  });
                                },
                              );
                      },
                    ),
                  ],
                ),
              ),
            )
          : loadingScaffold(context),
    );
  }
}

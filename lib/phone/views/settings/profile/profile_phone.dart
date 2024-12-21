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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showBottomNavBar.value = false;
    });
    initUserData();
    initLocale();
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
                                      child: CachedNetworkImage(
                                        imageUrl: image,
                                        width: 160,
                                        height: 160,
                                        fit: BoxFit.fill,
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
                            razh(25),
                            textButton(AppLocalizations.of(context)!.signout,
                                () {
                              SignInHandler().signOut(context);
                              Navigator.of(context).pop();
                            },
                                const TextStyle(
                                    color: Colors.white, fontSize: 18)),
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

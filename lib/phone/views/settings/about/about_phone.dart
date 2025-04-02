import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';
import 'package:pongo/phone/views/settings/about/pdf_view.dart';

class AboutPhone extends StatefulWidget {
  const AboutPhone({super.key});

  @override
  State<AboutPhone> createState() => _AboutPhoneState();
}

class _AboutPhoneState extends State<AboutPhone> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showBottomNavBar.value = false;
    });
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
    Size size = MediaQuery.of(context).size;
    return Container(
      key: const ValueKey(true),
      width: size.width,
      height: size.height,
      decoration: AppConstants().backgroundBoxDecoration,
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              snap: true,
              floating: true,
              pinned: true,
              backgroundColor: useBlur.value
                  ? Col.transp
                  : Col.realBackground.withAlpha(AppConstants().noBlur),
              stretch: true,
              automaticallyImplyLeading: false,
              expandedHeight: kIsApple ? size.height / 5 : size.height / 4,
              title: Row(
                children: [
                  backButton(context),
                  Expanded(
                    child: Container(),
                  ),
                ],
              ),
              flexibleSpace: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: useBlur.value ? 10 : 0,
                    sigmaY: useBlur.value ? 10 : 0,
                  ),
                  child: FlexibleSpaceBar(
                    centerTitle: true,
                    title: Text(
                      "Pongo",
                      style: TextStyle(
                        fontSize: kIsApple ? 25 : 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    stretchModes: const [
                      StretchMode.zoomBackground,
                      StretchMode.blurBackground,
                      StretchMode.fadeTitle,
                    ],
                  ),
                ),
              ),
            ),
            SliverList(
              delegate:
                  SliverChildBuilderDelegate((BuildContext context, int index) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    razh(AppBar().preferredSize.height / 2),
                    razh(AppBar().preferredSize.height),
                    settingsText(AppLocalizations.of(context).about),
                    settingsTile(
                        context,
                        true,
                        false,
                        AppIcons.mail,
                        Icons.copy,
                        "pongo.group@gmail.com",
                        AppLocalizations.of(context).contactusviamail,
                        () async {
                      await Clipboard.setData(
                          const ClipboardData(text: "pongo.group@gmail.com"));
                    }),
                    settingsTile(
                        context,
                        false,
                        false,
                        CupertinoIcons.bookmark_fill,
                        CupertinoIcons.envelope_open,
                        AppLocalizations.of(context).termsandconditions,
                        AppLocalizations.of(context).ourtermsandconditions,
                        () async {
                      Navigations().nextScreen(context, const PDFView());
                    }),
                    settingsTile(
                        context,
                        false,
                        true,
                        CupertinoIcons.lock_shield,
                        CupertinoIcons.envelope_open,
                        AppLocalizations.of(context).privacypolicy,
                        AppLocalizations.of(context).ourprivacypolicy,
                        () {}),
                  ],
                );
              }, childCount: 1),
            ),
          ],
        ),
      ),
    );
  }
}

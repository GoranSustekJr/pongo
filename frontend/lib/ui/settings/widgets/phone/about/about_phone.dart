import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../routing/navigation.dart';
import '../../../../../utils/platform.dart';
import '../../../../app/view_models/app_settings_view_model.dart';
import '../../../../core/app_icons.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/themes/dimens.dart';
import '../../../../core/ui/app_blur.dart';
import '../../../../core/ui/phone/buttons/back_button.dart';
import '../../../../core/ui/space.dart';
import '../../../../shell/view_models/shell_view_model.dart';
import '../widgets/settings_text.dart';
import '../widgets/settings_tile.dart';
import 'pdf_view.dart';

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
      context.shell.showBottomNavBar.value = false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.shell.showBottomNavBar.value = true;
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Container(
      key: const ValueKey(true),
      width: size.width,
      height: size.height,
      decoration: context.colors.backgroundBoxDecoration,
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              snap: true,
              floating: true,
              pinned: true,
              backgroundColor: context.readSettings.useBlur
                  ? Col.transp
                  : context.colors.realBackground.withAlpha(Dimens.noBlur),
              stretch: true,
              automaticallyImplyLeading: false,
              expandedHeight: kIsApple ? size.height / 5 : size.height / 4,
              title: Row(
                children: [
                  backButton(context),
                  Expanded(child: Container()),
                ],
              ),
              flexibleSpace: ClipRRect(
                child: BackdropFilter(
                  filter: appBlur(context, 10),
                  child: FlexibleSpaceBar(
                    centerTitle: true,
                    title: Text(
                      'Pongo',
                      style: TextStyle(
                        fontSize: kIsApple ? 25 : 30,
                        fontWeight: FontWeight.bold,
                        color: context.colors.text,
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
              delegate: SliverChildBuilderDelegate((
                BuildContext context,
                int index,
              ) {
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
                      'pongo.group@gmail.com',
                      AppLocalizations.of(context).contactusviamail,
                      () async {
                        await Clipboard.setData(
                          const ClipboardData(text: 'pongo.group@gmail.com'),
                        );
                      },
                    ),
                    settingsTile(
                      context,
                      false,
                      false,
                      CupertinoIcons.bookmark_fill,
                      CupertinoIcons.envelope_open,
                      AppLocalizations.of(context).termsandconditions,
                      AppLocalizations.of(context).ourtermsandconditions,
                      () {
                        Navigations().nextScreen(context, const PDFView());
                      },
                    ),
                    settingsTile(
                      context,
                      false,
                      true,
                      CupertinoIcons.lock_shield,
                      CupertinoIcons.envelope_open,
                      AppLocalizations.of(context).privacypolicy,
                      AppLocalizations.of(context).ourprivacypolicy,
                      () {},
                    ),
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

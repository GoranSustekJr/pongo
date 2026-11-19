import 'package:flutter/material.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:provider/provider.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../utils/platform.dart';
import '../../../../app/view_models/app_settings_view_model.dart';
import '../../../../core/app_icons.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/ui/buttons/text_button.dart';
import '../../../../core/ui/phone/buttons/back_button.dart';
import '../../../../core/ui/space.dart';
import '../../../../shell/view_models/shell_view_model.dart';
import '../../../view_models/profile_view_model.dart';
import '../widgets/settings_tile.dart';
import 'delete_account_alert.dart';
import 'locale_popup.dart';
import 'profile_image.dart';

class ProfilePhone extends StatefulWidget {
  const ProfilePhone({super.key});

  @override
  State<ProfilePhone> createState() => _ProfilePhoneState();
}

class _ProfilePhoneState extends State<ProfilePhone>
    with WidgetsBindingObserver {
  late final ProfileViewModel viewModel;
  late final ShellViewModel _shell;

  String get email => viewModel.profile?.email ?? '';
  String get name => viewModel.profile?.name ?? '';
  String get image => viewModel.profile?.picture ?? '';
  bool get hidden => viewModel.profile?.hiddenAuth ?? false;

  // Show Body
  bool get showBody => viewModel.profile != null;

  // Locale
  late String locale = context.readSettings.locale;

  @override
  void initState() {
    super.initState();
    _shell = context.read<ShellViewModel>();
    viewModel = ProfileViewModel(auth: context.read());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _shell.showBottomNavBar.value = false;
    });
  }

  @override
  void dispose() {
    viewModel.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _shell.showBottomNavBar.value = true;
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: showBody
              ? Container(
                  key: const ValueKey(true),
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  decoration: context.colors.backgroundBoxDecoration,
                  child: Scaffold(
                    backgroundColor: Col.transp,
                    appBar: AppBar(
                      automaticallyImplyLeading: false,
                      title: Row(
                        children: [
                          backButton(context),
                          Expanded(child: Container()),
                          kIsApple
                              ? appleLocalePopup(locale, (loc) {
                                  setState(() {
                                    locale = loc;
                                  });
                                })
                              : appleLocalePopup('en', (loc) {
                                  setState(() {
                                    locale = loc;
                                  });
                                }), //TODO: non apple implement
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
                            AppLocalizations.of(context).profile,
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w500,
                              color: context.colors.text,
                            ),
                          ),
                          razh(AppBar().preferredSize.height / 2),
                          profileImage(context, image),
                          razh(AppBar().preferredSize.height),
                          if (!hidden && name != '')
                            settingsTile(
                              context,
                              true,
                              false,
                              AppIcons.profile,
                              null,
                              name,
                              AppLocalizations.of(context).name,
                              () {},
                            ),
                          if (hidden)
                            settingsTile(
                              context,
                              true,
                              false,
                              AppIcons.hide,
                              null,
                              AppLocalizations.of(context).hidden,
                              AppLocalizations.of(context)
                                  .allofyourdataishidden,
                              () {},
                            ),
                          settingsTile(
                            context,
                            !hidden && name == '',
                            false,
                            AppIcons.mail,
                            null,
                            email,
                            AppLocalizations.of(context).email,
                            () {},
                          ),
                          settingsTile(
                            context,
                            false,
                            true,
                            AppIcons.trash,
                            null,
                            AppLocalizations.of(context).delete,
                            AppLocalizations.of(context).deleteyouraccount,
                            () async {
                              final ok = await deleteAccountAlert(context);
                              if (ok == CustomButton.positiveButton) {
                                await viewModel.deleteAccount();
                              }
                            },
                          ),
                          razh(25),
                          textButton(
                            AppLocalizations.of(context).signout,
                            () {
                              viewModel.signOut();
                              Navigator.of(context).pop();
                            },
                            TextStyle(color: context.colors.text, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : Scaffold(
                  key: const ValueKey(false),
                  backgroundColor: Colors.black,
                  appBar: AppBar(
                    automaticallyImplyLeading: false,
                    title: Row(
                      children: [
                        backButton(context),
                        Expanded(child: Container()),
                      ],
                    ),
                  ),
                  body: Center(
                    child: textButton(AppLocalizations.of(context).signout, () {
                      viewModel.signOut();
                      Navigator.of(context).pop();
                    }, const TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                ),
        );
      },
    );
  }
}

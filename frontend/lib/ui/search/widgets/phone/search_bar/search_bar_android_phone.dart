import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../app/view_models/app_settings_view_model.dart';
import '../../../../core/app_icons.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/ui/phone/app_bar_blur.dart';
import '../../../../core/ui/phone/buttons/icon_button.dart';
import '../../../../shell/view_models/shell_view_model.dart';

class SearchBarAndroidPhone extends StatefulWidget
    implements PreferredSizeWidget {
  final Function(String) onFieldSubmitted;
  final Function(bool) setShowSearchHistory;
  final FocusNode focusNode;
  final TextEditingController searchController;
  const SearchBarAndroidPhone({
    super.key,
    required this.onFieldSubmitted,
    required this.searchController,
    required this.setShowSearchHistory,
    required this.focusNode,
  });

  @override
  State<SearchBarAndroidPhone> createState() => _SearchBarAndroidPhoneState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _SearchBarAndroidPhoneState extends State<SearchBarAndroidPhone> {
  // Is Searching
  bool searching = false;

  // Search Text Controller
  TextEditingController searchController = TextEditingController(text: '');

  // Query / Inserted Text
  String? query;

  // Show x
  bool showX = false;

  // Constant Text Form Field Border
  OutlineInputBorder border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: Col.transp),
  );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: context.shell.searchBarIsSearching,
      builder: (context, isSearching, child) {
        return SizedBox(
          height: Scaffold.of(context).appBarMaxHeight == null
              ? MediaQuery.of(context).padding.top +
                    AppBar().preferredSize.height
              : Scaffold.of(context).appBarMaxHeight!,
          child: AppBar(
            backgroundColor: Col.transp,
            shadowColor: Col.transp,
            surfaceTintColor: Col.transp,
            title: TextFormField(
              cursorColor: context.colors.onIcon,
              controller: widget.searchController,
              focusNode: widget.focusNode,
              onTap: () {
                widget.setShowSearchHistory(true);
                setState(() {
                  searching = true;
                  context.shell.searchBarIsSearching.value = true;
                });
              },
              onChanged: (value) {
                setState(() {
                  query = value;
                });
              },
              onFieldSubmitted: (qry) {
                widget.setShowSearchHistory(false);
                widget.onFieldSubmitted(qry); // Callback
                widget.focusNode.unfocus();
              },
              style: TextStyle(color: context.colors.text),
              decoration: InputDecoration(
                enabledBorder: border,
                border: border,
                hintText: AppLocalizations.of(context).search,
                hintStyle: TextStyle(
                  color: context.colors.text, // Hint text color
                ),
                filled: true,
                fillColor: context.colors.primaryCard.withAlpha(150),
                contentPadding: const EdgeInsets.all(10),
                focusedBorder: border,
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.searchController.text.isNotEmpty)
                      iconButton(AppIcons.x, context.colors.icon, () {
                        setState(() {
                          widget.searchController.clear();
                        });
                      }, edgeInsets: EdgeInsets.zero),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        if (context.shell.searchBarIsSearching.value) {
                          setState(() {
                            searching = false;
                            context.shell.searchBarIsSearching.value = false;
                          });
                          widget.focusNode.unfocus();
                          searchController.clear();
                          widget.setShowSearchHistory(false);
                          widget.onFieldSubmitted('');
                        } else {
                          setState(() {
                            searching = true;
                            context.shell.searchBarIsSearching.value = true;
                          });
                          widget.setShowSearchHistory(true);
                          widget.focusNode.requestFocus();
                        }
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedOpacity(
                            duration: Duration(
                              milliseconds: context.readSettings.useAnimations
                                  ? 250
                                  : 0,
                            ),
                            opacity: context.shell.searchBarIsSearching.value
                                ? 1
                                : 0,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 15),
                              child: Text(
                                AppLocalizations.of(context).cancel,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.text.withAlpha(200),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            flexibleSpace: appBarBlur(),
          ),
        );
      },
    );
  }
}

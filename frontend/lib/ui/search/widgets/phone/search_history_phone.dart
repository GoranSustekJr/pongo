import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/view_models/app_settings_view_model.dart';
import '../../../core/app_icons.dart';
import '../../../core/themes/colors.dart';
import '../../../core/ui/app_blur.dart';
import '../../../core/ui/buttons/text_button.dart';
import '../../../core/ui/space.dart';
import 'search_history_tile.dart';

class SearchHistoryPhone extends StatelessWidget {
  final bool showSearchHistory;
  final bool clear;
  final List<String> searchHistory;
  final Function(String) search;
  final Function(String) removeItem;
  final Function() clearAll;
  final Function() changeClear;
  const SearchHistoryPhone({
    super.key,
    required this.search,
    required this.searchHistory,
    required this.removeItem,
    required this.clearAll,
    required this.showSearchHistory,
    required this.clear,
    required this.changeClear,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        height:
            MediaQuery.of(context).size.height -
            MediaQuery.of(context).viewInsets.bottom,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: context.colors.primaryCard.withAlpha(
            context.readSettings.useBlur ? 150 : 240,
          ),
        ),
        child: AnimatedOpacity(
          duration: const Duration(
            milliseconds: /* context.readSettings.useAnimations ? 350 :  */ 0,
          ),
          opacity: showSearchHistory ? 1 : 0,
          child: ClipRRect(
            child: BackdropFilter(
              filter: appBlur(context, 10),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(top: 0, left: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      razh(
                        Scaffold.of(context).appBarMaxHeight == null
                            ? MediaQuery.of(context).padding.top +
                                  AppBar().preferredSize.height +
                                  20
                            : Scaffold.of(context).appBarMaxHeight! + 20,
                      ),
                      if (searchHistory.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.zero,
                          child: Row(
                            children: [
                              textButtonNoPadding(
                                clear
                                    ? AppLocalizations.of(context).cancel
                                    : AppLocalizations.of(context)
                                          .clearallhistory,
                                changeClear,
                                TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w300,
                                  color: context.colors.text.withAlpha(200),
                                ),
                              ),
                              const Expanded(child: SizedBox()),
                              AnimatedContainer(
                                duration: Duration(
                                  milliseconds:
                                      context.readSettings.useAnimations
                                      ? 350
                                      : 0,
                                ),
                                width: clear ? 50 : 0,
                                child: SizedBox(
                                  width: 50,
                                  height: 40,
                                  child: CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: clearAll,
                                    child: Icon(
                                      AppIcons.trash,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: searchHistory.length,
                        itemBuilder: (context, index) {
                          return searchHistoryTile(
                            searchHistory[index],
                            searchHistory.length - 1 == index,
                            () {
                              search(searchHistory[index]);
                            },
                            () => removeItem(searchHistory[index]),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

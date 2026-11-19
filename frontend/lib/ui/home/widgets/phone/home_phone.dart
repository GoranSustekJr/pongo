import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../utils/platform.dart';
import '../../../app/view_models/app_settings_view_model.dart';
import '../../../recommendations/widgets/phone/recommendations_phone.dart';
import '../../../search/view_models/search_history_view_model.dart';
import '../../../search/widgets/phone/search_bar/search_bar_android_phone.dart';
import '../../../search/widgets/phone/search_bar/search_bar_ios_phone.dart';
import '../../../search/widgets/phone/search_history_phone.dart';
import '../../../search/widgets/phone/search_phone.dart';
import '../../../shell/view_models/shell_view_model.dart';

class HomePhone extends StatefulWidget {
  const HomePhone({super.key});

  @override
  State<HomePhone> createState() => _HomePhoneState();
}

class _HomePhoneState extends State<HomePhone> {
  // Search query
  String query = '';

  // Search filter
  String filter = '';

  // Search controller
  TextEditingController searchController = TextEditingController(text: '');

  // Keyboard Focus Node, shared with the shell so other screens can focus
  // the search field.
  late final FocusNode focusNode = context.shell.searchFocusNode;

  // Show Search History
  bool showSearchHistory = false;

  // Clear history list
  bool clear = false;

  late final SearchHistoryViewModel searchHistoryViewModel;

  @override
  void initState() {
    super.initState();
    searchHistoryViewModel = SearchHistoryViewModel(history: context.read());
  }

  @override
  void dispose() {
    searchHistoryViewModel.dispose();
    searchController.dispose();
    super.dispose();
  }

  // On Field Submitted Callback Function
  Future<void> onFieldSubmitted(String qry) async {
    if (qry != '') {
      await searchHistoryViewModel.add(qry.trim());
      setState(() {
        query = qry.trim();
      });
    } else {
      // Cancelled
      setState(() {
        query = '';
        filter = '';
        showSearchHistory = false;
      });
    }
  }

  void unfocus(FocusNode focusNode) {
    focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: context.shell.showSearchBar,
      builder: (context, value, child) {
        return ValueListenableBuilder(
          valueListenable: context.shell.searchBarIsSearching,
          builder: (context, value, child) {
            return Stack(
              children: [
                // 1. - home screen recomendations
                AnimatedOpacity(
                  opacity:
                      (context.shell.searchBarIsSearching.value ||
                          focusNode.hasFocus)
                      ? 1
                      : 0,
                  duration: Duration(
                    milliseconds: !context.readSettings.useAnimations
                        ? 0
                        : context.shell.searchBarIsSearching.value ||
                              focusNode.hasFocus
                        ? 350
                        : 250,
                  ),
                  child: SearchPhone(query: query),
                ),
                // 2. - search screen
                AnimatedPositioned(
                  duration: const Duration(
                    milliseconds: /* !context.readSettings.useAnimations
                          ? 0
                          : context.shell.searchBarIsSearching.value || focusNode.hasFocus
                              ? 400
                              : 35 */
                        0,
                  ),
                  curve:
                      context.shell.searchBarIsSearching.value ||
                          focusNode.hasFocus
                      ? Curves.easeInOut
                      : Curves.fastEaseInToSlowEaseOut,
                  top:
                      (context.shell.searchBarIsSearching.value ||
                          focusNode.hasFocus)
                      ? MediaQuery.of(context).size.height
                      : 0,
                  child: const RecommendationsPhone(),
                ),
                // 3. - Search history screen
                Positioned(
                  top: showSearchHistory
                      ? 0
                      : -MediaQuery.of(context).size.height,
                  child: ListenableBuilder(
                    listenable: searchHistoryViewModel,
                    builder: (context, _) => SearchHistoryPhone(
                      showSearchHistory: showSearchHistory,
                      clear: clear,
                      searchHistory: searchHistoryViewModel.searches
                          .map((item) {
                            if (item.trim().contains(filter.trim())) {
                              return item;
                            }
                            return null;
                          })
                          .where((item) => item != null)
                          .cast<String>()
                          .toList(),
                      removeItem: searchHistoryViewModel.remove,
                      clearAll: searchHistoryViewModel.clear,
                      search: (qry) {
                        setState(() {
                          context.shell.searchBarIsSearching.value = true;
                          searchController.value = TextEditingValue(text: qry);
                          showSearchHistory = false;
                        });
                        unawaited(onFieldSubmitted(qry));
                        unfocus(focusNode);
                      },
                      changeClear: () {
                        setState(() {
                          clear = !clear;
                        });
                      },
                    ),
                  ),
                ),
                // 4. - Search bar
                AnimatedPositioned(
                  top: context.shell.showSearchBar.value ? 0 : -100,
                  width: MediaQuery.of(context).size.width,
                  duration: Duration(
                    milliseconds: context.readSettings.useAnimations ? 500 : 0,
                  ),
                  curve: Curves.easeInOut,
                  child: kIsIOS
                      ? SearchBarIOSPhone(
                          searchController: searchController,
                          onFieldSubmitted: onFieldSubmitted,
                          focusNode: focusNode,
                          setShowSearchHistory: (show) {
                            setState(() {
                              showSearchHistory = show;
                            });
                          },
                          onChanged: (qry) {
                            setState(() {
                              filter = qry;
                            });
                          },
                        )
                      : SearchBarAndroidPhone(
                          onFieldSubmitted: onFieldSubmitted,
                          focusNode: focusNode,
                          setShowSearchHistory: (show) {
                            setState(() {
                              showSearchHistory = show;
                            });
                          },
                          searchController: searchController,
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

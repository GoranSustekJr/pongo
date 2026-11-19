import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/library/library_sync.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/app_icons.dart';
import '../../../core/themes/colors.dart';
import '../../../recommendations/widgets/desktop/recommendations_macos.dart';
import '../../../shell/view_models/shell_view_model.dart';
import '../../view_models/search_history_view_model.dart';
import 'searching_macos.dart';

class SearchMacos extends StatefulWidget {
  const SearchMacos({super.key});

  @override
  State<SearchMacos> createState() => _SearchMacosState();
}

class _SearchMacosState extends State<SearchMacos> {
  // Show searching
  bool showSearching = false;

  // Searching
  TextEditingController searchController = TextEditingController();
  late final FocusNode focusNode;
  late final SearchHistoryViewModel history;
  String qry = '';
  bool searching = false;

  @override
  void initState() {
    super.initState();
    history = SearchHistoryViewModel(
      history: context.read(),
      libraryChanges: context.read<LibrarySync>(),
    )
      ..addListener(() => setState(() {}));
    focusNode = context.shell.searchFocusNode..addListener(focusNodeListener);
  }

  @override
  void dispose() {
    focusNode.removeListener(focusNodeListener);
    history.dispose();
    searchController.dispose();
    super.dispose();
  }

  List<SearchResultItem> get searchHistory => [
    for (final item in history.searches)
      SearchResultItem(
        item,
        child: Row(
          children: [
            Text(item),
            Expanded(child: Container()),
            GestureDetector(
              onTap: () => history.remove(item),
              child: Icon(
                AppIcons.cancel,
                color: Colors.white.withAlpha(100),
                size: 15,
              ),
            ),
          ],
        ),
      ),
  ];

  Future<void> onFieldSubmitted(String query) async {
    if (query != '') {
      await history.add(query.trim());

      setState(() {
        showSearching = true;
        qry = query.trim();
      });
    }
  }

  void focusNodeListener() {
    if (!focusNode.hasFocus && showSearching) {
      onFieldSubmitted(searchController.text);
    } else if (focusNode.hasFocus &&
        !showSearching &&
        searchController.text != '') {
      setState(() {
        showSearching = true;
      });
    } else if (!focusNode.hasFocus && searchController.text.isNotEmpty) {
      onFieldSubmitted(searchController.text);
    }
    setState(() {
      searching = focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return MacosScaffold(
      backgroundColor: Col.transp,
      children: [
        ContentArea(
          builder: (context, scrollController) {
            return ValueListenableBuilder(
              valueListenable: context.shell.searchBarIsSearching,
              builder: (context, value, child) {
                return Container(
                  height: size.height,
                  width: size.width,
                  color: Col.transp,
                  child: Stack(
                    children: [
                      AnimatedOpacity(
                        opacity:
                            showSearching ||
                                context.shell.searchBarIsSearching.value
                            ? 1
                            : 0,
                        duration: const Duration(milliseconds: 500),
                        child: SearchingMacos(query: qry),
                      ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 500),
                        bottom:
                            showSearching ||
                                context.shell.searchBarIsSearching.value
                            ? size.height * 2
                            : null,
                        child: AnimatedOpacity(
                          opacity:
                              showSearching ||
                                  context.shell.searchBarIsSearching.value
                              ? 0
                              : 1,
                          duration: const Duration(milliseconds: 500),
                          child: const RecommendationsMacos(),
                        ),
                      ),
                      SizedBox(
                        height: 50,
                        child: ClipRRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  Flexible(
                                    child: MacosSearchField(
                                      maxLines: 1,
                                      placeholder: AppLocalizations.of(context)
                                          .search,
                                      placeholderStyle: TextStyle(
                                        color: Colors.white.withAlpha(150),
                                      ),
                                      decoration: BoxDecoration(
                                        color: context.colors.primaryCard
                                            .withAlpha(200),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      focusNode: focusNode,
                                      results: searchHistory,
                                      controller: searchController,
                                      expands: false,
                                      onTap: () {
                                        //TODO: SOmething
                                      },
                                    ),
                                  ),
                                  if (context
                                          .shell
                                          .searchBarIsSearching
                                          .value ||
                                      focusNode.hasFocus ||
                                      showSearching)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 10),
                                      child: CupertinoButton(
                                        padding: EdgeInsets.zero,
                                        onPressed: () {
                                          if (context
                                                  .shell
                                                  .searchBarIsSearching
                                                  .value ||
                                              focusNode.hasFocus ||
                                              showSearching) {
                                            setState(() {
                                              searching = false;
                                              context
                                                      .shell
                                                      .searchBarIsSearching
                                                      .value =
                                                  false;
                                              showSearching = false;
                                            });
                                            focusNode.unfocus();
                                            searchController.clear();
                                            // Set Empty Query In Parent Widget
                                            onFieldSubmitted('');
                                          }
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            right: 5,
                                          ),
                                          child: Text(
                                            AppLocalizations.of(context).cancel,
                                            style: TextStyle(
                                              color: Colors.white.withAlpha(
                                                200,
                                              ),
                                              fontSize: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
    /*   const SizedBox(); */
  }
}

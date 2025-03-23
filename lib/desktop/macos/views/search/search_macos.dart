import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:pongo/desktop/macos/views/search/recommendations/recommendations_macos.dart';
import 'package:pongo/desktop/macos/views/search/searching/searching_macos.dart';
import 'package:pongo/exports.dart';

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
  FocusNode focusNode = FocusNode();
  List<SearchResultItem> searchHistory = [];
  String qry = "";
  bool searching = false;

  @override
  void initState() {
    super.initState();
    initSearchHistory();
    focusNode.addListener(focusNodeListener);
  }

  initSearchHistory() async {
    final data = await DatabaseHelper().querySearchHistorySearch();
    setState(() {
      searchHistory = data
          .map((item) => SearchResultItem(
                item,
                child: Row(
                  children: [
                    Text(item),
                    Expanded(child: Container()),
                    GestureDetector(
                      onTap: () async {
                        await DatabaseHelper().removeSearchHistoryEntry(item);
                        initSearchHistory();
                      },
                      child: Icon(
                        AppIcons.cancel,
                        color: Colors.white.withAlpha(100),
                        size: 15,
                      ),
                    ),
                  ],
                ),
              ))
          .toList();
    });
  }

  void onFieldSubmitted(String query) async {
    if (query != "") {
      await DatabaseHelper().insertSearchHistorySearch(query.trim());
      await initSearchHistory();

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
        searchController.text != "") {
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
    Size size = MediaQuery.of(context).size;
    return MacosScaffold(
      backgroundColor: Col.transp,
      children: [
        ContentArea(
          builder: (context, scrollController) {
            return Container(
              height: size.height,
              width: size.width,
              color: Col.transp,
              child: Stack(
                children: [
                  AnimatedOpacity(
                    opacity: showSearching ? 1 : 0,
                    duration: const Duration(milliseconds: 500),
                    child: SearchingMacos(
                      query: qry,
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 500),
                    bottom: showSearching ? size.height * 2 : null,
                    child: AnimatedOpacity(
                      opacity: showSearching ? 0 : 1,
                      duration: const Duration(milliseconds: 500),
                      child: const RecommendationsMacos(),
                    ),
                  ),
                  SizedBox(
                    height: 50,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              Flexible(
                                  child: MacosSearchField(
                                maxLines: 1,
                                placeholder:
                                    AppLocalizations.of(context)!.search,
                                placeholderStyle: TextStyle(
                                    color: Colors.white.withAlpha(150)),
                                decoration: BoxDecoration(
                                    color: Col.primaryCard.withAlpha(200),
                                    borderRadius: BorderRadius.circular(5)),
                                focusNode: focusNode,
                                results: searchHistory,
                                controller: searchController,
                                expands: false,
                              )),
                              if (searchBarIsSearching.value ||
                                  focusNode.hasFocus ||
                                  showSearching)
                                Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: () {
                                      if (searchBarIsSearching.value ||
                                          focusNode.hasFocus ||
                                          showSearching) {
                                        setState(() {
                                          searching = false;
                                          searchBarIsSearching.value = false;
                                          showSearching = false;
                                        });
                                        focusNode.unfocus();
                                        searchController.clear();
                                        onFieldSubmitted(
                                            ""); // Set Empty Query In Parent Widget
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 5),
                                      child: Text(
                                        AppLocalizations.of(context)!.cancel,
                                        style: TextStyle(
                                            color: Colors.white.withAlpha(200),
                                            fontSize: 20),
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
        )
      ],
    );
    /*   const SizedBox(); */
  }
}

import 'package:pongo/exports.dart';

class HomePhone extends StatefulWidget {
  const HomePhone({super.key});

  @override
  State<HomePhone> createState() => _HomePhoneState();
}

class _HomePhoneState extends State<HomePhone> {
  // Search query
  String query = "";

  // Search filter
  String filter = "";

  // Search controller
  TextEditingController searchController = TextEditingController(text: '');

  // Keyboard Focus Node
  FocusNode focusNode = FocusNode();

  // Show Search History
  bool showSearchHistory = false;

  // Search history list
  List<String> searchHistory = [];

  // Clear history list
  bool clear = false;

  @override
  void initState() {
    super.initState();
    initSearchHistory();
    searchScreenContext.value = context;
    searchFocusNode.value = focusNode;
  }

  // On Field Submitted Callback Function
  void onFieldSubmitted(String qry) async {
    if (qry != "") {
      await DatabaseHelper().insertSearchHistorySearch(qry.trim());
      await initSearchHistory();
      setState(() {
        query = qry.trim();
      });
    }
  }

  void unfocus(FocusNode focusNode) {
    focusNode.unfocus();
  }

  initSearchHistory() async {
    final data = await DatabaseHelper().querySearchHistorySearch();
    setState(() {
      searchHistory = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: showSearchBar,
      builder: (context, value, child) {
        return ValueListenableBuilder(
          valueListenable: searchBarIsSearching,
          builder: (context, value, child) {
            return SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Stack(
                children: [
                  // 1. - home screen recomendations
                  AnimatedOpacity(
                    opacity: (searchBarIsSearching.value || focusNode.hasFocus)
                        ? 1
                        : 0,
                    duration: Duration(
                        milliseconds:
                            searchBarIsSearching.value || focusNode.hasFocus
                                ? 350
                                : 250),
                    child: SearchPhone(
                      query: query,
                    ),
                  ),
                  // 2. - search screen
                  AnimatedPositioned(
                    duration: Duration(
                        milliseconds:
                            searchBarIsSearching.value || focusNode.hasFocus
                                ? 400
                                : 350),
                    curve: searchBarIsSearching.value || focusNode.hasFocus
                        ? Curves.easeInOut
                        : Curves.fastEaseInToSlowEaseOut,
                    top: (searchBarIsSearching.value || focusNode.hasFocus)
                        ? MediaQuery.of(context).size.height
                        : 0,
                    child: const RecommendationsPhone(),
                  ),
                  // 3. - Search history screen
                  /*  Positioned(
                    top: showSearchHistory
                        ? 0
                        : -MediaQuery.of(context).size.height,
                    child: */
                  /* AnimatedSwitcher(
                    duration:
                        Duration(milliseconds: showSearchHistory ? 400 : 350),
                    child: showSearchHistory
                        ? */
                  /*    */
                  /*  : const SizedBox(),
                  ), */
                  // ),
                  /* AnimatedPositioned(
                    top: showSearchHistory
                        ? 0
                        : -MediaQuery.of(context).size.height,
                    curve: Curves.fastEaseInToSlowEaseOut,
                    duration:
                        Duration(milliseconds: showSearchHistory ? 400 : 350),
                    child: */
                  Positioned(
                    top: showSearchHistory
                        ? 0
                        : -MediaQuery.of(context).size.height,
                    child: SearchHistoryPhone(
                      showSearchHistory: showSearchHistory,
                      clear: clear,
                      searchHistory: searchHistory
                          .map(
                            (item) {
                              if (item.trim().contains(filter.trim())) {
                                return item;
                              }
                              return null;
                            },
                          )
                          .where((item) => item != null)
                          .cast<String>()
                          .toList(),
                      removeItem: () async {
                        initSearchHistory();
                      },
                      search: (qry) async {
                        setState(() {
                          searchBarIsSearching.value = true;
                          searchController.value = TextEditingValue(text: qry);
                          showSearchHistory = false;
                        });
                        onFieldSubmitted(qry);
                        unfocus(focusNode);
                      },
                      changeClear: () {
                        setState(() {
                          clear = !clear;
                        });
                      },
                    ),
                  ),
                  // 4. - Search bar
                  AnimatedPositioned(
                    top: showSearchBar.value ? 0 : -100,
                    width: MediaQuery.of(context).size.width,
                    duration: const Duration(milliseconds: 500),
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
              ),
            );
          },
        );
      },
    );
  }
}

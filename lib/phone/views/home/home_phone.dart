import 'package:pongo/exports.dart';
import 'package:pongo/phone/views/home/recomendations/recomendations_phone.dart';
import 'package:pongo/phone/views/home/search%20bar/search_bar_android_phone.dart';
import 'package:pongo/phone/views/home/search%20bar/search_bar_ios_phone.dart';
import 'package:pongo/phone/views/home/search%20history/search_history_phone.dart';
import 'package:pongo/phone/views/home/search/search_phone.dart';

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
  }

  // On Field Submitted Callback Function
  void onFieldSubmitted(String qry) async {
    print(qry);
    if (qry != "") {
      print(2);
      await DatabaseHelper().insertSearchHistorySearch(qry.trim());
      await initSearchHistory();
      print(3);
      setState(() {
        print(4);
        query = qry.trim();
        print(5);
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
    print("SEARCH HISTORY: $data");
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
                    opacity: searchBarIsSearching.value ? 1 : 0,
                    duration: Duration(
                        milliseconds: searchBarIsSearching.value ? 350 : 250),
                    child: SearchPhone(
                      query: query,
                    ),
                  ),
                  // 2. - search screen
                  AnimatedPositioned(
                    duration: Duration(
                        milliseconds: searchBarIsSearching.value ? 400 : 350),
                    curve: searchBarIsSearching.value
                        ? Curves.easeInOut
                        : Curves.fastEaseInToSlowEaseOut,
                    top: searchBarIsSearching.value
                        ? MediaQuery.of(context).size.height
                        : 0,
                    child: const RecomendationsPhone(),
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
                  AnimatedPositioned(
                    top: showSearchHistory
                        ? 0
                        : -MediaQuery.of(context).size.height,
                    curve: Curves.fastEaseInToSlowEaseOut,
                    duration:
                        Duration(milliseconds: showSearchHistory ? 400 : 350),
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

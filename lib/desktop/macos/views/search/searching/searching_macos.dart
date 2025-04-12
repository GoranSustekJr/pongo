import 'package:pongo/desktop/macos/views/search/searching/searching_body_macos.dart';
import 'package:pongo/exports.dart';

class SearchingMacos extends StatefulWidget {
  final String query;
  const SearchingMacos({super.key, required this.query});

  @override
  State<SearchingMacos> createState() => _SearchingMacosState();
}

class _SearchingMacosState extends State<SearchingMacos> {
  late SearchDataManager searchDataManager;

  @override
  void initState() {
    super.initState();
    searchDataManager = SearchDataManager(context);
    searchDataManagr.value = searchDataManager;
  }

  // Listen For Query Parameter Change
  @override
  void didUpdateWidget(covariant SearchingMacos oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      // If Query Parameter Changed Do Search Function
      searchDataManager.search(widget.query);
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return ChangeNotifierProvider(
      create: (_) => searchDataManager,
      child:
          Consumer<SearchDataManager>(builder: (context, dataManager, child) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: searchDataManager.tracks.isEmpty
              ? SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  key: const ValueKey(true), // TODO: Shimmer
                )
              : SizedBox(
                  height: size.height, // Constrain height
                  width: size.width,
                  child: Scaffold(
                    extendBody: true,
                    extendBodyBehindAppBar: true,
                    backgroundColor: Col.transp,
                    body: SearchingBodyMacos(
                      tracks: searchDataManager.tracks,
                      artists: searchDataManager.artists,
                      albums: searchDataManager.albums,
                      playlists: searchDataManager.playlists,
                      loading: searchDataManager.loading,
                      scrollController: searchDataManager.scrollController,
                      suggestionHeader: TextStyle(
                        fontSize: kIsDesktop
                            ? 24
                            : kIsApple
                                ? 17
                                : 19,
                        fontWeight: kIsDesktop
                            ? FontWeight.w800
                            : kIsApple
                                ? FontWeight.w600
                                : FontWeight.w700,
                        color: Col.text,
                      ),
                      loadingAdd: (stid) {
                        setState(() {
                          if (!searchDataManager.loading.contains(stid)) {
                            searchDataManager.loading.add(stid);
                          }
                        });
                      },
                      loadingRemove: (stid) {
                        setState(() {
                          searchDataManager.loading.remove(stid);
                        });
                      },
                    ),
                  ),
                ),
        );
      }),
    );
  }
}

import 'package:pongo/exports.dart';
import 'package:pongo/phone/views/home/recomendations/recommendations%20body/recommendations_categories.dart';
import 'package:pongo/phone/views/home/recomendations/recommendations%20body/recommendations_history.dart';

class RecommendationsBodyPhone extends StatelessWidget {
  final RecommendationsDataManager dataManager;
  const RecommendationsBodyPhone({super.key, required this.dataManager});

  @override
  Widget build(BuildContext context) {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context, listen: true) as AudioServiceHandler;
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: dataManager.categoriesEnabled || dataManager.historyEnabled
          ? RefreshIndicator.adaptive(
              displacement: 25,
              edgeOffset: Scaffold.of(context).appBarMaxHeight == null
                  ? MediaQuery.of(context).padding.top +
                      AppBar().preferredSize.height
                  : Scaffold.of(context).appBarMaxHeight!,
              onRefresh: dataManager.init,
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: Scaffold.of(context).appBarMaxHeight == null
                        ? MediaQuery.of(context).padding.top +
                            AppBar().preferredSize.height +
                            20
                        : Scaffold.of(context).appBarMaxHeight! + 20,
                    bottom: MediaQuery.of(context).padding.bottom + 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      if (dataManager.history.isNotEmpty)
                        RecommendationsHistory(
                          dataManager: dataManager,
                          audioServiceHandler: audioServiceHandler,
                        ),
                      if (dataManager.categories.isNotEmpty ||
                          dataManager.newReleases.isNotEmpty)
                        RecommendationsCategories(
                          dataManager: dataManager,
                          audioServiceHandler: audioServiceHandler,
                        ),
                    ],
                  ),
                ),
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Text(
                  AppLocalizations.of(context).recommendationsdisabled,
                  style: TextStyle(
                      fontSize: 17.5,
                      fontWeight: FontWeight.w600,
                      color: Col.text),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
    );
  }
}

/* import 'package:spotify_api/spotify_api.dart' as sp;
import 'package:pongo/exports.dart';

class RecommendationsBodyPhone extends StatefulWidget {
  final List<Track> pTracks;
  final List<Artist> pArtists;
  final List<Album> pAlbums;
  final List<Playlist> pPlaylists;
  final List<Track> euTracks;
  final List<Artist> euArtists;
  final bool recommendationsDisabled;
  final Future<void> Function() onRefresh;
  const RecommendationsBodyPhone({
    super.key,
    required this.pTracks,
    required this.pArtists,
    required this.pAlbums,
    required this.pPlaylists,
    required this.euTracks,
    required this.euArtists,
    required this.recommendationsDisabled,
    required this.onRefresh,
  });

  @override
  State<RecommendationsBodyPhone> createState() =>
      _RecommendationsBodyPhoneState();
}

class _RecommendationsBodyPhoneState extends State<RecommendationsBodyPhone> {
  // Loading pongo tracks
  List<String> pTrackLoading = [];

  // Loading eu tracks
  List<String> euTrackLoading = [];

  // Suggestion header style
  final TextStyle suggestionHeader = TextStyle(
    fontSize: kIsApple ? 24 : 19,
    fontWeight: kIsApple ? FontWeight.w700 : FontWeight.w700,
    color: Colors.white,
  );
  @override
  Widget build(BuildContext context) {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context, listen: true) as AudioServiceHandler;
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: !widget.recommendationsDisabled
          ? RefreshIndicator.adaptive(
              displacement: 25,
              edgeOffset: Scaffold.of(context).appBarMaxHeight == null
                  ? MediaQuery.of(context).padding.top +
                      AppBar().preferredSize.height
                  : Scaffold.of(context).appBarMaxHeight!,
              onRefresh: widget.onRefresh,
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: Scaffold.of(context).appBarMaxHeight == null
                        ? MediaQuery.of(context).padding.top +
                            AppBar().preferredSize.height +
                            20
                        : Scaffold.of(context).appBarMaxHeight! + 20,
                    // bottom: MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      RecommendationsForYouPhone(
                        pTracks: widget.pTracks,
                        pArtists: widget.pArtists,
                        pAlbums: widget.pAlbums,
                        pPlaylists: widget.pPlaylists,
                        euTracks: widget.euTracks,
                        euArtists: widget.euArtists,
                        suggestionHeader: suggestionHeader,
                        pTrackLoading: pTrackLoading,
                        audioServiceHandler: audioServiceHandler,
                        loadingAdd: (stid) {
                          setState(() {
                            if (!pTrackLoading.contains(stid)) {
                              pTrackLoading.add(stid);
                            }
                          });
                        },
                        loadingRemove: (stid) {
                          setState(() {
                            pTrackLoading.remove(stid);
                          });
                        },
                      ),
                      RecommendedPongoPhone(
                        pTracks: widget.pTracks,
                        pArtists: widget.pArtists,
                        pAlbums: widget.pAlbums,
                        pPlaylists: widget.pPlaylists,
                        euTracks: widget.euTracks,
                        euArtists: widget.euArtists,
                        suggestionHeader: suggestionHeader,
                        pTrackLoading: pTrackLoading,
                        audioServiceHandler: audioServiceHandler,
                        loadingAdd: (stid) {
                          setState(() {
                            if (!pTrackLoading.contains(stid)) {
                              pTrackLoading.add(stid);
                            }
                          });
                        },
                        loadingRemove: (stid) {
                          setState(() {
                            pTrackLoading.remove(stid);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Text(
                  AppLocalizations.of(context)!.recommendationsdisabled,
                  style: const TextStyle(
                      fontSize: 17.5, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
    );
  }
}
 */

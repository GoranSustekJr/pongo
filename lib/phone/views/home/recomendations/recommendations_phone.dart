import 'package:pongo/exports.dart';
import 'package:pongo/phone/components/shared/shimmer/recommended_shimmer.dart';
import 'package:pongo/phone/views/home/recomendations/recommendations_data_manager.dart';

class RecommendationsPhone extends StatefulWidget {
  const RecommendationsPhone({super.key});

  @override
  State<RecommendationsPhone> createState() => _RecommendationsPhoneState();
}

class _RecommendationsPhoneState extends State<RecommendationsPhone> {
  /* // Pongo:: tracks
  List<Track> pTracks = [];

  // Pongo:: artists
  List<Artist> pArtists = [];

  // Pongo:: albums
  List<Album> pAlbums = [];

  // Pongo:: playlists
  List<Playlist> pPlaylists = [];

  // End-user:: tracks
  List<Track> euTracks = [];

  // End-user:: artists
  List<Artist> euArtists = [];

  bool recommendationsDisabled = false;

  // Show body
  bool showBody = false;

  // Show Recommendations
  /* bool recommendForYou = true;
  bool recommendedPongo = true; */
  bool historyEnabled = true;
  bool categoriesEnabled = true;

  @override
  void initState() {
    super.initState();
    getRecommendations();
  }

  Future<void> getRecommendations() async {
    // Check if user wants to get recommendations
    bool getHistory = await Storage().getEnableHistory();
    bool getCatgories = await Storage().getEnableCategories();

    setState(() {
      historyEnabled = getHistory;
      categoriesEnabled = getCatgories;
    });

    if (historyEnabled || categoriesEnabled) {
      final data = await Recommendations().get(context);
      print("DATATA;;;;;;; ${data.keys}");
    }
  } */

  /*  Future<void> getRecommendations() async {
    bool rcommendForYou = await Storage().getRecommendedForYou();
    bool rcommendPongo = await Storage().getRecommendedPongo();

    setState(() {
      recommendForYou = rcommendForYou;
      recommendedPongo = rcommendPongo;
    });

    final data = await Recommendations().get(context);

    print(data.keys);
    setState(() {
      // Pongo:: tracks

      pTracks = Track.fromMapList(data["tracks"]["tracks"]);

      // Pongo:: artists
      pArtists = (data["artists"]["artists"] as List<dynamic>).map((artist) {
        return Artist(
          id: artist["id"],
          name: artist["name"],
          image: artist["images"].isNotEmpty
              ? calculateWantedResolution(artist["images"], 300, 300)
              : "",
        );
      }).toList();

      // Pongo:: albums
      pAlbums = (data["albums"]["albums"]["items"] as List<dynamic>).isNotEmpty
          ? (data["albums"]["albums"]["items"] as List<dynamic>).map((album) {
              return Album(
                id: album["id"],
                name: album["name"],
                type: album["album_type"],
                artists: album["artists"].map((artist) {
                  return artist["name"]; //{artist["id"]: artist["name"]};
                }).toList(),
                image: calculateWantedResolution(album["images"], 300, 300),
              );
            }).toList()
          : [];

      // Pongo:: playlists
      pPlaylists = (data["playlists"]["playlists"]["items"] as List<dynamic>)
              .isNotEmpty
          ? (data["playlists"]["playlists"]["items"] as List<dynamic>)
              .map((playlist) {
              return Playlist(
                id: playlist["id"],
                name: playlist["name"],
                image: playlist["images"].isNotEmpty
                    ? calculateWantedResolution(playlist["images"], 300, 300)
                    : "",
              );
            }).toList()
          : [];

      // End-user:: tracks
      try {
        euTracks = Track.fromMapList(data["eu_tracks"]["tracks"]);

        // End-user:: artists
        euArtists =
            (data["eu_artists"]["artists"] as List<dynamic>).map((artist) {
          return Artist(
            id: artist["id"],
            name: artist["name"],
            image: artist["images"].isNotEmpty
                ? calculateWantedResolution(artist["images"], 300, 300)
                : "",
          );
        }).toList();
      } catch (e) {
        print(e);
      }
      recommendationsDisabled = pTracks.isEmpty &&
          pArtists.isEmpty &&
          pAlbums.isEmpty &&
          pPlaylists.isEmpty &&
          euArtists.isEmpty &&
          euTracks.isEmpty;

      // Show body => true
      showBody = true;
    });
  }
 */
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RecommendationsDataManager(context),
      child: Consumer<RecommendationsDataManager>(
          builder: (context, dataManager, child) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: dataManager.failed
              ? SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(AppLocalizations.of(context)!.error),
                        iconButton(
                            AppIcons.repeat, Colors.white, dataManager.init),
                      ],
                    ),
                  ),
                )
              : dataManager.showBody
                  ? RecommendationsBodyPhone(dataManager: dataManager)
                  : RecommendedShimmer(
                      history: dataManager.historyEnabled,
                      categories: dataManager.categoriesEnabled,
                    ),
        );
      }),
    );
  }
}

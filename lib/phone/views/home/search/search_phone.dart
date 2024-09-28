import 'package:pongo/exports.dart';
import 'package:pongo/phone/views/home/search/search_body_phone.dart';
import 'package:pongo/shared/utils/API%20requests/search.dart';
import 'package:spotify_api/spotify_api.dart' as sp;

class SearchPhone extends StatefulWidget {
  final String query;
  const SearchPhone({super.key, required this.query});

  @override
  State<SearchPhone> createState() => _SearchPhoneState();
}

class _SearchPhoneState extends State<SearchPhone> {
// Query
  String query = "";

  // Tracks
  List<sp.Track> tracks = [];

  // Artist
  List<Artist> artists = [];

  // Albums
  List<Album> albums = [];

  // Playlistst
  List<Playlist> playlists = [];

  // Manage Tracks That Do Not Exist
  List<String> loading = [];

  // Favourites
  List<String> favourites = [];

  // Scroll controller
  final ScrollController scrollController = ScrollController();

  // Search result header text style
  final TextStyle suggestionHeader = TextStyle(
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
    color: Colors.white,
  );

  // Search Spotify Tracks
  void search() async {
    final result = await SearchSpotify().search(context, query);

    setState(() {
      // Track
      final List<dynamic> trackItems = result["tracks"]["items"];
      tracks = trackItems.map((item) => sp.Track.fromJson(item)).toList();

      // Artist
      final List<dynamic> artistItems = result["artists"]["items"];

      // Playlists
      final List<dynamic> playlistsItems = result["playlists"]["items"];

      artists = artistItems.isNotEmpty
          ? artistItems.map((item) {
              return Artist(
                id: item["id"],
                name: item["name"],
                image: item["images"].isNotEmpty
                    ? calculateWantedResolution(item["images"], 300, 300)
                    : "",
              );
            }).toList()
          : [];

      // Albums
      final List<dynamic> albumItems = result["albums"]["items"];
      albums = albumItems.isNotEmpty
          ? albumItems.map((item) {
              return Album(
                id: item["id"],
                name: item["name"],
                type: item["album_type"],
                artists: item["artists"].map((artist) {
                  return artist["name"]; //{artist["id"]: artist["name"]};
                }).toList(),
                image: calculateWantedResolution(item["images"], 300, 300),
              );
            }).toList()
          : [];

      playlists = playlistsItems.isNotEmpty
          ? playlistsItems.map((item) {
              return Playlist(
                id: item["id"],
                name: item["name"],
                image: item["images"].isNotEmpty
                    ? calculateWantedResolution(item["images"], 300, 300)
                    : "",
                description: item["description"],
              );
            }).toList()
          : [];
    });
    for (int i = 0; i < tracks.length; i++) {
      bool exists =
          await DatabaseHelper().favouriteTrackAlreadyExists(tracks[i].id);
      if (exists) {
        setState(() {
          favourites.add(tracks[i].id);
        });
      }
    }
  }

  // Listen For Query Parameter Change
  @override
  void didUpdateWidget(covariant SearchPhone oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      // If Query Parameter Changed Do Search Function
      setState(() {
        query = widget.query;
      });
      search();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: tracks.isEmpty
          ? SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              key: const ValueKey(true), // TODO: Shimmer
            )
          : SearchBodyPhone(
              tracks: tracks,
              artists: artists,
              albums: albums,
              playlists: playlists,
              loading: loading,
              favourites: favourites,
              scrollController: scrollController,
              suggestionHeader: suggestionHeader,
              loadingAdd: (stid) {
                setState(() {
                  if (!loading.contains(stid)) {
                    loading.add(stid);
                  }
                });
              },
              loadingRemove: (stid) {
                setState(() {
                  loading.remove(stid);
                });
              },
            ),
    );
  }
}

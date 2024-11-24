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
  List<Track> tracks = [];

  // Artist
  List<Artist> artists = [];

  // Albums
  List<Album> albums = [];

  // Playlistst
  List<Playlist> playlists = [];

  // Manage Tracks That Do Not Exist
  List<String> loading = [];

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
      tracks = Track.fromMapList(trackItems);

      // Artist
      final List<dynamic> artistItems = result["artists"]["items"];

      // Playlists
      final List<dynamic> playlistsItems = result["playlists"]["items"];

      artists = artistItems.isNotEmpty ? Artist.fromMapList(artistItems) : [];

      // Albums
      final List<dynamic> albumItems = result["albums"]["items"];
      albums = albumItems.isNotEmpty ? Album.fromMapList(albumItems) : [];

      playlists =
          playlistsItems.isNotEmpty ? Playlist.fromMapList(playlistsItems) : [];
    });
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

import 'package:pongo/shared/utils/API%20requests/search.dart';
import 'package:pongo/exports.dart';

class SearchDataManager with ChangeNotifier {
  final BuildContext context;

  // Query
  String query = "";

  // Tracks
  List<Track> tracks = [];

  // Artist
  List<Artist> artists = [];

  // Albums
  List<Album> albums = [];

  // Playlists
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

  SearchDataManager(this.context);

  // Search Spotify Tracks
  Future<void> search(String searchQuery) async {
    query = searchQuery;
    final result = await SearchSpotify().search(context, query);

    // Updating the data
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

    // Notify listeners if you're using a listener-based state manager like Provider
    notifyListeners();
  }

  // Manage loading state
  void loadingAdd(String stid) {
    if (!loading.contains(stid)) {
      loading.add(stid);
      notifyListeners();
    }
  }

  void loadingRemove(String stid) {
    loading.remove(stid);
    notifyListeners();
  }
}

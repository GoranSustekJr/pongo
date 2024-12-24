import 'package:pongo/exports.dart';

class LocalPlaylistDataManager with ChangeNotifier {
  final BuildContext context;
  final int lpid;
  final String titl;
  final MemoryImage? covr;
  final String blurhsh;
  final Function(MemoryImage) updateCover;
  final Function(String) updateTitle;
  LocalPlaylistDataManager(
    this.context,
    this.lpid,
    this.titl,
    this.covr,
    this.blurhsh,
    this.updateCover,
    this.updateTitle,
  ) {
    init();
  }

  // Track stids
  List<String> stids = [];

  // Playlist data
  MemoryImage? cover;
  String title = "";
  String blurhash = "";

  // Hidden songs
  Map<String, bool> hidden = {};

  // Show body
  bool showBody = false;

  // Tracks
  List<Track> tracks = [];

  // Edit
  bool edit = false;

  // Cover image for background
  List<MemoryImage> coverImages = [];

  // Player
  List<MediaItem> mediaItem = [];

  // Length of item list
  int listLength = 0;

  // Selected tracks for editing
  List<String> selectedStids = [];

  // Manage Tracks That Do Not Exist
  List<String> loading = [];

  // Scroll controller
  late ScrollController scrollController;

  // Cancel play function
  bool cancel = false;

  // Offset
  double scrollControllerOffset = 0;

  // Tracks
  List<String> missingTracks = [];
  Map<String, double> existingTracks = {};

  // Loading shuffle
  bool loadingShuffle = false;

  // Playlist functions
  late PlaylistFunctions playlistFunctions;

  void init() async {
    cover = covr;
    title = titl;
    blurhash = blurhsh;
    scrollController = ScrollController();
    scrollController.addListener(scrollControllerListener);
  }

  scrollControllerListener() {
    if (scrollController.offset < 0) {
      scrollControllerOffset = 0;
    } else {
      scrollControllerOffset = scrollController.offset;
    }

    notifyListeners();
  }

  void getTracks() async {
    // Get tracks count in the playlist
    int len = await DatabaseHelper().queryLocalTrackIdsLengthForPlaylist(lpid);

    // Set tracks length in order to show shimmer
    listLength = len;
    notifyListeners();

    // get the stid list
    List<Map<String, dynamic>> trackss =
        await DatabaseHelper().queryLocalTracksForPlaylist(lpid);

    // init the help variables
    List<String> stidList = [];
    Map<String, bool> hiddn = {};

    tracks = Track.fromMapListLocal(trackss);

    // get the stid list from the stidss list and set the hidden status in the help variables
    /* for (var track in trackss) {
      stidList.add(track.id);
      hiddn[track.id] = (track. == 1);
    } */

    // Set states
    stids = stidList;
    hidden = hiddn;
    showBody = true;
    notifyListeners();
  }
}

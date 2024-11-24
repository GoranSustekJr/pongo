import 'package:pongo/exports.dart';

class LocalsDataManager with ChangeNotifier {
  final BuildContext context;
  LocalsDataManager(
    this.context,
  ) {
    init();
  }

  // Show body
  bool showBody = false;

  // Num of tracks
  int numOfTracks = 0;

  // Tracks
  List<Track> tracks = [];

  // Scroll controller
  ScrollController scrollController = ScrollController();

  // edit
  bool edit = false;

  // Durations
  Map<String, int> durations = {};

  // Selected track
  List<String> selectedTracks = [];

  void init() async {
    // Get the number of tracks
    int len = await DatabaseHelper().queryAllDownloadedTracksLength();

    // Set tracks length in order to show the shimmer

    numOfTracks = len;
    showBody = true;
    notifyListeners();

    // Get the tracks
    List<dynamic> trackss = await DatabaseHelper().queryAllDownloadedTracks();

    // Get the durations
    for (var track in trackss) {
      durations[track["stid"]] = track["duration"];
    }

    tracks = Track.fromMapListLocal(trackss);
    notifyListeners();
  }

  void select(String stid) {
    if (selectedTracks.contains(stid)) {
      selectedTracks.remove(stid);
    } else {
      selectedTracks.add(stid);
    }

    notifyListeners();
  }

  play({int index = 0}) async {
    PlayMultiple()
        .offlineTrack("library.locals", tracks, durations, index: index);
  }

  shuffle() async {
    PlayMultiple()
        .offlineTrack("library.locals", tracks, durations, shuffle: true);
  }
}

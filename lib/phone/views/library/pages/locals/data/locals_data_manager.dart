import 'package:pongo/exports.dart';
import 'package:pongo/phone/alerts/downloaded/downloaded.dart';

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

  // Primary key
  Map<String, int> primaryKey = {};

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
      primaryKey[track["stid"]] = track["id"];
    }

    tracks = Track.fromMapListLocal(trackss);
    notifyListeners();
  }

  // Select a track
  void select(String stid) {
    if (selectedTracks.contains(stid)) {
      selectedTracks.remove(stid);
    } else {
      selectedTracks.add(stid);
    }

    notifyListeners();
  }

  // Play
  play({int index = 0}) async {
    PlayMultiple()
        .offlineTrack("library.locals", tracks, durations, index: index);
  }

  // Shuffle
  shuffle() async {
    PlayMultiple()
        .offlineTrack("library.locals", tracks, durations, shuffle: true);
  }

  // Start editing
  startEdit() async {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context, listen: false)
            as AudioServiceHandler;
    if (audioServiceHandler.mediaItem.value != null) {
      if ("library.locals" ==
          '${audioServiceHandler.mediaItem.value!.id.split('.')[0]}.${audioServiceHandler.mediaItem.value!.id.split('.')[1]}') {
        CustomButton ok = await haltAlert(context);
        if (ok == CustomButton.positiveButton) {
          currentTrackHeight.value = 0;
          final audioServiceHandler =
              Provider.of<AudioHandler>(context, listen: false)
                  as AudioServiceHandler;

          await audioServiceHandler.halt();
          edit = true;
        }
      } else {
        edit = true;
      }
    } else {
      edit = true;
    }
    notifyListeners();
  }

  // Stop editing
  stopEdit() {
    edit = false;
    selectedTracks.clear();
    notifyListeners();
  }

  // Find new tracks ==> navigate to serach
  newTracks() {
    navigationBarIndex.value = 0;
    searchFocusNode.value.requestFocus();
  }

  // remove tracks from locals
  remove() async {
    if (selectedTracks.isNotEmpty) {
      CustomButton ok = await removeDownloadedAlert(context);
      if (ok == CustomButton.positiveButton) {
        await DatabaseHelper().removeDownloadedTracks(selectedTracks);

        tracks.clear();
        selectedTracks.clear();

        edit = false;

        init();
        notifyListeners();
      }
    }
  }

  // Select all stids
  selectAll() {
    print(selectedTracks.length != tracks.length);
    if (selectedTracks.length != tracks.length) {
      selectedTracks.clear();
      selectedTracks.addAll(tracks.map((track) => track.id));
    } else {
      selectedTracks.clear();
    }
    notifyListeners();
  }

  // sort
  sort() {
    showPullDownMenu(
      context: context,
      items: [
        PullDownMenuItem(
          onTap: () {
            tracks.sort((a, b) => a.name.compareTo(b.name));
            notifyListeners();
          },
          title: "A-Z",
        ),
        const PullDownMenuDivider(),
        PullDownMenuItem(
          onTap: () {
            tracks.sort((a, b) => b.name.compareTo(a.name));
            notifyListeners();
          },
          title: "Z-A",
        ),
        const PullDownMenuDivider(),
        PullDownMenuItem(
          onTap: () {
            tracks
                .sort((a, b) => primaryKey[a.id]!.compareTo(primaryKey[b.id]!));
            notifyListeners();
          },
          title: "First added",
        ),
        const PullDownMenuDivider(),
        PullDownMenuItem(
          onTap: () {
            tracks
                .sort((a, b) => primaryKey[b.id]!.compareTo(primaryKey[a.id]!));
            notifyListeners();
          },
          title: "Last added",
        ),
      ],
      position: RelativeRect.fromLTRB(
          MediaQuery.of(context).size.width, kToolbarHeight * 2, 0, 0),
      topWidget: const SizedBox(),
    );
  }

  // Add to playlist
  void addToPlaylist() {
    if (selectedTracks.isNotEmpty) {
      OpenPlaylist().show(
        context,
        PlaylistHandler(
          type: PlaylistHandlerType.offline,
          function: PlaylistHandlerFunction.addToPlaylist,
          track: tracks
              .where((track) => selectedTracks.contains(track.id))
              .map(
                (track) => PlaylistHandlerOfflineTrack(
                  id: track.id,
                  name: track.name,
                  artist: track.artists.map((artist) => artist.name).join(', '),
                  cover: track.image != null ? track.image!.path : "",
                  playlistHandlerCoverType: PlaylistHandlerCoverType.bytes,
                  filePath: track.image != null ? track.image!.path : "",
                ),
              )
              .toList(),
        ),
      );
    }
  }
}

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

  // Tracks backup
  List<Track> tracksBackup = [];

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

  // Search focus node
  FocusNode focusNode = FocusNode();

  // Search controller
  TextEditingController searchController = TextEditingController();

  void init() async {
    // Get the number of tracks
    int len = await DatabaseHelper().queryAllDownloadedTracksLength();

    // Get the sort
    String sort = await Storage().getLocalsSort();

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
    tracksBackup = tracks;

    if (sort == "A-Z") {
      tracks.sort((a, b) => a.name.compareTo(b.name));
    } else if (sort == "Z-A") {
      tracks.sort((a, b) => b.name.compareTo(a.name));
    } else if (sort == "First added") {
      tracks.sort((a, b) => primaryKey[a.id]!.compareTo(primaryKey[b.id]!));
    } else {
      tracks.sort((a, b) => primaryKey[b.id]!.compareTo(primaryKey[a.id]!));
    }

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
          onTap: () async {
            tracks.sort((a, b) => a.name.compareTo(b.name));
            notifyListeners();
            await Storage().writeLocalsSort("A-Z");
          },
          title: "A-Z",
        ),
        const PullDownMenuDivider(),
        PullDownMenuItem(
          onTap: () async {
            tracks.sort((a, b) => b.name.compareTo(a.name));
            notifyListeners();
            await Storage().writeLocalsSort("Z-A");
          },
          title: "Z-A",
        ),
        const PullDownMenuDivider(),
        PullDownMenuItem(
          onTap: () async {
            tracks
                .sort((a, b) => primaryKey[a.id]!.compareTo(primaryKey[b.id]!));
            notifyListeners();
            await Storage().writeLocalsSort("First added");
          },
          title: AppLocalizations.of(context)!.firstadded,
        ),
        const PullDownMenuDivider(),
        PullDownMenuItem(
          onTap: () async {
            tracks
                .sort((a, b) => primaryKey[b.id]!.compareTo(primaryKey[a.id]!));
            notifyListeners();
            await Storage().writeLocalsSort("Last added");
          },
          title: AppLocalizations.of(context)!.lastadded,
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
                  artist: track.artists
                      .map((artist) => {"id": artist.id, "name": artist.name})
                      .toList(),
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

  // On searched
  void onSearched(String value) {
    if (value.isEmpty) {
      tracks = tracksBackup;
    } else {
      final byName = tracks
          .where((track) => track.name.toLowerCase().contains(value))
          .toList();
      final byArtist = tracks
          .where((track) =>
              !byName.contains(
                  track) && // Do not include tracks are already filtered
              track.artists
                  .map((artist) => artist.name)
                  .join(', ')
                  .toLowerCase()
                  .contains(value))
          .toList();

      tracks = [...byName, ...byArtist];
    }

    notifyListeners();
  }

  // Clear the search
  clearSearch() {
    searchController.text = '';
    onSearched('');
    notifyListeners();
  }
}

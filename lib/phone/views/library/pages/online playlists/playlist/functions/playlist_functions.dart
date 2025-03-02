import 'package:pongo/exports.dart';

class PlaylistFunctions {
  final BuildContext context;
  final int opid;
  final ValueChanged<String> updateTitle;
  final ValueChanged<MemoryImage> updateCover;
  bool edit = false;
  List<String> selectedStids = [];
  Map<String, bool> hidden = {};
  bool loadingShuffle = false;
  List<Track> tracks = [];
  List<String> missingTracks = [];
  Map<String, double> existingTracks = {};
  Function(String) addLoading;
  Function(String) removeLoading;
  Function(String, double) addDuration;

  PlaylistFunctions({
    required this.context,
    required this.opid,
    required this.updateTitle,
    required this.updateCover,
    required this.addLoading,
    required this.removeLoading,
    required this.addDuration,
  });

  play({int index = 0}) async {
    if (!loadingShuffle) {
      PlayMultiple().onlineTrack(
        "online.playlist:$opid",
        tracks,
        missingTracks,
        existingTracks,
        addLoading,
        removeLoading,
        addDuration,
        index: index,
      );
    }
  }

  void playShuffle() {
    if (!loadingShuffle && missingTracks.isEmpty) {
      PlayMultiple().onlineTrack(
        "online.playlist:$opid",
        tracks,
        missingTracks,
        existingTracks,
        addLoading,
        removeLoading,
        addDuration,
        shuffle: true,
      );
    }
  }

  Future<void> move<T>(List<T> list, int currentIndex, int newIndex) async {
    if (currentIndex == newIndex) return;
    final item = list.removeAt(currentIndex);
    list.insert(newIndex, item);
  }

  void showSelected() async {
    if (selectedStids.isNotEmpty) {
      await DatabaseHelper().updateOnlinePlaylistShow(opid, selectedStids);
      // handle UI update
    }
  }

  void hideSelected() async {
    if (selectedStids.isNotEmpty) {
      await DatabaseHelper().updateOnlinePlaylistHide(opid, selectedStids);
      // handle UI update
    }
  }

  void changeTitle() async {
    newPlaylistTitle(
      context,
      opid,
      (newTitle) {
        updateTitle(newTitle);
      },
    );
  }

  void changeCover() async {
    if (edit) {
      XFile? pickedFile;
      try {
        pickedFile = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          requestFullMetadata: false,
        );
      } catch (e) {
        if (e.toString().contains("access_denied")) {
          Notifications().showWarningNotification(
            context,
            "Please allow access to the photo gallery.",
          );
          return;
        }
      }
      if (pickedFile != null) {
        CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          maxHeight: 600,
          maxWidth: 600,
          aspectRatio: const CropAspectRatio(
            ratioX: 1,
            ratioY: 1,
          ),
        );

        if (croppedFile != null) {
          Uint8List bytes = await File(croppedFile.path).readAsBytes();
          await DatabaseHelper().updateOnlinePlaylistCover(opid, bytes);
          /* final String blurHash = await BlurhashFFI.encode(
            MemoryImage(bytes),
            componentX: 3,
            componentY: 3,
          ); */
          updateCover(MemoryImage(bytes));
        }
      }
    }
  }

  void stopEdit() {
    // stop editing logic
  }

  void remove() async {
    if (selectedStids.isNotEmpty) {
      // Remove logic
    }
  }

  void addToPlaylist() {
    if (selectedStids.isNotEmpty) {
      // Add to playlist logic
    }
  }

  void select(stid) {
    // Track selection logic
  }

  void moveTrack(oldIndex, newIndex) {
    if (oldIndex == newIndex || !edit) return;
    // Move track logic
  }
}

import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:blurhash_ffi/blurhash.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:pongo/core/audio/audio_service_handler.dart';
import 'package:pongo/core/notifications/notifications.dart';
import 'package:pongo/core/state/globals.dart';
import 'package:pongo/core/storage/database/database_helper.dart';
import 'package:pongo/features/player/data/play.dart';
import 'package:pongo/features/player/presentation/phone/alerts/halt_alert.dart';
import 'package:pongo/features/playlists/data/open_playlist.dart';
import 'package:pongo/features/playlists/data/playlist_functions.dart';
import 'package:pongo/features/playlists/models/playlist_handler.dart';
import 'package:pongo/features/playlists/presentation/phone/online/change_online_playlist_name_phone.dart';
import 'package:pongo/features/playlists/presentation/phone/track_from_playlist_alert.dart';
import 'package:pongo/l10n/app_localizations.dart';
import 'package:pongo/shared/models/catalog/track.dart';

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

  // Durations
  Map<String, int> durations = {};

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
    getTracks();
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

    for (var trackk in trackss) {
      stidList.add(trackk["stid"]);
      hiddn[trackk["stid"]] = (trackk["hidden"] == 1);
      durations[trackk["stid"]] = trackk["duration"];
    }

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

  // Change the title of the local playlist function
  void changeTitle() {
    newPlaylistTitle(
      context,
      lpid,
      (newTitle) {
        title = newTitle;
        notifyListeners();
        updateTitle(newTitle);
      },
    );
  }

  // Change cover of the playlist function
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
            AppLocalizations.of(context).pleaseallowaccesstophotogalery,
          );
          return;
        }
      }
      Uint8List? bytes;

      if (pickedFile != null) {
        // Crop the image to a square
        CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          maxHeight: 600,
          maxWidth: 600,
          aspectRatio: const CropAspectRatio(
            ratioX: 1,
            ratioY: 1,
          ), // Square aspect ratio

          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: AppLocalizations.of(context).cropimage,
              toolbarColor: Colors.black,
              toolbarWidgetColor: Colors.white,
              hideBottomControls: true,
            ),
            IOSUiSettings(
              title: AppLocalizations.of(context).cropimage,
              cancelButtonTitle: AppLocalizations.of(context).cancel,
              doneButtonTitle: AppLocalizations.of(context).okey,
            ),
          ],
        );

        if (croppedFile != null) {
          bytes = await File(croppedFile.path).readAsBytes();
          if (bytes.isNotEmpty) {
            await DatabaseHelper().updateLocalPlaylistCover(lpid, bytes);
            final String blurHash = await BlurhashFFI.encode(
              MemoryImage(bytes),
              componentX: 3,
              componentY: 3,
            );

            cover = MemoryImage(bytes);
            blurhash = blurHash;

            updateCover(MemoryImage(bytes));
          }
        }
      }
    } else {
      final audioServiceHandler =
          Provider.of<AudioHandler>(context, listen: false)
              as AudioServiceHandler;
      if (audioServiceHandler.mediaItem.value != null) {
        if ("local.playlist:$lpid" ==
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
    }
    notifyListeners();
  }

  // Play
  play({int index = 0}) async {
    PlayMultiple().offlineTrack("local.playlist:$lpid",
        tracks.where((track) => hidden[track.id] == false).toList(), durations,
        index: index);
  }

  // Play shuffle
  playShuffle() async {
    PlayMultiple().offlineTrack("local.playlist:$lpid",
        tracks.where((track) => hidden[track.id] == false).toList(), durations,
        shuffle: true);
  }

  // Stop editing
  stopEdit() {
    edit = false;
    selectedStids.clear();
    notifyListeners();
  }

  // remove tracks from locals
  remove() async {
    if (selectedStids.isNotEmpty) {
      CustomButton ok = await removeTrackFromPlaylistAlert(context);
      if (ok == CustomButton.positiveButton) {
        await DatabaseHelper()
            .removeTracksFromLocalPlaylist(lpid, selectedStids, 0);

        tracks.clear();
        selectedStids.clear();

        edit = false;

        init();
        notifyListeners();
      }
    }
  }

  // Show and hide selected
  void showSelected() async {
    if (selectedStids.isNotEmpty) {
      await DatabaseHelper().updateLocalPlaylistShow(lpid, selectedStids);
      // Remove from hidden
      for (var key in hidden.keys) {
        if (selectedStids.contains(key)) {
          hidden[key] = false;
        }
      }
      selectedStids.clear();
      edit = false;
      notifyListeners();
    }
  }

  void hideSelected() async {
    if (selectedStids.isNotEmpty) {
      await DatabaseHelper().updateLocalPlaylistHide(lpid, selectedStids);
      // Add to hidden
      for (var key in hidden.keys) {
        if (selectedStids.contains(key)) {
          hidden[key] = true;
        }
      }
      selectedStids.clear();
      edit = false;
      notifyListeners();
    }
  }

  // Add to playlist
  void addToPlaylist() {
    if (selectedStids.isNotEmpty) {
      OpenPlaylist().show(
        context,
        PlaylistHandler(
          type: PlaylistHandlerType.offline,
          function: PlaylistHandlerFunction.addToPlaylist,
          track: tracks
              .where((track) => selectedStids.contains(track.id))
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
      notifyListeners();
    }
  }

  // Select track
  void select(stid) {
    if (selectedStids.contains(stid)) {
      selectedStids.remove(stid);
    } else {
      selectedStids.add(stid);
    }
    notifyListeners();
  }

  // Reorder tracks
  void moveTrack(oldIndex, newIndex) {
    if (oldIndex == newIndex) return;
    final item = tracks.removeAt(oldIndex);
    tracks.insert(
      oldIndex < newIndex ? newIndex - 1 : newIndex,
      item,
    );

    final stid = stids.removeAt(oldIndex);
    stids.insert(
      oldIndex < newIndex ? newIndex - 1 : newIndex,
      stid,
    );
    DatabaseHelper().updateLocalPlaylistOrder(lpid, stids);
    notifyListeners();
  }

  // Select all tracks
  selectAll() {
    if (selectedStids.length != tracks.length) {
      selectedStids.clear();
      selectedStids.addAll(tracks.map((track) => track.id));
    } else {
      selectedStids.clear();
    }
    notifyListeners();
  }
}

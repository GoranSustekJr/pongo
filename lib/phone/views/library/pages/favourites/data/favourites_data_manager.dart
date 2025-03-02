import 'package:pongo/exports.dart';

class FavouritesDataManager with ChangeNotifier {
  final BuildContext context;
  FavouritesDataManager(
    this.context,
  ) {
    init();
  }

  // Show body
  bool showBody = false;

  // length
  int lengthOfFavourites = 0;

  // Favourites
  List<Track> favourites = [];
  List<Map> favouritesSTIDS = [];

  // Num of songs per page
  int numb = 150;

  // No favourites

  // Edit
  bool edit = false;
  List<String> selectedTracks = [];

  // Scroll controller
  late ScrollController scrollController;

  // Offset
  double scrollControllerOffset = 0;

  // Tracks
  List<String> missingTracks = [];
  Map<String, double> existingTracks = {};

  // Loading shuffle
  bool loadingShuffle = false;

  // Cancel the getting songs
  bool cancel = false;

  // Current loading songs
  List<String> loading = [];

  void init() async {
    scrollController = ScrollController();
    scrollController.addListener(scrollControllerListener);

    initFavourites();

    notifyListeners();
  }

  // If scrolled to bottom, get new tracks
  scrollControllerListener() {
    if (scrollController.offset < 0) {
      scrollControllerOffset = 0;
    } else {
      scrollControllerOffset = scrollController.offset;
    }
    if (scrollController.position.maxScrollExtent == scrollController.offset &&
        favouritesSTIDS.length > favourites.length) {
      fetchTracks((favourites.length / numb).floor() + 1);
    }

    notifyListeners();
  }

  // Fetch next set of tracks
  void fetchTracks(int index) async {
    final start = numb * (index - 1);
    final end = (start + numb) <= favouritesSTIDS.length
        ? (start + numb)
        : favouritesSTIDS.length;

    // Ensure the indices are within valid bounds
    if (start < 0 || start >= favouritesSTIDS.length) return;

    List<String> tempStids = favouritesSTIDS
        .map((entry) => entry["stid"].toString())
        .toList()
        .sublist(start, end);

    final trackData = await SearializedData().tracks(
      context,
      tempStids,
    );

    final List<dynamic> page = trackData["tracks"]["tracks"];

    final trackThatExist = await Tracks().getDurations(
      context,
      favouritesSTIDS
          .map((entry) => entry["stid"].toString())
          .toList()
          .sublist(start, end),
    );
    final List<Track> newTracks =
        page.map((item) => Track.fromMap(item)).toList();

    // Add tracks to favourites list and update
    favourites.addAll(newTracks);
    existingTracks.addAll({
      for (var item in trackThatExist["durations"])
        item[0] as String: item[1] as double
    });
    missingTracks.addAll((trackThatExist["missing_tracks"] as List)
        .map((item) => item.toString()));

    newMediaItems(newTracks);
  }

  // Insert new media items
  void newMediaItems(List<Track> newTracks) async {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context, listen: false)
            as AudioServiceHandler;

    if (audioServiceHandler.mediaItem.value != null) {
      if ('${audioServiceHandler.mediaItem.value!.id.split('.')[0]}.${audioServiceHandler.mediaItem.value!.id.split('.')[1]}' ==
          "library.favourites") {
        bool reEnableShuffleMode =
            audioServiceHandler.audioPlayer.shuffleModeEnabled;
        audioServiceHandler.setShuffleMode(AudioServiceShuffleMode.none);
        if (missingTracks.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            TrackPlay().playConcenating(
              context,
              newTracks,
              existingTracks,
              "library.favourites.",
              cancel,
              (stid) {
                if (!loading.contains(stid)) {
                  loading.add(stid);
                }
              },
              (stid) {
                loading.remove(stid);
                missingTracks.remove(stid);
              },
              (mediaItem, i) async {
                await audioServiceHandler.playlist
                    .add(audioServiceHandler.createAudioSource(mediaItem));
                audioServiceHandler.queue.value.add(mediaItem);
              },
            );
          });
        } else {
          final data = await Tracks().getDurations(
              context, newTracks.map((track) => track.id).toList());

          if (data["durations"] != null) {
            existingTracks.addAll({
              for (var item in data["durations"])
                item[0] as String: item[1] as double
            });
          }
          final List<MediaItem> mediaItems = [];

          for (int i = 0; i < newTracks.length; i++) {
            final MediaItem mediaItem = MediaItem(
              id: "library.newTracks.${newTracks[i].id}",
              title: newTracks[i].name,
              artist:
                  favourites[i].artists.map((artist) => artist.name).join(', '),
              album: newTracks[i].album != null
                  ? "${newTracks[i].album!.id}..Ææ..${newTracks[i].album!.name}"
                  : "..Ææ..",
              duration: Duration(
                  milliseconds:
                      (existingTracks[newTracks[i].id]! * 1000).toInt()),
              artUri: favourites[i].album != null
                  ? Uri.parse(
                      calculateBestImageForTrack(favourites[i].album!.images))
                  : null,
              extras: {
                "artists": jsonEncode(favourites[i]
                    .artists
                    .map((artist) => {"id": artist.id, "name": artist.name})
                    .toList()),
                "released": newTracks[i].album != null
                    ? newTracks[i].album!.releaseDate
                    : "",
              },
            );
            mediaItems.add(mediaItem);
          }

          audioServiceHandler.queue.value.addAll(mediaItems);
          audioServiceHandler.playlist.addAll(
              mediaItems.map(audioServiceHandler.createAudioSource).toList());
        }
        if (reEnableShuffleMode) {
          audioServiceHandler.setShuffleMode(AudioServiceShuffleMode.all);
        }
      }
    }

    notifyListeners();
  }

  // Initialize the favourites data
  void initFavourites() async {
    final int length = await DatabaseHelper().queryFavouritesLength();

    lengthOfFavourites = length;
    showBody = true;

    final stids = await DatabaseHelper().queryAllFavouriteTracks();

    favouritesSTIDS = stids;
    fetchTracks(1);

    notifyListeners();
  }

  // Download track/playlist
  void download() async {
    if (selectedTracks.isNotEmpty) {
      // Get the tracks that need to be downloaded
      List<String> toDownload =
          await DatabaseHelper().queryMissingStids(selectedTracks);

      // Open playlist helper and add them to a playlist or create a new playlist
      OpenPlaylist().show(
        context,
        PlaylistHandler(
          toDownload: toDownload,
          type: PlaylistHandlerType.offline,
          function: PlaylistHandlerFunction.addToPlaylist,
          track: favourites
              .where((track) => selectedTracks.contains(track.id))
              .map(
            (track) {
              return PlaylistHandlerOnlineTrack(
                id: track.id,
                name: track.name,
                artist: track.artists
                    .map((artist) => {"id": artist.id, "name": artist.name})
                    .toList(),
                cover: calculateBestImageForTrack(
                  track.album!.images,
                ),
                playlistHandlerCoverType: PlaylistHandlerCoverType.url,
              );
            },
          ).toList(),
        ),
      );
    }
  }

  // play
  play({int? index}) async {
    if (!edit) {
      if (!loadingShuffle) {
        final audioServiceHandler =
            Provider.of<AudioHandler>(context, listen: false)
                as AudioServiceHandler;
        // Set shuffle mode
        await audioServiceHandler.setShuffleMode(AudioServiceShuffleMode.none);

        // Set global id of the playlist
        currentAlbumPlaylistId.value = "library.favourites.";

        if (missingTracks.isNotEmpty) {
          queueAllowShuffle.value = false;

          cancel = true;
          await audioServiceHandler.halt();

          cancel = false;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            //  op:${widget.opid}.$stid
            TrackPlay().playConcenating(
              context,
              favourites,
              existingTracks,
              "library.favourites.",
              cancel,
              (stid) {
                if (!loading.contains(stid)) {
                  loading.add(stid);
                }
              },
              (stid) {
                loading.remove(stid);
                missingTracks.remove(stid);
              },
              (mediaItem, i) async {
                if (i == 0) {
                  await audioServiceHandler.initSongs(songs: [mediaItem]);
                  audioServiceHandler.play();
                } else {
                  await audioServiceHandler.playlist
                      .add(audioServiceHandler.createAudioSource(mediaItem));
                  audioServiceHandler.queue.value.add(mediaItem);
                }
                if (i == favourites.length - 1) {
                  queueAllowShuffle.value = true;
                }
              },
            );
          });
        } else {
          final data = await Tracks().getDurations(context, missingTracks);

          if (data["durations"] != null) {
            existingTracks.addAll({
              for (var item in data["durations"])
                item[0] as String: item[1] as double
            });
          }

          final List<MediaItem> mediaItems = [];

          final audioServiceHandler =
              Provider.of<AudioHandler>(context, listen: false)
                  as AudioServiceHandler;

          for (int i = 0; i < favourites.length; i++) {
            final MediaItem mediaItem = MediaItem(
              id: "library.favourites.${favourites[i].id}",
              title: favourites[i].name,
              artist:
                  favourites[i].artists.map((artist) => artist.name).join(', '),
              album: favourites[i].album != null
                  ? "${favourites[i].album!.id}..Ææ..${favourites[i].album!.name}"
                  : "..Ææ..",
              duration: Duration(
                  milliseconds:
                      (existingTracks[favourites[i].id]! * 1000).toInt()),
              artUri: favourites[i].album != null
                  ? Uri.parse(
                      calculateBestImageForTrack(favourites[i].album!.images))
                  : null,
              extras: {
                //"blurhash": blurHash,
                "artists": jsonEncode(favourites[i]
                    .artists
                    .map((artist) => {"id": artist.id, "name": artist.name})
                    .toList()),
                "released": favourites[i].album != null
                    ? favourites[i].album!.releaseDate
                    : "",
              },
            );
            mediaItems.add(mediaItem);
          }

          await audioServiceHandler.initSongs(songs: mediaItems);

          await audioServiceHandler.skipToQueueItem(index!);
          audioServiceHandler.play();
        }
      }
    }
    notifyListeners();
  }

  // Play with shuffle
  playShuffle() async {
    if (!loadingShuffle && missingTracks.isEmpty && !edit) {
      queueAllowShuffle.value = true;

      loadingShuffle = true;

      // Set global id of the playlist
      final data = await Tracks().getDurations(context, missingTracks);
      if (data["durations"] != null) {
        existingTracks.addAll({
          for (var item in data["durations"])
            item[0] as String: item[1] as double
        });
      }

      final List<MediaItem> mediaItems = [];

      final audioServiceHandler =
          Provider.of<AudioHandler>(context, listen: false)
              as AudioServiceHandler;
      await audioServiceHandler.setShuffleMode(AudioServiceShuffleMode.all);

      for (int i = 0; i < favourites.length; i++) {
        final MediaItem mediaItem = MediaItem(
          id: "library.favourites.${favourites[i].id}",
          title: favourites[i].name,
          artist: favourites[i].artists.map((artist) => artist.name).join(', '),
          album: favourites[i].album != null
              ? "${favourites[i].album!.id}..Ææ..${favourites[i].album!.name}"
              : "..Ææ..",
          duration: Duration(
              milliseconds: (existingTracks[favourites[i].id]! * 1000).toInt()),
          artUri: favourites[i].album != null
              ? Uri.parse(
                  calculateBestImageForTrack(favourites[i].album!.images))
              : null,
          extras: {
            "artists": jsonEncode(favourites[i]
                .artists
                .map((artist) => {"id": artist.id, "name": artist.name})
                .toList()),
            "released": favourites[i].album != null
                ? favourites[i].album!.releaseDate
                : "",
          },
        );
        mediaItems.add(mediaItem);
      }

      await audioServiceHandler.initSongs(songs: mediaItems);
      await audioServiceHandler
          .skipToQueueItem(audioServiceHandler.audioPlayer.shuffleIndices![0]);
      audioServiceHandler.play();

      loadingShuffle = false;
    }

    notifyListeners();
  }
}

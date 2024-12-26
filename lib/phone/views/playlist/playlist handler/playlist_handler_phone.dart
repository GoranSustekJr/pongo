import 'dart:ui';
import 'package:pongo/exports.dart';
import 'package:pongo/phone/views/playlist/playlist%20handler/playlist_handler_body_phone.dart';
import 'package:http/http.dart' as http;

class PlaylistHandlerPhone extends StatefulWidget {
  final PlaylistHandler playlistHandler;
  const PlaylistHandlerPhone({super.key, required this.playlistHandler});

  @override
  State<PlaylistHandlerPhone> createState() => _PlaylistHandlerPhoneState();
}

class _PlaylistHandlerPhoneState extends State<PlaylistHandlerPhone> {
  // Show create playlist screen
  bool showCreatePlaylist = false;

  // Current Playlists
  List currentPlaylists = [];
  List<MemoryImage?> currentPlaylistsCoverImages = []; // Playlist cover image
  Map playlistTrackMap = {}; // Map of tracks for every playlist

  // New playlist data
  dynamic newPlaylistCover;
  TextEditingController titleController = TextEditingController();

  // Selected playlists
  List<int> selectedPlaylists = [];

  // Online playlist
  bool onlinePlaylist = false;

  @override
  void initState() {
    super.initState();
    initData();
  }

  void initData() {
    // init playlists
    if (widget.playlistHandler.function !=
        PlaylistHandlerFunction.createPlaylist) {
      initPlaylists();
    } else {
      setState(() {
        showCreatePlaylist = false;
      });
    }

    if (widget.playlistHandler.function ==
        PlaylistHandlerFunction.createPlaylist) {
      initNewPlaylist();
    }
  }

  void initPlaylists() async {
    if (widget.playlistHandler.type == PlaylistHandlerType.online) {
      // If adding an online track
      // Get online playlists
      final playlsts = await DatabaseHelper().queryAllOnlinePlaylists();

      // Extract ids
      final opids = playlsts.map((playlist) => playlist["opid"]).toList();

      // get all of theyre current tracks
      Map plylistTrackMap = {};
      for (int opid in opids) {
        final tracks =
            await DatabaseHelper().queryOnlineTrackIdsForPlaylist(opid);
        print(tracks);
        plylistTrackMap[opid] = tracks.map((track) => {
              "id": track["opid"],
              "track_id": track["track_id"],
            });
      }

      // Set all to a widget state variable
      setState(() {
        currentPlaylists = playlsts
            .map((playlist) => {
                  "id": playlist["opid"],
                  "title": playlist["title"],
                  "cover": playlist["cover"],
                })
            .toList();
        currentPlaylistsCoverImages = playlsts
            .map((playlist) => playlist["cover"] != null
                ? MemoryImage(playlist["cover"])
                : null)
            .toList();
        playlistTrackMap = plylistTrackMap;
      });
    } else {
      // If adding an online track
      // Get local playlists
      final playlsts = await DatabaseHelper().queryAllLocalPlaylists();

      // Extract ids
      final lpids = playlsts.map((playlist) => playlist["lpid"]).toList();

      // get all of theyre current tracks
      Map plylistTrackMap = {};
      for (int lpid in lpids) {
        final tracks =
            await DatabaseHelper().queryLocalTrackIdsForPlaylist(lpid);
        plylistTrackMap[lpid] = tracks;
      }

      // Set all to a widget state variable
      setState(() {
        currentPlaylists = playlsts
            .map((playlist) => {
                  "id": playlist["lpid"],
                  "title": playlist["title"],
                  "cover": playlist["cover"],
                })
            .toList();
        currentPlaylistsCoverImages = playlsts
            .map((playlist) => playlist["cover"] != null
                ? MemoryImage(playlist["cover"])
                : null)
            .toList();
        playlistTrackMap = plylistTrackMap;
      });
    }
  }

  void initNewPlaylist() {
    setState(() {
      if (widget.playlistHandler.track != null) {
        if (widget.playlistHandler.track!.isNotEmpty) {
          print("Dubre; ${widget.playlistHandler.track}");
          newPlaylistCover = widget.playlistHandler.track![0].cover;
        }
      }
    });
  }

  pickImage() async {
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
          AppLocalizations.of(context)!.pleaseallowaccesstophotogalery,
        );
        return;
      }
    }

    if (pickedFile != null) {
      // Crop the image to a square
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        maxHeight: 500,
        maxWidth: 500,
        aspectRatio: const CropAspectRatio(
          ratioX: 1,
          ratioY: 1,
        ), // Square aspect ratio

        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: AppLocalizations.of(context)!.cropimage,
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            hideBottomControls: true,
          ),
          IOSUiSettings(
            title: AppLocalizations.of(context)!.cropimage,
            cancelButtonTitle: AppLocalizations.of(context)!.cancel,
            doneButtonTitle: AppLocalizations.of(context)!.okey,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          newPlaylistCover = File(croppedFile.path);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.5, sigmaY: 12.5),
        child: Container(
          height: size.height,
          width: size.width,
          color: Colors.black.withAlpha(75),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: Scaffold(
              key: ValueKey(widget.playlistHandler),
              resizeToAvoidBottomInset: false,
              extendBodyBehindAppBar: true,
              extendBody: true,
              appBar: AppBar(),
              body: PlaylistHandlerBodyPhone(
                playlistHandlerTracks: widget.playlistHandler.track,
                createPlaylistFunction: () async {
                  if (titleController.value.text.trim() != "") {
                    List<Map> titless =
                        await DatabaseHelper().queryAllOnlinePlaylistsTitles();
                    List<String> titles = titless
                        .map((title) => title["title"] as String)
                        .toList();

                    if (!titles.contains(titleController.value.text.trim())) {
                      // If adding and creating
                      if (widget.playlistHandler.track != null) {
                        print(newPlaylistCover);
                        Uint8List? bytes = newPlaylistCover != null
                            ? newPlaylistCover.runtimeType == String
                                ? newPlaylistCover
                                        .toString()
                                        .contains('file:///')
                                    ? await File.fromUri(
                                            Uri.parse(newPlaylistCover))
                                        .readAsBytes()
                                    : (await http
                                            .get(Uri.parse(newPlaylistCover)))
                                        .bodyBytes
                                : await newPlaylistCover.readAsBytes()
                            : null;
                        if (widget.playlistHandler.type ==
                            PlaylistHandlerType.online) {
                          int opid = await DatabaseHelper()
                              .insertOnlinePlaylist(
                                  titleController.value.text.trim(), bytes);
                          if (widget.playlistHandler.track != null) {
                            if (widget.playlistHandler.track!.isEmpty) {
                              playlistHandler.value = null;
                            } else {
                              for (int i = 0;
                                  i < widget.playlistHandler.track!.length;
                                  i++) {
                                await DatabaseHelper().insertOnlineTrackId(
                                    opid, widget.playlistHandler.track![i].id);
                                if (i ==
                                    widget.playlistHandler.track!.length - 1) {
                                  playlistHandler.value = null;
                                }
                              }
                            }
                          }
                        } else {
                          int lpid = await DatabaseHelper().insertLocalPlaylist(
                              titleController.value.text.trim(), bytes);
                          if (widget.playlistHandler.track != null) {
                            if (widget.playlistHandler.track!.isEmpty) {
                              playlistHandler.value = null;
                            } else {
                              for (int i = 0;
                                  i < widget.playlistHandler.track!.length;
                                  i++) {
                                await DatabaseHelper().insertLocalTrackId(
                                    lpid, widget.playlistHandler.track![i].id);
                                if (i ==
                                    widget.playlistHandler.track!.length - 1) {
                                  print("object");
                                  playlistHandler.value = null;
                                }
                              }
                            }
                          }
                        }
                      }
                    } else {
                      Notifications().showWarningNotification(
                          context,
                          AppLocalizations.of(context)!
                              .playlistnamealreadyexists);
                    }
                  }
                },
                titleController: titleController,
                addTracksToPlalists: () async {
                  if (widget.playlistHandler.type ==
                      PlaylistHandlerType.online) {
                    for (int opid in selectedPlaylists) {
                      if (widget.playlistHandler.track!.length == 1) {
                        await DatabaseHelper().insertOnlineTrackId(
                            opid, widget.playlistHandler.track![0].id);
                      } else {
                        for (var track in widget.playlistHandler.track!) {
                          await DatabaseHelper()
                              .insertOnlineTrackId(opid, track.id);
                        }
                      }
                    }
                  } else {
                    for (int opid in selectedPlaylists) {
                      if (widget.playlistHandler.track!.length == 1) {
                        await DatabaseHelper().insertLocalTrackId(
                            opid, widget.playlistHandler.track![0].id);
                      } else {
                        for (var track in widget.playlistHandler.track!) {
                          await DatabaseHelper()
                              .insertLocalTrackId(opid, track.id);
                        }
                      }
                    }
                  }
                  playlistHandler.value = null;
                },
                newPlaylistCover: newPlaylistCover,
                currentPlaylists: currentPlaylists,
                currentPlaylistsCoverImages: currentPlaylistsCoverImages,
                selectedPlaylists: selectedPlaylists,
                playlistTrackMap: playlistTrackMap,

                showCreatePlaylist: showCreatePlaylist ||
                    playlistHandler.value!.function ==
                        PlaylistHandlerFunction
                            .createPlaylist, // When not on create playlist page
                onlyCreatePlaylist: playlistHandler.value!.function ==
                    PlaylistHandlerFunction
                        .createPlaylist, // When not only showing the create playlist page
                changeCreatePlaylist: () {
                  setState(() {
                    showCreatePlaylist = !showCreatePlaylist;
                  });
                },
                selectPlaylist: (playlist) {
                  setState(() {
                    if (selectedPlaylists.contains(playlist)) {
                      selectedPlaylists.remove(playlist);
                    } else {
                      selectedPlaylists.add(playlist);
                    }
                  });
                },
                pickImage: () async {
                  await pickImage();
                },
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
  }
}

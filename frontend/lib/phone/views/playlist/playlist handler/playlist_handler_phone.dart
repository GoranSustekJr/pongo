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

  // Working
  bool working = false;

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
            await DatabaseHelper().queryOnlineTracksForPlaylist(opid);
        plylistTrackMap[opid] = tracks.map((track) => {
              "id": track.opid,
              "track_id": track.stid,
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
          AppLocalizations.of(context).pleaseallowaccesstophotogalery,
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
        filter: ImageFilter.blur(
            sigmaX: useBlur.value ? 12.5 : 0, sigmaY: useBlur.value ? 12.5 : 0),
        child: Container(
          height: size.height,
          width: size.width,
          color: useBlur.value
              ? Colors.black.withAlpha(75)
              : Col.realBackground.withAlpha(225),
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
                working: working,
                createPlaylistFunction: () async {
                  if (!working) {
                    setState(() {
                      working = true;
                    });
                    if (titleController.value.text.trim() != "") {
                      List<Map> titless = [];
                      if (widget.playlistHandler.type ==
                          PlaylistHandlerType.online) {
                        titless = await DatabaseHelper()
                            .queryAllOnlinePlaylistsTitles();
                      } else {
                        titless = await DatabaseHelper()
                            .queryAllLocalPlaylistsTitles();
                      }
                      List<String> titles = titless
                          .map((title) => title["title"] as String)
                          .toList();
                      bool titleDoesntExist =
                          !titles.contains(titleController.value.text.trim());

                      if (titleDoesntExist) {
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

                        // If adding and creating
                        if (widget.playlistHandler.track != null) {
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
                                      OnlinePlaylistTrack(
                                          opid: opid,
                                          stid: widget
                                              .playlistHandler.track![i].id,
                                          title: widget
                                              .playlistHandler.track![i].name,
                                          artistTrack: widget
                                              .playlistHandler.track![i].artist
                                              .map((artistTrack) =>
                                                  ArtistTrack.fromMap(
                                                      artistTrack))
                                              .toList(),
                                          albumTrack: (widget
                                                      .playlistHandler.track![i]
                                                  as PlaylistHandlerOnlineTrack)
                                              .albumTrack,
                                          image: widget
                                              .playlistHandler.track![i].cover,
                                          orderNumber: -1,
                                          hidden: false));
                                  if (i ==
                                      widget.playlistHandler.track!.length -
                                          1) {
                                    playlistHandler.value = null;
                                  }
                                }
                              }
                            }
                          } else {
                            if (widget.playlistHandler.toDownload.isEmpty) {
                              int lpid = await DatabaseHelper()
                                  .insertLocalPlaylist(
                                      titleController.value.text.trim(), bytes);
                              if (widget.playlistHandler.track != null) {
                                if (widget.playlistHandler.track!.isEmpty) {
                                  playlistHandler.value = null;
                                } else {
                                  for (int i = 0;
                                      i < widget.playlistHandler.track!.length;
                                      i++) {
                                    await DatabaseHelper().insertLocalTrackId(
                                        lpid,
                                        widget.playlistHandler.track![i].id);
                                    if (i ==
                                        widget.playlistHandler.track!.length -
                                            1) {
                                      playlistHandler.value = null;
                                    }
                                  }
                                }
                              }
                            } else {
                              try {
                                // Download and add
                                Notifications().showSpecialNotification(
                                    context,
                                    AppLocalizations.of(context).downloading,
                                    AppLocalizations.of(context)
                                        .downloadhasstarted,
                                    AppIcons.download);

                                final downloaded = await Download().playlist(
                                    context, widget.playlistHandler.toDownload);

                                if (downloaded.isNotEmpty) {
                                  for (String stid in downloaded.keys) {
                                    PlaylistHandlerTrack track = widget
                                        .playlistHandler.track!
                                        .where((track) => track.id == stid)
                                        .first;
                                    await Download().singleWithoutAPI(
                                      stid,
                                      base64Decode(downloaded[stid][1]),
                                      downloaded[stid][0],
                                      track.cover,
                                      track.name,
                                      track.artist,
                                    );
                                  }
                                  // Add the tracks
                                  int lpid = await DatabaseHelper()
                                      .insertLocalPlaylist(
                                          titleController.value.text.trim(),
                                          bytes);
                                  if (widget.playlistHandler.track!.length ==
                                      1) {
                                    await DatabaseHelper().insertLocalTrackId(
                                        lpid,
                                        widget.playlistHandler.track![0].id);
                                  } else {
                                    for (var track
                                        in widget.playlistHandler.track!) {
                                      await DatabaseHelper()
                                          .insertLocalTrackId(lpid, track.id);
                                    }
                                  }

                                  // Notify the user
                                  Notifications().showSpecialNotification(
                                      context,
                                      AppLocalizations.of(context).successful,
                                      AppLocalizations.of(context)
                                          .downloadsucceeded,
                                      AppIcons.download);
                                }
                              } catch (e) {
                                Notifications().showSpecialNotification(
                                    context,
                                    AppLocalizations.of(context).error,
                                    AppLocalizations.of(context).downloadfailed,
                                    AppIcons.warning);
                              }
                            }
                          }
                        } else {
                          if (widget.playlistHandler.type ==
                              PlaylistHandlerType.online) {
                            await DatabaseHelper().insertOnlinePlaylist(
                                titleController.value.text.trim(), bytes);
                          } else {
                            await DatabaseHelper().insertLocalPlaylist(
                                titleController.value.text.trim(), bytes);
                          }
                        }
                        playlistHandler.value = null;
                      } else {
                        Notifications().showWarningNotification(
                            context,
                            AppLocalizations.of(context)
                                .playlistnamealreadyexists);
                      }
                    } else {
                      setState(() {
                        working = false;
                      });
                    }
                  }
                },
                titleController: titleController,
                addTracksToPlalists: () async {
                  if (!working && selectedPlaylists.isNotEmpty) {
                    setState(() {
                      working = true;
                    });
                    if (widget.playlistHandler.type ==
                        PlaylistHandlerType.online) {
                      for (int opid in selectedPlaylists) {
                        if (widget.playlistHandler.track!.length == 1) {
                          await DatabaseHelper().insertOnlineTrackId(
                              OnlinePlaylistTrack(
                                  opid: opid,
                                  stid: widget.playlistHandler.track![0].id,
                                  title: widget.playlistHandler.track![0].name,
                                  artistTrack: widget
                                      .playlistHandler.track![0].artist
                                      .map((artistTrack) =>
                                          ArtistTrack.fromMap(artistTrack))
                                      .toList(),
                                  albumTrack: (widget.playlistHandler.track![0]
                                          as PlaylistHandlerOnlineTrack)
                                      .albumTrack,
                                  image: widget.playlistHandler.track![0].cover,
                                  orderNumber: -1,
                                  hidden: false));
                        } else {
                          for (var track in widget.playlistHandler.track!) {
                            await DatabaseHelper().insertOnlineTrackId(
                                OnlinePlaylistTrack(
                                    opid: opid,
                                    stid: track.id,
                                    title: track.name,
                                    artistTrack: widget
                                        .playlistHandler.track![0].artist
                                        .map((artistTrack) =>
                                            ArtistTrack.fromMap(artistTrack))
                                        .toList(),
                                    albumTrack:
                                        (track as PlaylistHandlerOnlineTrack)
                                            .albumTrack,
                                    image: track.cover,
                                    orderNumber: -1,
                                    hidden: false));
                          }
                        }
                      }
                    } else {
                      if (widget.playlistHandler.toDownload.isEmpty) {
                        for (int lpid in selectedPlaylists) {
                          if (widget.playlistHandler.track!.length == 1) {
                            await DatabaseHelper().insertLocalTrackId(
                                lpid, widget.playlistHandler.track![0].id);
                          } else {
                            for (var track in widget.playlistHandler.track!) {
                              await DatabaseHelper()
                                  .insertLocalTrackId(lpid, track.id);
                            }
                          }
                        }
                      } else {
                        try {
                          // Download and add
                          Notifications().showSpecialNotification(
                              context,
                              AppLocalizations.of(context).downloading,
                              AppLocalizations.of(context).downloadhasstarted,
                              AppIcons.download);

                          final downloaded = await Download().playlist(
                              context, widget.playlistHandler.toDownload);

                          if (downloaded.isNotEmpty) {
                            for (String stid in downloaded.keys) {
                              PlaylistHandlerTrack track = widget
                                  .playlistHandler.track!
                                  .where((track) => track.id == stid)
                                  .first;
                              await Download().singleWithoutAPI(
                                stid,
                                base64Decode(downloaded[stid][1]),
                                downloaded[stid][0],
                                track.cover,
                                track.name,
                                track.artist,
                              );
                            }
                            // Add the tracks
                            for (int opid in selectedPlaylists) {
                              if (widget.playlistHandler.track!.length == 1) {
                                await DatabaseHelper().insertLocalTrackId(
                                    opid, widget.playlistHandler.track![0].id);
                              } else {
                                for (var track
                                    in widget.playlistHandler.track!) {
                                  await DatabaseHelper()
                                      .insertLocalTrackId(opid, track.id);
                                }
                              }
                            }

                            // Notify the user
                            Notifications().showSpecialNotification(
                                context,
                                AppLocalizations.of(context).successful,
                                AppLocalizations.of(context).downloadsucceeded,
                                AppIcons.download);
                          }
                        } catch (e) {
                          Notifications().showSpecialNotification(
                              context,
                              AppLocalizations.of(context).error,
                              AppLocalizations.of(context).downloadfailed,
                              AppIcons.warning);
                        }
                      }
                    }
                    playlistHandler.value = null;
                  }
                },
                newPlaylistCover: newPlaylistCover,
                currentPlaylists: currentPlaylists,
                currentPlaylistsCoverImages: currentPlaylistsCoverImages,
                selectedPlaylists: selectedPlaylists,
                playlistTrackMap: playlistTrackMap,

                showCreatePlaylist: showCreatePlaylist ||
                    playlistHandler.value?.function ==
                        PlaylistHandlerFunction
                            .createPlaylist, // When not on create playlist page
                onlyCreatePlaylist: playlistHandler.value?.function ==
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

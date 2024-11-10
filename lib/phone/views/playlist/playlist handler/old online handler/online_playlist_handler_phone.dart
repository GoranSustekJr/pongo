import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pongo/exports.dart';
import 'package:pongo/phone/components/shared/playing%20details/controls.dart';
import 'package:pongo/phone/views/playlist/playlist%20handler/old%20online%20handler/online_playlist_handler_body_phone.dart';
import 'package:http/http.dart' as http;

class OnlinePlaylistHandlerPhone extends StatefulWidget {
  const OnlinePlaylistHandlerPhone({super.key});

  @override
  State<OnlinePlaylistHandlerPhone> createState() =>
      _OnlinePlaylistHandlerPhoneState();
}

class _OnlinePlaylistHandlerPhoneState
    extends State<OnlinePlaylistHandlerPhone> {
  // Create new playlist boolean
  bool createPlaylist = false;

  // New playlist
  TextEditingController titleController = TextEditingController();
  File? cover;
  Uint8List? coverBytes;
  bool redIt = false;

  // Playlists
  List playlists = [];

  // Cover image for background
  List<MemoryImage?> coverImages = [];

  // Map of tracks for every playlist
  Map playlistTrackMap = {};

  // Selected playlist
  List<int> selectedPlaylists = [];

  @override
  void initState() {
    super.initState();
    initPlaylists();
  }

  void initPlaylists() async {
    final playlsts = await DatabaseHelper().queryAllOnlinePlaylists();
    final opids = playlsts.map((playlist) => playlist["opid"]).toList();
    Map plylistTrackMap = {};
    for (int opid in opids) {
      final tracks =
          await DatabaseHelper().queryOnlineTrackIdsForPlaylist(opid);
      plylistTrackMap[opid] = tracks;
    }

    setState(() {
      playlists = playlsts;
      coverImages = playlists
          .map((playlist) =>
              playlist["cover"] != null ? MemoryImage(playlist["cover"]) : null)
          .toList();
      playlistTrackMap = plylistTrackMap;
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
        Uint8List bytes = await File(croppedFile.path).readAsBytes();

        setState(() {
          cover = File(croppedFile.path);
          coverBytes = bytes;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return ValueListenableBuilder(
        valueListenable: playlistTrackToAddData,
        builder: (context, value, child) {
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
                    key: ValueKey(playlistTrackToAddData.value),
                    resizeToAvoidBottomInset: false,
                    extendBodyBehindAppBar: true,
                    extendBody: true,
                    appBar: AppBar(),
                    body: OnlinePlaylistHandlerBodyPhone(
                      titleController: titleController,
                      redIt: redIt,
                      createPlaylist: createPlaylist,
                      playlists: playlists,
                      selectedPlaylists: selectedPlaylists,
                      coverImages: coverImages,
                      cover: cover,
                      coverBytes: coverBytes,
                      playlistTrackMap: playlistTrackMap,
                      pickImage: () async {
                        await pickImage();
                      },
                      onChanged: (value) {
                        /* setState(() {
                          titleController.value = value.trim();
                        }); */
                      },
                      createPlaylistFunction: () async {
                        if (titleController.value.text.trim() != "") {
                          List<Map> titless = await DatabaseHelper()
                              .queryAllOnlinePlaylistsTitles();
                          List<String> titles = titless
                              .map((title) => title["title"] as String)
                              .toList();
                          if (!titles
                              .contains(titleController.value.text.trim())) {
                            if (playlistTrackToAddData.value != null
                                ? playlistTrackToAddData.value!["playlist"] !=
                                    null
                                : true) {
                              dynamic bytes;
                              if (playlistTrackToAddData.value!["cover"] !=
                                  null) {
                                bytes = await http.get(Uri.parse(
                                    playlistTrackToAddData.value!["cover"]));
                              }
                              Uint8List? img;
                              if (bytes != null) {
                                img = bytes.bodyBytes;
                              } else if (coverBytes != null) {
                                img = coverBytes;
                              }
                              int opid = await DatabaseHelper()
                                  .insertOnlinePlaylist(
                                      titleController.value.text.trim(), img);
                              initPlaylists();
                              setState(() {
                                redIt = false;
                                createPlaylist = false;
                              });
                              showPlaylistHandler.value = false;
                              for (String stid in playlistTrackToAddData
                                  .value!["playlist"]) {
                                await DatabaseHelper()
                                    .insertOnlineTrackId(opid, stid);
                              }
                            } else {
                              await DatabaseHelper().insertOnlinePlaylist(
                                  titleController.value.text.trim(),
                                  coverBytes);

                              initPlaylists();
                              setState(() {
                                redIt = false;
                                createPlaylist = false;
                              });
                              if (createPlaylist ||
                                  playlistTrackToAddData.value == null) {
                                showPlaylistHandler.value = false;
                              }
                            }
                          } else {
                            setState(() {
                              redIt = true;
                            });
                            Notifications().showWarningNotification(
                                context,
                                AppLocalizations.of(context)!
                                    .playlistnamealreadyexists);
                          }
                        } else {
                          print("object; ${titleController.value.text}");
                          setState(() {
                            redIt = true;
                          });
                        }
                      },
                      selectPlaylist: (index) {
                        if (selectedPlaylists
                            .contains(playlists[index]['opid'])) {
                          setState(() {
                            selectedPlaylists.remove(playlists[index]['opid']);
                          });
                        } else {
                          setState(() {
                            selectedPlaylists.add(playlists[index]['opid']);
                          });
                        }
                      },
                      changeCreatePlaylist: () {
                        if (playlistTrackToAddData.value != null) {
                          setState(() {
                            createPlaylist = !createPlaylist;
                          });
                        }
                      },
                      addTracksToPlalists: () async {
                        for (int opid in selectedPlaylists) {
                          if (playlistTrackToAddData.value!["id"] != null) {
                            await DatabaseHelper().insertOnlineTrackId(
                                opid, playlistTrackToAddData.value!["id"]);
                          } else {
                            for (var track
                                in playlistTrackToAddData.value!["tracks"]) {
                              await DatabaseHelper()
                                  .insertOnlineTrackId(opid, track["id"]);
                            }
                          }
                        }
                        initPlaylists();
                        setState(() {
                          selectedPlaylists.clear();
                        });
                        showPlaylistHandler.value = false;
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        });
  }
}

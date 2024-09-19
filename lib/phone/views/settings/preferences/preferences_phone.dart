import 'package:flutter/cupertino.dart';
import 'package:pongo/phone/components/settings/preferences/apple_number_picker.dart';
import 'package:pongo/phone/widgets/settings/tiles/settings_tile_int.dart';
import 'package:pongo/phone/widgets/settings/tiles/settings_tile_switcher.dart';

import '../../../../exports.dart';

class PreferencesPhone extends StatefulWidget {
  const PreferencesPhone({super.key});

  @override
  State<PreferencesPhone> createState() => _PreferencesPhoneState();
}

class _PreferencesPhoneState extends State<PreferencesPhone> {
  // Show body
  bool showBody = false;

  // Market
  String market = '';

  // Sync time delay
  bool syncTimeDelay = false;

  // Synced lyrics
  bool syncedLyrics = false;

  // Search result num
  int numOfSearchArtists = 3;
  int numOfSearchAlbums = 5;
  int numOfSearchTracks = 50;
  int numOfSearchPlaylists = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showBottomNavBar.value = false;
    });
    initPreferences();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showBottomNavBar.value = true;
    });
    super.dispose();
  }

  initPreferences() async {
    final mark = await Storage().getMarket();
    final sync = await Storage().getSyncDelay();
    final syncLyrics = await Storage().getUseSyncedLyrics();
    final numSearchArtists = await Storage().getNumOfSearchArtists();
    final numSearchAlbums = await Storage().getNumOfSearchAlbums();
    final numSearchTracks = await Storage().getNumOfSearchTracks();
    final numSearchPlaylists = await Storage().getNumOfSearchPlaylists();
    setState(() {
      market = mark ?? 'US';
      syncTimeDelay = sync;
      showBody = true;
      syncedLyrics = syncLyrics;
      numOfSearchArtists = numSearchArtists;
      numOfSearchAlbums = numSearchAlbums;
      numOfSearchTracks = numSearchTracks;
      numOfSearchPlaylists = numSearchPlaylists;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: showBody
          ? Container(
              key: const ValueKey(true),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              decoration: AppConstants().backgroundBoxDecoration,
              child: Scaffold(
                appBar: AppBar(
                  automaticallyImplyLeading: false,
                  title: Row(
                    children: [
                      backButton(context),
                      Expanded(
                        child: Container(),
                      ),
                    ],
                  ),
                ),
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    razw(size.width),
                    razh(AppBar().preferredSize.height / 2),
                    Text(
                      AppLocalizations.of(context)!.preferences,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    razh(AppBar().preferredSize.height),
                    settingsText(
                        AppLocalizations.of(context)!.searchpreferences),
                    settingsTile(
                      context,
                      true,
                      false,
                      AppIcons.world,
                      AppIcons.edit,
                      "${marketsCountryNames[market]} - $market",
                      AppLocalizations.of(context)!.searchmarket,
                      () {
                        kIsApple
                            ? appleMarketPopup(
                                context,
                                market,
                                (mark) async {
                                  Storage().writeMarket(mark);
                                  setState(() {
                                    market = mark;
                                  });
                                },
                              )
                            : appleMarketPopup(
                                //TODO: Implement this for Android
                                context,
                                market,
                                (mark) async {
                                  Storage().writeMarket(mark);
                                  setState(() {
                                    market = mark;
                                  });
                                },
                              );
                      },
                    ),
                    settingsTileInt(
                        context,
                        false,
                        false,
                        AppIcons.blankArtist,
                        numOfSearchArtists,
                        AppLocalizations.of(context)!.artists,
                        AppLocalizations.of(context)!
                            .howmanyartistsshownwhensearching, () {
                      appleNumberPicker(context, numOfSearchArtists,
                          (number) async {
                        await Storage().writeNumOfSearchArtists(number);
                        setState(() {
                          numOfSearchArtists = number;
                          numberOfSearchArtists.value = number;
                        });
                      });
                    }),
                    settingsTileInt(
                        context,
                        false,
                        false,
                        AppIcons.blankAlbum,
                        numOfSearchAlbums,
                        AppLocalizations.of(context)!.albums,
                        AppLocalizations.of(context)!
                            .howmanyalbumsshownwhensearching, () {
                      appleNumberPicker(context, numOfSearchAlbums,
                          (number) async {
                        await Storage().writeNumOfSearchAlbums(number);
                        setState(() {
                          numOfSearchAlbums = number;
                          numberOfSearchAlbums.value = number;
                        });
                      });
                    }),
                    settingsTileInt(
                        context,
                        false,
                        false,
                        AppIcons.blankTrack,
                        numOfSearchTracks,
                        AppLocalizations.of(context)!.tracks,
                        AppLocalizations.of(context)!
                            .howmanytracksshownwhensearching, () {
                      appleNumberPicker(context, numOfSearchTracks,
                          (number) async {
                        await Storage().writeNumOfSearchTracks(number);

                        setState(() {
                          numOfSearchTracks = number;
                          numberOfSearchTracks.value = number;
                        });
                      });
                    }),
                    settingsTileInt(
                        context,
                        false,
                        true,
                        AppIcons.blankAlbum,
                        numOfSearchPlaylists,
                        AppLocalizations.of(context)!.playlists,
                        AppLocalizations.of(context)!
                            .howmanyplaylistsshownwhensearching, () {
                      appleNumberPicker(context, numOfSearchPlaylists,
                          (number) async {
                        await Storage().writeNumOfSearchPlaylists(number);

                        setState(() {
                          numOfSearchPlaylists = number;
                          numberOfSearchPlaylists.value = number;
                        });
                      });
                    }),
                    razh(20),
                    settingsText(AppLocalizations.of(context)!.lyrics),
                    settingsTileSwitcher(
                      context,
                      true,
                      false,
                      CupertinoIcons.hourglass,
                      syncTimeDelay, // AppIcons.edit,
                      AppLocalizations.of(context)!.synctimedelay,
                      AppLocalizations.of(context)!.prefersyncedlyrics,
                      (use) async {
                        setState(() {
                          syncTimeDelay = use;
                        });
                        Storage().writeSyncDelay(use);
                        useSyncTimeDelay.value = use;
                      },
                    ),
                    settingsTileSwitcher(
                      context,
                      false,
                      true,
                      syncedLyrics
                          ? CupertinoIcons.hourglass_tophalf_fill
                          : CupertinoIcons.hourglass_bottomhalf_fill,
                      syncedLyrics, // AppIcons.edit,
                      AppLocalizations.of(context)!.prefersyncedlyrics,
                      AppLocalizations.of(context)!.preferusageofsyncedlyrics,
                      (use) async {
                        setState(() {
                          syncedLyrics = use;
                        });
                        Storage().writeUseSyncedLyrics(use);
                        useSyncedLyrics.value = use;
                      },
                    ),
                  ],
                ),
              ),
            )
          : loadingScaffold(context, const ValueKey(false)),
    );
  }
}

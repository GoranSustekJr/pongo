import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:pongo/phone/components/settings/preferences/apple_lyrics_text_align_picker.dart';
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

  // Enable lyrics
  bool enbleLyrics = false;

  // Lyrics text align
  TextAlign lyricsTextAlign = TextAlign.center;

  // Search result num
  int numOfSearchArtists = 3;
  int numOfSearchAlbums = 5;
  int numOfSearchTracks = 50;
  int numOfSearchPlaylists = 20;

  // Recommendations
  bool recommendedForYou = true;
  bool recommendedPongo = true;

  // Audio player
  bool useCachingAudioSource = false;

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
    final recommendForYou = await Storage().getRecommendedForYou();
    final recommendPongo = await Storage().getRecommendedPongo();
    final lyricsTxtAlign = await Storage().getLyricsTextAlign();
    final useCacheAudioSource = await Storage().getUseCachingAudioSource();
    final enblLyrics = await Storage().getEnableLyrics();
    setState(() {
      market = mark ?? 'US';
      syncTimeDelay = sync;
      showBody = true;
      syncedLyrics = syncLyrics;
      numOfSearchArtists = numSearchArtists;
      numOfSearchAlbums = numSearchAlbums;
      numOfSearchTracks = numSearchTracks;
      numOfSearchPlaylists = numSearchPlaylists;
      recommendedForYou = recommendForYou;
      recommendedPongo = recommendPongo;
      lyricsTextAlign = lyricsTxtAlign;
      useCachingAudioSource = useCacheAudioSource;
      enbleLyrics = enblLyrics;
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
              width: size.width,
              height: size.height,
              decoration: AppConstants().backgroundBoxDecoration,
              child: Scaffold(
                extendBodyBehindAppBar: true,
                extendBody: true,
                body: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      snap: true,
                      floating: true,
                      pinned: true,
                      stretch: true,
                      automaticallyImplyLeading: false,
                      expandedHeight:
                          kIsApple ? size.height / 5 : size.height / 4,
                      title: Row(
                        children: [
                          backButton(context),
                          Expanded(
                            child: Container(),
                          ),
                        ],
                      ),
                      flexibleSpace: ClipRRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: FlexibleSpaceBar(
                            centerTitle: true,
                            title: Text(
                              AppLocalizations.of(context)!.preferences,
                              style: TextStyle(
                                fontSize: kIsApple ? 25 : 30,
                                fontWeight: kIsApple
                                    ? FontWeight.w700
                                    : FontWeight.w800,
                              ),
                            ),
                            stretchModes: const [
                              StretchMode.zoomBackground,
                              StretchMode.blurBackground,
                              StretchMode.fadeTitle,
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              razh(AppBar().preferredSize.height / 2),
                              razh(AppBar().preferredSize.height),
                              settingsText(AppLocalizations.of(context)!
                                  .searchpreferences),
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
                                  await Storage()
                                      .writeNumOfSearchArtists(number);
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
                                  await Storage()
                                      .writeNumOfSearchAlbums(number);
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
                                  await Storage()
                                      .writeNumOfSearchTracks(number);

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
                                  await Storage()
                                      .writeNumOfSearchPlaylists(number);

                                  setState(() {
                                    numOfSearchPlaylists = number;
                                    numberOfSearchPlaylists.value = number;
                                  });
                                });
                              }),
                              razh(20),
                              settingsText(AppLocalizations.of(context)!
                                  .recommendations),
                              settingsTileSwitcher(
                                context,
                                true,
                                false,
                                CupertinoIcons.arrow_down_doc_fill,
                                recommendedForYou, // AppIcons.edit,
                                AppLocalizations.of(context)!
                                    .showrecommendedforyou,
                                AppLocalizations.of(context)!
                                    .showrecommendedforyoubody,
                                (use) async {
                                  setState(() {
                                    recommendedForYou = use;
                                  });
                                  Storage().writeRecommendedForYou(use);
                                },
                              ),
                              settingsTileSwitcher(
                                context,
                                false,
                                true,
                                CupertinoIcons.arrow_up_doc_fill,
                                recommendedPongo, // AppIcons.edit,
                                AppLocalizations.of(context)!
                                    .showrecommendedbypongo,
                                AppLocalizations.of(context)!
                                    .showrecommendedbypongobody,
                                (use) async {
                                  setState(() {
                                    recommendedPongo = use;
                                  });
                                  Storage().writeRecommendedPongo(use);
                                },
                              ),
                              razh(20),
                              settingsText(
                                  AppLocalizations.of(context)!.lyrics),
                              settingsTileSwitcher(
                                context,
                                true,
                                false,
                                AppIcons.lyrics,
                                enbleLyrics,
                                AppLocalizations.of(context)!.enablelyrics,
                                AppLocalizations.of(context)!
                                    .enableusageoflyrics,
                                (enable) async {
                                  setState(() {
                                    enbleLyrics = enable;
                                  });
                                  await Storage().writeEnableLyrics(enable);
                                  enableLyrics.value = enable;
                                  print(enableLyrics.value);
                                },
                              ),
                              settingsTileSwitcher(
                                context,
                                false,
                                false,
                                CupertinoIcons.hourglass,
                                syncTimeDelay, // AppIcons.edit,
                                AppLocalizations.of(context)!.synctimedelay,
                                AppLocalizations.of(context)!
                                    .prefersyncedlyrics,
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
                                false,
                                syncedLyrics
                                    ? CupertinoIcons.hourglass_tophalf_fill
                                    : CupertinoIcons.hourglass_bottomhalf_fill,
                                syncedLyrics, // AppIcons.edit,
                                AppLocalizations.of(context)!
                                    .prefersyncedlyrics,
                                AppLocalizations.of(context)!
                                    .preferusageofsyncedlyrics,
                                (use) async {
                                  setState(() {
                                    syncedLyrics = use;
                                  });
                                  Storage().writeUseSyncedLyrics(use);
                                  useSyncedLyrics.value = use;
                                },
                              ),
                              settingsTile(
                                context,
                                false,
                                true,
                                lyricsTextAlign == TextAlign.left
                                    ? CupertinoIcons.text_alignleft
                                    : lyricsTextAlign == TextAlign.right
                                        ? CupertinoIcons.text_alignright
                                        : CupertinoIcons.text_aligncenter,
                                AppIcons.edit,
                                lyricsTextAlign == TextAlign.left
                                    ? AppLocalizations.of(context)!
                                        .lefttextalign
                                    : lyricsTextAlign == TextAlign.center
                                        ? AppLocalizations.of(context)!
                                            .centertextalign
                                        : lyricsTextAlign == TextAlign.right
                                            ? AppLocalizations.of(context)!
                                                .righttextalign
                                            : AppLocalizations.of(context)!
                                                .justifytextalign,
                                AppLocalizations.of(context)!
                                    .lyircstextalignment,
                                () {
                                  /* kIsApple
                                      ? appleLyricsTextAlignPicker(context)
                                      :  */
                                  appleLyricsTextAlignPicker(
                                      context,
                                      lyricsTextAlign == TextAlign.left
                                          ? 0
                                          : lyricsTextAlign == TextAlign.center
                                              ? 1
                                              : lyricsTextAlign ==
                                                      TextAlign.right
                                                  ? 2
                                                  : 3, (ind) async {
                                    if (ind == 0) {
                                      await Storage()
                                          .writeLyricsTextAlign(TextAlign.left);

                                      setState(() {
                                        lyricsTextAlign = TextAlign.left;
                                      });
                                      currentLyricsTextAlignment.value =
                                          TextAlign.left;
                                    } else if (ind == 1) {
                                      await Storage().writeLyricsTextAlign(
                                          TextAlign.center);
                                      setState(() {
                                        lyricsTextAlign = TextAlign.center;
                                      });
                                      currentLyricsTextAlignment.value =
                                          TextAlign.center;
                                    } else if (ind == 2) {
                                      await Storage().writeLyricsTextAlign(
                                          TextAlign.right);
                                      setState(() {
                                        lyricsTextAlign = TextAlign.right;
                                      });
                                      currentLyricsTextAlignment.value =
                                          TextAlign.right;
                                    } else {
                                      await Storage().writeLyricsTextAlign(
                                          TextAlign.justify);
                                      setState(() {
                                        lyricsTextAlign = TextAlign.justify;
                                      });
                                      currentLyricsTextAlignment.value =
                                          TextAlign.justify;
                                    }
                                  });
                                },
                              ),
                              razh(20),
                              settingsText(
                                  AppLocalizations.of(context)!.audioplayer),
                              settingsTileSwitcher(
                                context,
                                true,
                                false,
                                CupertinoIcons.arrow_down_doc_fill,
                                useCachingAudioSource, // AppIcons.edit,
                                AppLocalizations.of(context)!
                                    .audioplayercaching,
                                AppLocalizations.of(context)!
                                    .letaudioplayercachethesongs,
                                (use) async {
                                  setState(() {
                                    useCachingAudioSource = use;
                                  });
                                  useCacheAudioSource.value = use;
                                  Storage().writeUseCacheAudioSource(use);
                                },
                              ),
                              razh(50),
                            ],
                          );
                        },
                        childCount: 1,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : loadingScaffold(context, const ValueKey(false)),
    );
  }
}

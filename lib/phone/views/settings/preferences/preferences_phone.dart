import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
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
  bool showHistory = true;
  bool showExplore = true;

  // Audio player
  bool useCachingAudioSource = false;

  // Cache Images
  bool useCacheImages = false;

  // Use blur
  bool useBlr = false;

  // Use detailed blurhash
  bool useDetailedBlurhsh = true;

  // Use mix
  bool useMx = false;

  // Dark mode
  bool drkMode = true;

  // Sleep alarm
  bool linearSleepIn = true;
  bool linearWakeUp = true;

  // dynamic blurhash
  bool usDynamicBlurhash = false;

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
    final shwHistory = await Storage().getEnableHistory();
    final shwExplore = await Storage().getEnableCategories();
    final lyricsTxtAlign = await Storage().getLyricsTextAlign();
    final useCacheAudioSource = await Storage().getUseCachingAudioSource();
    final enblLyrics = await Storage().getEnableLyrics();
    final useCachImages = await Storage().getCacheImages();
    final usBlur = await Storage().getUseBlur();
    final usDetailedBlurhash = await Storage().getUseDetailedBlurhash();
    final usMix = await Storage().getUseMix();
    final darkMod = await Storage().getDarkMode();
    final linearSlpin = await Storage().getLinearSleepin();
    final linearWkup = await Storage().getLinearWakeup();
    final usDynmicBlurhash = await Storage().getUseDynamicBlurhash();
    setState(() {
      market = mark ?? 'US';
      syncTimeDelay = sync;
      showBody = true;
      syncedLyrics = syncLyrics;
      numOfSearchArtists = numSearchArtists;
      numOfSearchAlbums = numSearchAlbums;
      numOfSearchTracks = numSearchTracks;
      numOfSearchPlaylists = numSearchPlaylists;
      showHistory = shwHistory;
      showExplore = shwExplore;
      lyricsTextAlign = lyricsTxtAlign;
      useCachingAudioSource = useCacheAudioSource;
      enbleLyrics = enblLyrics;
      useCacheImages = useCachImages;
      useBlr = usBlur;
      useDetailedBlurhsh = usDetailedBlurhash;
      useMx = usMix;
      drkMode = darkMod;
      linearSleepIn = linearSlpin;
      linearWakeUp = linearWkup;
      usDynamicBlurhash = usDynmicBlurhash;
    });
  }

  void notifyChange() {
    Notifications().showWarningNotification(
        context,
        AppLocalizations.of(context)
            .appmayneedtoberestartedinorderforchangestotakefullaffect);
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
                      backgroundColor: useBlur.value
                          ? Col.transp
                          : Col.realBackground.withAlpha(AppConstants().noBlur),
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
                          filter: ImageFilter.blur(
                            sigmaX: useBlur.value ? 10 : 0,
                            sigmaY: useBlur.value ? 10 : 0,
                          ),
                          child: FlexibleSpaceBar(
                            centerTitle: true,
                            title: Text(
                              AppLocalizations.of(context).preferences,
                              style: TextStyle(
                                  fontSize: kIsApple ? 25 : 30,
                                  fontWeight: kIsApple
                                      ? FontWeight.w700
                                      : FontWeight.w800,
                                  color: Col.text),
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
                              settingsText(AppLocalizations.of(context)
                                  .searchpreferences),
                              settingsTile(
                                context,
                                true,
                                false,
                                AppIcons.world,
                                AppIcons.edit,
                                "${marketsCountryNames[market]} - $market",
                                AppLocalizations.of(context).searchmarket,
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
                                            notifyChange();
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
                                            notifyChange();
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
                                  AppLocalizations.of(context).artists,
                                  AppLocalizations.of(context)
                                      .howmanyartistsshownwhensearching, () {
                                appleNumberPicker(context, numOfSearchArtists,
                                    (number) async {
                                  await Storage()
                                      .writeNumOfSearchArtists(number);
                                  setState(() {
                                    numOfSearchArtists = number;
                                    numberOfSearchArtists.value = number;
                                  });
                                  notifyChange();
                                });
                              }),
                              settingsTileInt(
                                  context,
                                  false,
                                  false,
                                  AppIcons.blankAlbum,
                                  numOfSearchAlbums,
                                  AppLocalizations.of(context).albums,
                                  AppLocalizations.of(context)
                                      .howmanyalbumsshownwhensearching, () {
                                appleNumberPicker(context, numOfSearchAlbums,
                                    (number) async {
                                  await Storage()
                                      .writeNumOfSearchAlbums(number);
                                  setState(() {
                                    numOfSearchAlbums = number;
                                    numberOfSearchAlbums.value = number;
                                  });
                                  notifyChange();
                                });
                              }),
                              settingsTileInt(
                                  context,
                                  false,
                                  false,
                                  AppIcons.blankTrack,
                                  numOfSearchTracks,
                                  AppLocalizations.of(context).tracks,
                                  AppLocalizations.of(context)
                                      .howmanytracksshownwhensearching, () {
                                appleNumberPicker(context, numOfSearchTracks,
                                    (number) async {
                                  await Storage()
                                      .writeNumOfSearchTracks(number);

                                  setState(() {
                                    numOfSearchTracks = number;
                                    numberOfSearchTracks.value = number;
                                  });
                                  notifyChange();
                                });
                              }),
                              settingsTileInt(
                                  context,
                                  false,
                                  true,
                                  AppIcons.blankAlbum,
                                  numOfSearchPlaylists,
                                  AppLocalizations.of(context).playlists,
                                  AppLocalizations.of(context)
                                      .howmanyplaylistsshownwhensearching, () {
                                appleNumberPicker(context, numOfSearchPlaylists,
                                    (number) async {
                                  await Storage()
                                      .writeNumOfSearchPlaylists(number);

                                  setState(() {
                                    numOfSearchPlaylists = number;
                                    numberOfSearchPlaylists.value = number;
                                  });
                                  notifyChange();
                                });
                              }),
                              razh(20),
                              settingsText(
                                  AppLocalizations.of(context).startpage),
                              settingsTileSwitcher(
                                context,
                                true,
                                false,
                                CupertinoIcons.arrow_down_doc_fill,
                                showHistory, // AppIcons.edit,
                                AppLocalizations.of(context).showhistory,
                                AppLocalizations.of(context)
                                    .showhistoryonstartpage,
                                (use) async {
                                  setState(() {
                                    showHistory = use;
                                  });
                                  await Storage().writeEnableHistory(use);
                                  notifyChange();
                                },
                              ),
                              settingsTileSwitcher(
                                context,
                                false,
                                true,
                                CupertinoIcons.arrow_up_doc_fill,
                                showExplore, // AppIcons.edit,
                                AppLocalizations.of(context).showexplore,
                                AppLocalizations.of(context)
                                    .showexploreonstartpage,
                                (use) async {
                                  setState(() {
                                    showExplore = use;
                                  });
                                  await Storage().writeEnableCategories(use);
                                  notifyChange();
                                },
                              ),
                              razh(20),
                              settingsText(AppLocalizations.of(context).lyrics),
                              settingsTileSwitcher(
                                context,
                                true,
                                false,
                                AppIcons.lyrics,
                                enbleLyrics,
                                AppLocalizations.of(context).enablelyrics,
                                AppLocalizations.of(context)
                                    .enableusageoflyrics,
                                (enable) async {
                                  setState(() {
                                    enbleLyrics = enable;
                                  });
                                  await Storage().writeEnableLyrics(enable);
                                  enableLyrics.value = enable;
                                  //notifyChange();
                                },
                              ),
                              settingsTileSwitcher(
                                context,
                                false,
                                false,
                                CupertinoIcons.hourglass,
                                syncTimeDelay, // AppIcons.edit,
                                AppLocalizations.of(context).synctimedelay,
                                AppLocalizations.of(context).prefersyncedlyrics,
                                (use) async {
                                  setState(() {
                                    syncTimeDelay = use;
                                  });
                                  Storage().writeSyncDelay(use);
                                  useSyncTimeDelay.value = use;
                                  //notifyChange();
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
                                AppLocalizations.of(context).prefersyncedlyrics,
                                AppLocalizations.of(context)
                                    .preferusageofsyncedlyrics,
                                (use) async {
                                  setState(() {
                                    syncedLyrics = use;
                                  });
                                  Storage().writeUseSyncedLyrics(use);
                                  useSyncedLyrics.value = use;
                                  notifyChange();
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
                                    ? AppLocalizations.of(context).lefttextalign
                                    : lyricsTextAlign == TextAlign.center
                                        ? AppLocalizations.of(context)
                                            .centertextalign
                                        : lyricsTextAlign == TextAlign.right
                                            ? AppLocalizations.of(context)
                                                .righttextalign
                                            : AppLocalizations.of(context)
                                                .justifytextalign,
                                AppLocalizations.of(context)
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
                                    //notifyChange();
                                  });
                                },
                              ),
                              razh(20),
                              settingsText(
                                  AppLocalizations.of(context).audioplayer),
                              settingsTileSwitcher(
                                context,
                                true,
                                false,
                                CupertinoIcons.music_albums_fill,
                                useMx,
                                AppLocalizations.of(context).mix,
                                AppLocalizations.of(context)
                                    .usemixfeaturewhenplayingsearchedmusic,
                                (use) async {
                                  setState(() {
                                    useMx = use;
                                  });
                                  useMix.value = use;
                                  await Storage().writeUseMix(use);
                                  notifyChange();
                                },
                              ),
                              settingsTileSwitcher(
                                context,
                                false,
                                false,
                                CupertinoIcons.arrow_down_doc_fill,
                                useCachingAudioSource, // AppIcons.edit,
                                AppLocalizations.of(context).audioplayercaching,
                                AppLocalizations.of(context)
                                    .letaudioplayercachethesongs,
                                (use) async {
                                  setState(() {
                                    useCachingAudioSource = use;
                                  });
                                  useCacheAudioSource.value = use;
                                  await Storage().writeUseCacheAudioSource(use);
                                  notifyChange();
                                },
                              ),
                              settingsTile(
                                context,
                                false,
                                true,
                                AppIcons.audioPlayer,
                                AppIcons.trash,
                                AppLocalizations.of(context)
                                    .clearaudioplayercache,
                                AppLocalizations.of(context)
                                    .clearyouraudioplayercache,
                                () async {
                                  await AudioPlayer.clearAssetCache();
                                },
                              ),
                              razh(20),
                              settingsText(AppLocalizations.of(context).images),
                              settingsTileSwitcher(
                                context,
                                true,
                                false,
                                CupertinoIcons.arrow_down_doc_fill,
                                useCacheImages, // AppIcons.edit,
                                AppLocalizations.of(context).imagecaching,
                                AppLocalizations.of(context)
                                    .cacheimagestoreducenetworkactivity,
                                (use) async {
                                  setState(() {
                                    useCacheImages = use;
                                  });
                                  cacheImages.value = use;
                                  await Storage().writeCacheImages(use);
                                  notifyChange();
                                },
                              ),
                              settingsTile(
                                  context,
                                  false,
                                  true,
                                  AppIcons.image,
                                  AppIcons.trash,
                                  AppLocalizations.of(context).clearimagecache,
                                  AppLocalizations.of(context)
                                      .clearyourassetimagecache, () async {
                                DefaultCacheManager manager =
                                    DefaultCacheManager();
                                manager.emptyCache();
                                PaintingBinding.instance.imageCache.clear();
                              }),
                              razh(20),
                              settingsText(
                                  AppLocalizations.of(context).userinterface),
                              settingsTileSwitcher(
                                  context,
                                  true,
                                  false,
                                  AppIcons.image,
                                  usDynamicBlurhash,
                                  AppLocalizations.of(context).dynamicblurhash,
                                  AppLocalizations.of(context)
                                      .playingdetailsbackgroundwilldynamicallychange,
                                  (use) async {
                                setState(() {
                                  usDynamicBlurhash = use;
                                });

                                useDynamicBlurhash = use;
                                await Storage().writeUseDynamicBlurhash(use);

                                if (use == true) {
                                  Notifications().showWarningNotification(
                                      context,
                                      AppLocalizations.of(context)
                                          .dynamicblurhashwarning);
                                }
                              }),
                              settingsTileSwitcher(
                                context,
                                false,
                                false,
                                drkMode
                                    ? CupertinoIcons.moon
                                    : CupertinoIcons.sun_max,
                                drkMode, // AppIcons.edit,
                                drkMode
                                    ? AppLocalizations.of(context).darkmode
                                    : AppLocalizations.of(context).lightmode,
                                drkMode
                                    ? AppLocalizations.of(context)
                                        .currentlyusingdarkmode
                                    : AppLocalizations.of(context)
                                        .currentlyusinglightmode,
                                (use) async {
                                  setState(() {
                                    drkMode = use;
                                  });

                                  darkMode.value = use;
                                  await Storage().writeDarkMode(use);
                                  notifyChange();
                                },
                              ),
                              settingsTileSwitcher(
                                context,
                                false,
                                false,
                                CupertinoIcons.arrow_down_doc_fill,
                                useBlr, // AppIcons.edit,
                                AppLocalizations.of(context).useblur,
                                AppLocalizations.of(context)
                                    .turnoffifyourdeviceisgettinghotorhaslag,
                                (use) async {
                                  setState(() {
                                    useBlr = use;
                                  });

                                  useBlur.value = use;
                                  await Storage().writeUseBlur(use);
                                  notifyChange();
                                },
                              ),
                              settingsTileSwitcher(
                                context,
                                false,
                                true,
                                CupertinoIcons.photo_on_rectangle,
                                useDetailedBlurhsh, // AppIcons.edit,
                                AppLocalizations.of(context).detailedblurhash,
                                AppLocalizations.of(context)
                                    .usedetailedblurhash,
                                (use) async {
                                  setState(() {
                                    useDetailedBlurhsh = use;
                                  });

                                  detailedBlurhash.value = use;
                                  await Storage().writeUseDetailedBlurhash(use);
                                  notifyChange();
                                },
                              ),
                              razh(20),
                              settingsText(AppLocalizations.of(context).sleep),
                              settingsTileSwitcher(
                                context,
                                true,
                                false,
                                AppIcons.sleep,
                                linearSleepIn, // AppIcons.edit,
                                AppLocalizations.of(context).linearsleepin,
                                AppLocalizations.of(context)
                                    .linearlydecreasevolumewhenusingsleepin,
                                (use) async {
                                  setState(() {
                                    linearSleepIn = use;
                                  });

                                  linearSleepin = use;
                                  await Storage().writeLinearSleepin(use);
                                  // notifyChange();
                                },
                              ),
                              settingsTileSwitcher(
                                context,
                                false,
                                true, Icons.alarm,
                                linearWakeUp, // AppIcons.edit,
                                AppLocalizations.of(context).linearalarm,
                                AppLocalizations.of(context)
                                    .linearlyincreasevolumewhenusingalarm,
                                (use) async {
                                  setState(() {
                                    linearWakeUp = use;
                                  });

                                  linearWakeup = use;
                                  await Storage().writeLinearWakeup(use);
                                  // notifyChange();
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

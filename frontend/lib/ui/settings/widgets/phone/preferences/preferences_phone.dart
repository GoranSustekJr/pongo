import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../../../../../config/markets.dart';
import '../../../../../domain/models/settings/app_settings.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../utils/platform.dart';
import '../../../../app/view_models/app_settings_view_model.dart';
import '../../../../core/app_icons.dart';
import '../../../../core/notifications.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/themes/dimens.dart';
import '../../../../core/ui/app_blur.dart';
import '../../../../core/ui/phone/buttons/back_button.dart';
import '../../../../core/ui/phone/loading_scaffold.dart';
import '../../../../core/ui/space.dart';
import '../../../../shell/view_models/shell_view_model.dart';
import '../widgets/settings_text.dart';
import '../widgets/settings_tile.dart';
import '../widgets/settings_tile_int.dart';
import '../widgets/settings_tile_switcher.dart';
import 'apple_lyrics_text_align_picker.dart';
import 'apple_market_popup.dart';
import 'apple_number_picker.dart';

class PreferencesPhone extends StatefulWidget {
  const PreferencesPhone({super.key});

  @override
  State<PreferencesPhone> createState() => _PreferencesPhoneState();
}

class _PreferencesPhoneState extends State<PreferencesPhone> {
  late final AppSettingsViewModel _settings;
  late final ShellViewModel _shell;

  // Show body
  final bool showBody = true;

  String get market => _settings.settings.market;
  bool get syncTimeDelay => _settings.settings.useSyncTimeDelay;
  bool get syncedLyrics => _settings.settings.useSyncedLyrics;
  bool get enbleLyrics => _settings.settings.enableLyrics;
  TextAlign get lyricsTextAlign => _settings.settings.lyricsTextAlign;
  int get numOfSearchArtists => _settings.settings.searchArtistCount;
  int get numOfSearchAlbums => _settings.settings.searchAlbumCount;
  int get numOfSearchTracks => _settings.settings.searchTrackCount;
  int get numOfSearchPlaylists => _settings.settings.searchPlaylistCount;
  bool get showHistory => _settings.settings.enableHistory;
  bool get showExplore => _settings.settings.enableCategories;
  bool get useCachingAudioSource => _settings.settings.useCacheAudioSource;
  bool get streamWhileDownloading => _settings.settings.streamWhileDownloading;
  bool get useCacheImages => _settings.settings.cacheImages;
  bool get useBlr => _settings.settings.useBlur;
  bool get useDetailedBlurhsh => _settings.settings.useDetailedBlurhash;
  bool get useMx => _settings.settings.useMix;
  bool get drkMode => _settings.settings.darkMode;
  bool get linearSleepIn => _settings.settings.linearSleepIn;
  bool get linearWakeUp => _settings.settings.linearWakeUp;
  bool get usDynamicBlurhash => _settings.settings.useDynamicBlurhash;
  bool get useAnimations => _settings.settings.useAnimations;
  bool get useLiquidGlss => _settings.settings.useLiquidGlass;

  @override
  void initState() {
    super.initState();
    _settings = context.read<AppSettingsViewModel>();
    _shell = context.read<ShellViewModel>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _shell.showBottomNavBar.value = false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _shell.showBottomNavBar.value = true;
    });
    super.dispose();
  }

  Future<void> _save(AppSettings Function(AppSettings current) change) =>
      _settings.update(change);

  void notifyChange() {
    Notifications().showWarningNotification(
      context,
      AppLocalizations.of(context)
          .appmayneedtoberestartedinorderforchangestotakefullaffect,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    context.watch<AppSettingsViewModel>();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: showBody
          ? Container(
              key: const ValueKey(true),
              width: size.width,
              height: size.height,
              decoration: context.colors.backgroundBoxDecoration,
              child: Scaffold(
                extendBodyBehindAppBar: true,
                extendBody: true,
                body: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      //snap: true,
                      //floating: true,
                      pinned: true,
                      stretch: true,
                      backgroundColor: _settings.settings.useBlur
                          ? Col.transp
                          : context.colors.realBackground.withAlpha(
                              Dimens.noBlur,
                            ),
                      automaticallyImplyLeading: false,
                      expandedHeight: kIsApple
                          ? size.height / 5
                          : size.height / 4,
                      title: Row(
                        children: [
                          backButton(context),
                          Expanded(child: Container()),
                        ],
                      ),
                      flexibleSpace: ClipRRect(
                        child: BackdropFilter(
                          filter: appBlur(context, 10),
                          child: FlexibleSpaceBar(
                            centerTitle: true,
                            title: Text(
                              AppLocalizations.of(context).preferences,
                              style: TextStyle(
                                fontSize: kIsApple ? 25 : 30,
                                fontWeight: kIsApple
                                    ? FontWeight.w700
                                    : FontWeight.w800,
                                color: context.colors.text,
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
                      delegate: SliverChildBuilderDelegate((
                        BuildContext context,
                        int index,
                      ) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            razh(AppBar().preferredSize.height / 2),
                            razh(AppBar().preferredSize.height),
                            settingsText(
                              AppLocalizations.of(context).searchpreferences,
                            ),
                            settingsTile(
                              context,
                              true,
                              false,
                              AppIcons.world,
                              AppIcons.edit,
                              '${marketsCountryNames[market]} - $market',
                              AppLocalizations.of(context).searchmarket,
                              () {
                                kIsApple
                                    ? appleMarketPopup(context, market, (
                                        mark,
                                      ) async {
                                        await _save(
                                          (s) => s.copyWith(market: mark),
                                        );

                                        notifyChange();
                                      })
                                    : appleMarketPopup(
                                        //TODO: Implement this for Android
                                        context,
                                        market,
                                        (mark) async {
                                          await _save(
                                            (s) => s.copyWith(market: mark),
                                          );

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
                                  .howmanyartistsshownwhensearching,
                              () {
                                appleNumberPicker(context, numOfSearchArtists, (
                                  number,
                                ) async {
                                  await _save(
                                    (s) =>
                                        s.copyWith(searchArtistCount: number),
                                  );

                                  notifyChange();
                                });
                              },
                            ),
                            settingsTileInt(
                              context,
                              false,
                              false,
                              AppIcons.blankAlbum,
                              numOfSearchAlbums,
                              AppLocalizations.of(context).albums,
                              AppLocalizations.of(context)
                                  .howmanyalbumsshownwhensearching,
                              () {
                                appleNumberPicker(context, numOfSearchAlbums, (
                                  number,
                                ) async {
                                  await _save(
                                    (s) => s.copyWith(searchAlbumCount: number),
                                  );

                                  notifyChange();
                                });
                              },
                            ),
                            settingsTileInt(
                              context,
                              false,
                              false,
                              AppIcons.blankTrack,
                              numOfSearchTracks,
                              AppLocalizations.of(context).tracks,
                              AppLocalizations.of(context)
                                  .howmanytracksshownwhensearching,
                              () {
                                appleNumberPicker(context, numOfSearchTracks, (
                                  number,
                                ) async {
                                  await _save(
                                    (s) => s.copyWith(searchTrackCount: number),
                                  );

                                  notifyChange();
                                });
                              },
                            ),
                            settingsTileInt(
                              context,
                              false,
                              true,
                              AppIcons.blankAlbum,
                              numOfSearchPlaylists,
                              AppLocalizations.of(context).playlists,
                              AppLocalizations.of(context)
                                  .howmanyplaylistsshownwhensearching,
                              () {
                                appleNumberPicker(
                                  context,
                                  numOfSearchPlaylists,
                                  (number) async {
                                    await _save(
                                      (s) => s.copyWith(
                                        searchPlaylistCount: number,
                                      ),
                                    );

                                    notifyChange();
                                  },
                                );
                              },
                            ),
                            razh(20),
                            settingsText(
                              AppLocalizations.of(context).startpage,
                            ),
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
                                await _save(
                                  (s) => s.copyWith(enableHistory: use),
                                );
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
                                await _save(
                                  (s) => s.copyWith(enableCategories: use),
                                );
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
                              AppLocalizations.of(context).enableusageoflyrics,
                              (enable) async {
                                await _save(
                                  (s) => s.copyWith(enableLyrics: enable),
                                );
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
                                await _save(
                                  (s) => s.copyWith(useSyncTimeDelay: use),
                                );
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
                                await _save(
                                  (s) => s.copyWith(useSyncedLyrics: use),
                                );
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
                                  ? AppLocalizations.of(context).centertextalign
                                  : lyricsTextAlign == TextAlign.right
                                  ? AppLocalizations.of(context).righttextalign
                                  : AppLocalizations.of(context)
                                        .justifytextalign,
                              AppLocalizations.of(context).lyircstextalignment,
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
                                      : lyricsTextAlign == TextAlign.right
                                      ? 2
                                      : 3,
                                  (ind) async {
                                    if (ind == 0) {
                                      await _save(
                                        (s) => s.copyWith(
                                          lyricsTextAlign: TextAlign.left,
                                        ),
                                      );
                                    } else if (ind == 1) {
                                      await _save(
                                        (s) => s.copyWith(
                                          lyricsTextAlign: TextAlign.center,
                                        ),
                                      );
                                    } else if (ind == 2) {
                                      await _save(
                                        (s) => s.copyWith(
                                          lyricsTextAlign: TextAlign.right,
                                        ),
                                      );
                                    } else {
                                      await _save(
                                        (s) => s.copyWith(
                                          lyricsTextAlign: TextAlign.justify,
                                        ),
                                      );
                                    }
                                    //notifyChange();
                                  },
                                );
                              },
                            ),
                            razh(20),
                            settingsText(
                              AppLocalizations.of(context).audioplayer,
                            ),
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
                                await _save((s) => s.copyWith(useMix: use));
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
                                await _save(
                                  (s) => s.copyWith(useCacheAudioSource: use),
                                );
                                notifyChange();
                              },
                            ),
                            settingsTile(
                              context,
                              false,
                              !kIsApple,
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
                            // Only tried with AVPlayer so far
                            if (kIsApple)
                              settingsTileSwitcher(
                                context,
                                false,
                                true,
                                CupertinoIcons.waveform,
                                streamWhileDownloading,
                                AppLocalizations.of(context)
                                    .streamwhiledownloading,
                                AppLocalizations.of(context)
                                    .streamwhiledownloadingdescription,
                                (use) async {
                                  await _save(
                                    (s) =>
                                        s.copyWith(streamWhileDownloading: use),
                                  );
                                  notifyChange();
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
                                await _save(
                                  (s) => s.copyWith(cacheImages: use),
                                );
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
                                  .clearyourassetimagecache,
                              () async {
                                final DefaultCacheManager manager =
                                    DefaultCacheManager();
                                await manager.emptyCache();
                                PaintingBinding.instance.imageCache.clear();
                              },
                            ),
                            razh(20),
                            settingsText(
                              AppLocalizations.of(context).userinterface,
                            ),
                            settingsTileSwitcher(
                              context,
                              true,
                              false,
                              Icons.animation_rounded,
                              useAnimations,
                              AppLocalizations.of(context).useanimations,
                              AppLocalizations.of(context)
                                  .turnoffifanimationsaretoohardonthedevice,
                              (use) async {
                                await _save(
                                  (s) => s.copyWith(useAnimations: use),
                                );
                              },
                            ),
                            settingsTileSwitcher(
                              context,
                              false,
                              false,
                              AppIcons.drop,
                              useLiquidGlss,
                              AppLocalizations.of(context).liquidglass,
                              AppLocalizations.of(context).useliquidglass,
                              (use) async {
                                await _save(
                                  (s) => s.copyWith(useLiquidGlass: use),
                                );

                                if (use && context.mounted) {
                                  Notifications().showWarningNotification(
                                    context,
                                    AppLocalizations.of(context)
                                        .liquidglasswarning,
                                  );
                                }
                              },
                            ),
                            settingsTileSwitcher(
                              context,
                              false,
                              false,
                              AppIcons.image,
                              usDynamicBlurhash,
                              AppLocalizations.of(context).dynamicblurhash,
                              AppLocalizations.of(
                                context,
                              ).playingdetailsbackgroundwilldynamicallychange,
                              (use) async {
                                await _save(
                                  (s) => s.copyWith(useDynamicBlurhash: use),
                                );

                                if (use && context.mounted) {
                                  Notifications().showWarningNotification(
                                    context,
                                    AppLocalizations.of(context)
                                        .dynamicblurhashwarning,
                                  );
                                }
                              },
                            ),
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
                                await _save((s) => s.copyWith(darkMode: use));
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
                                await _save((s) => s.copyWith(useBlur: use));
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
                              AppLocalizations.of(context).usedetailedblurhash,
                              (use) async {
                                await _save(
                                  (s) => s.copyWith(useDetailedBlurhash: use),
                                );
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
                                await _save(
                                  (s) => s.copyWith(linearSleepIn: use),
                                );
                                // notifyChange();
                              },
                            ),
                            settingsTileSwitcher(
                              context,
                              false,
                              true,
                              Icons.alarm,
                              linearWakeUp, // AppIcons.edit,
                              AppLocalizations.of(context).linearalarm,
                              AppLocalizations.of(context)
                                  .linearlyincreasevolumewhenusingalarm,
                              (use) async {
                                await _save(
                                  (s) => s.copyWith(linearWakeUp: use),
                                );
                                // notifyChange();
                              },
                            ),
                            razh(50),
                          ],
                        );
                      }, childCount: 1),
                    ),
                  ],
                ),
              ),
            )
          : loadingScaffold(context, const ValueKey(false)),
    );
  }
}

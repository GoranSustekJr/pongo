import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/view_models/app_settings_view_model.dart';
import '../../../core/app_icons.dart';
import '../../../core/themes/colors.dart';
import '../../../core/ui/space.dart';
import '../../../library/widgets/desktop/favourites_macos.dart';
import '../../../library/widgets/desktop/locals_macos.dart';
import '../../../player/view_models/player_view_model.dart';
import '../../../player/widgets/desktop/lyrics/lyrics_macos.dart';
import '../../../player/widgets/desktop/queue/queue_buttons_macos.dart';
import '../../../player/widgets/desktop/queue/queue_macos.dart';
import '../../../playlists/widgets/desktop/offline_playlists_macos.dart';
import '../../../playlists/widgets/desktop/online_playlists_macos.dart';
import '../../../search/widgets/desktop/search_macos.dart';
import '../../../settings/view_models/profile_view_model.dart';
import '../../../settings/widgets/desktop/settings_macos.dart';
import '../../../sleep_alarm/widgets/desktop/sleep_alarm_macos.dart';
import '../../view_models/shell_view_model.dart';
import 'title_bar/title_bar_macos.dart';

class MainMacos extends StatefulWidget {
  const MainMacos({super.key});

  @override
  State<MainMacos> createState() => _HomeStateMacos();
}

class _HomeStateMacos extends State<MainMacos> {
  // Pages
  late List<Widget> pages = [];

  // User data
  late final ProfileViewModel profile;
  String get name => profile.profile?.name ?? '';
  String get email => profile.profile?.email ?? '';
  String? get image => profile.profile?.picture;

  // Queue
  bool queue = false;

  // Style
  TextStyle titleStyle = TextStyle(
    color: Colors.white.withAlpha(150),
    fontSize: 12.5,
  );

  TextStyle cardStyle = TextStyle(
    color: Colors.white.withAlpha(200),
    fontSize: 15,
  );

  // Navigation bar - index map
  Map<int, int> indexMap = {1: 0, 3: 1, 4: 2, 5: 3, 6: 4, 7: 5, 9: 6, 11: 7};
  Map<int, int> indexMapReverse = {
    0: 1,
    1: 3,
    2: 4,
    3: 5,
    4: 6,
    5: 7,
    6: 9,
    7: 11,
  };

  // Locale
  late String locale;

  // Queue \\
  // Edit queue state
  bool editQueue = false;

  // Selected queue indexes state
  final List<int> selectedQueueIndexes = [];

  // Function to toggle selection
  void selectQueueIndex(int ind) {
    setState(() {
      if (selectedQueueIndexes.contains(ind)) {
        selectedQueueIndexes.remove(ind);
      } else {
        selectedQueueIndexes.add(ind);
      }
    });
  }

  @override
  void initState() {
    super.initState();

    pages = [
      const SearchMacos(),
      const FavouritesMacos(),
      const OnlinePlaylistsMacos(),
      const LocalsMacos(),
      const OfflinePlaylistsMacos(),
      const SleepAlarmMacos(),
      const LyricsMacos(),
      const SettingsMacos(),
    ];
    profile = ProfileViewModel(auth: context.read())
      ..addListener(() => setState(() {}));
    locale = context.readSettings.locale;
  }

  @override
  void dispose() {
    profile.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = context.player;
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      decoration: context.colors.backgroundBoxDecoration,
      child: ValueListenableBuilder(
        valueListenable: context.shell.navigationBarIndex,
        builder: (context, index, child) {
          return MacosWindow(
            titleBar: titleBarMacos(context, player, queue, () {
              final bool empty = player.queue.value.isEmpty;
              if (!empty) {
                setState(() {
                  queue = !queue;
                });
              }
            }),
            backgroundColor: Col.transp,
            disableWallpaperTinting: true,
            sidebar: Sidebar(
              minWidth: 185,
              maxWidth: 185,
              topOffset: 20,
              dragClosed: false,
              builder: (context, scrollController) {
                return ValueListenableBuilder(
                  valueListenable: context.shell.navigationBarIndex,
                  builder: (context, _, _) {
                    return SidebarItems(
                      currentIndex:
                          indexMapReverse[context
                              .shell
                              .navigationBarIndex
                              .value]!,
                      scrollController: scrollController,
                      itemSize: SidebarItemSize.large,
                      onChanged: (i) {
                        if (i != 0 && i != 2 && i != 8 && i != 10) {
                          setState(
                            () => context.shell.navigationBarIndex.value =
                                indexMap[i]!,
                          );
                        }
                      },
                      items: [
                        SidebarItem(
                          // Title: Search
                          selectedColor: Col.transp,
                          label: Text(
                            AppLocalizations.of(context).search,
                            style: titleStyle,
                          ),
                        ),
                        SidebarItem(
                          // View: Search
                          leading: const Icon(
                            AppIcons.search,
                            color: Colors.white,
                            size: 15,
                          ),
                          label: Text(
                            AppLocalizations.of(context).search,
                            style: cardStyle,
                          ),
                        ),
                        SidebarItem(
                          // Title: Library
                          selectedColor: Col.transp,
                          label: Text(
                            AppLocalizations.of(context).library,
                            style: titleStyle,
                          ),
                        ),
                        SidebarItem(
                          // View: Favourites
                          leading: Icon(
                            context.shell.navigationBarIndex.value == 1
                                ? AppIcons.heartFill
                                : AppIcons.heart,
                            color: Colors.white,
                            size: 15,
                          ),
                          label: Text(
                            AppLocalizations.of(context).favouritesongs,
                            style: cardStyle,
                          ),
                        ),
                        SidebarItem(
                          // View: Offline playlists
                          leading: const Icon(
                            Icons.wifi_rounded,
                            color: Colors.white,
                            size: 15,
                          ),
                          label: Text(
                            AppLocalizations.of(context).onlineplaylists,
                            style: cardStyle,
                          ),
                        ),
                        SidebarItem(
                          // View: Offline songs
                          leading: const Icon(
                            AppIcons.download,
                            color: Colors.white,
                            size: 15,
                          ),
                          label: Text(
                            AppLocalizations.of(context).offlinesongs,
                            style: cardStyle,
                          ),
                        ),
                        SidebarItem(
                          // View: Offline playlists
                          leading: const Icon(
                            Icons.wifi_off_rounded,
                            color: Colors.white,
                            size: 15,
                          ),
                          label: Text(
                            AppLocalizations.of(context).offlineplaylists,
                            style: cardStyle,
                          ),
                        ),
                        SidebarItem(
                          // View: Sleep alarm
                          leading: const Icon(
                            AppIcons.sleep,
                            color: Colors.white,
                            size: 15,
                          ),
                          label: Text(
                            AppLocalizations.of(context).sleep,
                            style: cardStyle,
                          ),
                        ),
                        SidebarItem(
                          // Title: Lyrics
                          selectedColor: Col.transp,
                          label: Text(
                            AppLocalizations.of(context).lyrics,
                            style: titleStyle,
                          ),
                        ),
                        SidebarItem(
                          // View: Lyrics
                          leading: Builder(
                            builder: (context) {
                              return StreamBuilder(
                                stream: player.currentItemStream,
                                builder:
                                    (
                                      context,
                                      AsyncSnapshot<MediaItem?> snapshot,
                                    ) {
                                      return ValueListenableBuilder(
                                        valueListenable:
                                            context.player.currentStid,
                                        builder: (context, _, _) {
                                          // Current media item
                                          final currentMediaItem =
                                              snapshot.data;

                                          return Icon(
                                            context
                                                        .shell
                                                        .navigationBarIndex
                                                        .value ==
                                                    6
                                                ? AppIcons.lyricsFill
                                                : AppIcons.lyrics,
                                            size: 15,
                                            color: currentMediaItem != null
                                                ? currentMediaItem.id.split(
                                                            '.',
                                                          )[2] ==
                                                          context
                                                              .player
                                                              .currentStid
                                                              .value
                                                      ? Colors.white
                                                      : Colors.white.withAlpha(
                                                          150,
                                                        )
                                                : Colors.white,
                                          );
                                        },
                                      );
                                    },
                              );
                            },
                          ),
                          label: Text(
                            AppLocalizations.of(context).lyrics,
                            style: cardStyle,
                          ),
                        ),
                        SidebarItem(
                          // Title: Settings
                          selectedColor: Col.transp,
                          label: Text(
                            AppLocalizations.of(context).settings,
                            style: titleStyle,
                          ),
                        ),
                        SidebarItem(
                          // View: Settings
                          leading: Icon(
                            AppIcons.settings,
                            color: Colors.white,
                            size: 15,
                          ),
                          label: Text(
                            AppLocalizations.of(context).settings,
                            style: cardStyle,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              bottom: Column(
                children: [
                  MacosListTile(
                    leading: Column(
                      children: [
                        razh(5),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: image == null
                              ? const SizedBox(
                                  key: ValueKey(true),
                                  height: 20,
                                  width: 20,
                                  child: Icon(
                                    CupertinoIcons.profile_circled,
                                    size: 20,
                                  ),
                                )
                              : SizedBox(
                                  key: const ValueKey(false),
                                  height: 20,
                                  width: 20,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(90),
                                    child: Image.network(image!),
                                  ),
                                ),
                        ),
                      ],
                    ),
                    title: Text(name, overflow: TextOverflow.ellipsis),
                    subtitle: Text(email, overflow: TextOverflow.ellipsis),
                  ),
                  razh(5),
                  const Divider(color: CupertinoColors.inactiveGray),
                  razh(5),
                  Row(
                    children: [
                      const Icon(AppIcons.world, color: Colors.white, size: 20),
                      razw(10),
                      Expanded(
                        child: MacosPopupButton(
                          value: locale,
                          items: const [
                            MacosPopupMenuItem(
                              value: 'en',
                              child: Text('English'),
                            ),
                            MacosPopupMenuItem(
                              value: 'de',
                              child: Text('Deutsch'),
                            ),
                            MacosPopupMenuItem(
                              value: 'hr',
                              child: Text('Hrvatski'),
                            ),
                          ],
                          onChanged: (value) async {
                            if (value == null) return;
                            setState(() {
                              locale = value;
                            });
                            await context.read<AppSettingsViewModel>().update(
                              (s) => s.copyWith(locale: value),
                            );
                          },
                        ),
                      ),
                      razw(10),
                    ],
                  ),
                ],
              ),
            ),
            endSidebar: Sidebar(
              startWidth: queue ? 400 : 0,
              maxWidth: queue ? 400 : 0,
              minWidth: queue ? 300 : 0,
              dragClosed: false,
              topOffset: 0,
              top: razh(61),
              bottom: QueueButtonsMacos(
                edit: editQueue,
                changeEditQueue: (p) {
                  setState(() {
                    editQueue = p;
                  });
                },
                closeQueue: () {
                  setState(() {
                    queue = false;
                  });
                },
                clearSelectedQueueIndexes: () {
                  setState(selectedQueueIndexes.clear);
                },
                removeItemsFromQueue: () async {
                  await player.removeFromQueue([...selectedQueueIndexes]);

                  setState(() {
                    editQueue = false;
                    selectedQueueIndexes.clear();
                  });
                },
              ),
              decoration: const BoxDecoration(color: Col.transp),
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: QueueMacos(
                    editQueue: editQueue,
                    selectedQueueIndexes: selectedQueueIndexes,
                    selectQueueIndex: (ind) {
                      if (selectedQueueIndexes.contains(ind)) {
                        setState(() {
                          selectedQueueIndexes.remove(ind);
                        });
                      } else {
                        setState(() {
                          selectedQueueIndexes.add(ind);
                        });
                      }
                    },
                  ),
                );
              },
            ),
            child: Stack(
              children: [
                IndexedStack(
                  index: context.shell.navigationBarIndex.value,
                  children: pages,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

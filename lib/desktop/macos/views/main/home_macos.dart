import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

class MainMacos extends StatefulWidget {
  const MainMacos({super.key});

  @override
  State<MainMacos> createState() => _HomeStateMacos();
}

class _HomeStateMacos extends State<MainMacos> {
  // Pages
  late List<Widget> pages = [];

  // User data
  String name = "";
  String email = "";
  String? image;

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
  Map<int, int> indexMap = {
    1: 0,
    3: 1,
    4: 2,
    5: 3,
    6: 4,
    7: 5,
    9: 6,
    11: 7,
  };
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
  String locale = "en";

  @override
  void initState() {
    super.initState();
    notificationsContext.value = context;

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
    initUserData();
    initLocale();
  }

  initUserData() async {
    final data = await UserData().get(context);

    if (data != null) {
      setState(() {
        email = data["email"];
        name = data["name"];
        image = data["picture"];
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  initLocale() async {
    final loc = await Storage().getLocale();
    setState(() {
      locale = loc ?? "en";
    });
  }

  @override
  Widget build(BuildContext context) {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context) as AudioServiceHandler;
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      decoration: AppConstants().backgroundBoxDecoration,
      child: ValueListenableBuilder(
          valueListenable: navigationBarIndex,
          builder: (context, index, child) {
            return MacosWindow(
              titleBar: titleBarMacos(context, audioServiceHandler),
              backgroundColor: Col.transp,
              disableWallpaperTinting: true,
              sidebar: Sidebar(
                minWidth: 185,
                maxWidth: 185,
                topOffset: 20,
                dragClosed: false,
                builder: (context, scrollController) {
                  return ValueListenableBuilder(
                      valueListenable: navigationBarIndex,
                      builder: (context, _, __) {
                        return SidebarItems(
                          currentIndex:
                              indexMapReverse[navigationBarIndex.value]!,
                          scrollController: scrollController,
                          itemSize: SidebarItemSize.large,
                          onChanged: (i) {
                            if (i != 0 && i != 2 && i != 8 && i != 10) {
                              setState(() =>
                                  navigationBarIndex.value = indexMap[i]!);
                            }
                          },
                          items: [
                            SidebarItem(
                                // Title: Search
                                selectedColor: Col.transp,
                                label: Text(
                                  AppLocalizations.of(context)!.search,
                                  style: titleStyle,
                                )),
                            SidebarItem(
                              // View: Search
                              leading: const Icon(
                                AppIcons.search,
                                color: Colors.white,
                                size: 15,
                              ),
                              label: Text(
                                AppLocalizations.of(context)!.search,
                                style: cardStyle,
                              ),
                            ),
                            SidebarItem(
                                // Title: Library
                                selectedColor: Col.transp,
                                label: Text(
                                  AppLocalizations.of(context)!.library,
                                  style: titleStyle,
                                )),
                            SidebarItem(
                              // View: Favourites
                              leading: Icon(
                                navigationBarIndex.value == 1
                                    ? AppIcons.heartFill
                                    : AppIcons.heart,
                                color: Colors.white,
                                size: 15,
                              ),
                              label: Text(
                                AppLocalizations.of(context)!.favouritesongs,
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
                                AppLocalizations.of(context)!.onlineplaylists,
                                style: cardStyle,
                              ),
                            ),
                            SidebarItem(
                              // View: Offline songs
                              leading: Icon(
                                AppIcons.download,
                                color: Colors.white,
                                size: 15,
                              ),
                              label: Text(
                                AppLocalizations.of(context)!.offlinesongs,
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
                                AppLocalizations.of(context)!.offlineplaylists,
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
                                AppLocalizations.of(context)!.sleep,
                                style: cardStyle,
                              ),
                            ),
                            SidebarItem(
                                // Title: Lyrics
                                selectedColor: Col.transp,
                                label: Text(
                                  AppLocalizations.of(context)!.lyrics,
                                  style: titleStyle,
                                )),
                            SidebarItem(
                              // View: Lyrics
                              leading: Builder(builder: (context) {
                                return StreamBuilder(
                                    stream:
                                        audioServiceHandler.mediaItem.stream,
                                    builder: (context,
                                        AsyncSnapshot<MediaItem?> snapshot) {
                                      return ValueListenableBuilder(
                                          valueListenable: currentStid,
                                          builder: (context, _, __) {
                                            // Current media item
                                            final currentMediaItem =
                                                snapshot.data;

                                            return Icon(
                                              navigationBarIndex.value == 6
                                                  ? AppIcons.lyricsFill
                                                  : AppIcons.lyrics,
                                              size: 15,
                                              color: currentMediaItem != null
                                                  ? currentMediaItem.id
                                                              .split('.')[2] ==
                                                          currentStid.value
                                                      ? Colors.white
                                                      : Colors.white
                                                          .withAlpha(150)
                                                  : Colors.white,
                                            );
                                          });
                                    });
                              }),
                              label: Text(
                                AppLocalizations.of(context)!.lyrics,
                                style: cardStyle,
                              ),
                            ),
                            SidebarItem(
                                // Title: Settings
                                selectedColor: Col.transp,
                                label: Text(
                                  AppLocalizations.of(context)!.settings,
                                  style: titleStyle,
                                )),
                            SidebarItem(
                              // View: Settings
                              leading: Icon(
                                AppIcons.settings,
                                color: Colors.white,
                                size: 15,
                              ),
                              label: Text(
                                AppLocalizations.of(context)!.settings,
                                style: cardStyle,
                              ),
                            ),
                          ],
                        );
                      });
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
                                      child: Image.network(
                                        image!,
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                      title: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        email,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    razh(5),
                    const Divider(color: CupertinoColors.inactiveGray),
                    razh(5),
                    Row(
                      children: [
                        const Icon(
                          AppIcons.world,
                          color: Colors.white,
                          size: 20,
                        ),
                        razw(10),
                        Expanded(
                          child: MacosPopupButton(
                            value: locale,
                            items: const [
                              MacosPopupMenuItem(
                                value: "en",
                                child: Text(
                                  'English',
                                ),
                              ),
                              MacosPopupMenuItem(
                                value: "de",
                                child: Text(
                                  'Deutsch',
                                ),
                              ),
                              MacosPopupMenuItem(
                                value: "hr",
                                child: Text(
                                  'Hrvatski',
                                ),
                              ),
                            ],
                            onChanged: (value) async {
                              MyAppDesktop.setLocale(context, Locale(value!));
                              Storage().writeLocale(value);
                              setState(() {
                                locale = value;
                              });
                            },
                          ),
                        ),
                        razw(10),
                      ],
                    )
                  ],
                ),
              ),
              child: Stack(
                children: [
                  IndexedStack(
                    index: navigationBarIndex.value,
                    children: pages,
                  ),
                ],
              ),
            );
          }),
    );
  }
}

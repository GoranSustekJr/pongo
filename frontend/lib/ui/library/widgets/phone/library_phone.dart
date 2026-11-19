import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:pongo/app/navigation/navigation.dart';
import 'package:pongo/app/theme/colors.dart';
import 'package:pongo/core/constants/app_icons.dart';
import 'package:pongo/core/constants/platform.dart';
import 'package:pongo/features/library/presentation/phone/favourites/favourites_phone.dart';
import 'package:pongo/features/library/presentation/phone/library_tile.dart';
import 'package:pongo/features/library/presentation/phone/locals/locals_phone.dart';
import 'package:pongo/features/playlists/presentation/phone/local/local_playlists_phone.dart';
import 'package:pongo/features/playlists/presentation/phone/online/online_playlists_phone.dart';
import 'package:pongo/features/settings/presentation/phone/widgets/settings_text.dart';
import 'package:pongo/features/sleep_alarm/presentation/phone/sleep_alarm_phone.dart';
import 'package:pongo/l10n/app_localizations.dart';
import 'package:pongo/shared/widgets/space.dart';

class LibraryPhone extends StatefulWidget {
  const LibraryPhone({super.key});

  @override
  State<LibraryPhone> createState() => _LibraryPhoneState();
}

class _LibraryPhoneState extends State<LibraryPhone> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            snap: true,
            floating: true,
            pinned: true,
            stretch: true,
            automaticallyImplyLeading: false,
            expandedHeight: kIsApple
                ? MediaQuery.of(context).size.height / 5
                : MediaQuery.of(context).size.height / 4,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                AppLocalizations.of(context).library,
                style: TextStyle(
                  fontSize: kIsApple ? 30 : 40,
                  fontWeight: kIsApple ? FontWeight.w700 : FontWeight.w800,
                  color: Col.text,
                ),
              ),
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
                StretchMode.fadeTitle,
              ],
            ),
          ),

          // Other slivers for your Wi-Fi settings content
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 20,
                  ),
                  child: Column(
                    children: [
                      razh(kIsApple ? size.width / 5 : size.width / 4),
                      settingsText(AppLocalizations.of(context).online),
                      libraryTile(
                        context,
                        true,
                        false,
                        CupertinoIcons.heart_fill,
                        Icons.wifi_rounded,
                        AppLocalizations.of(context).favouritesongs,
                        AppLocalizations.of(context).onlinefavouritesongs,
                        () {
                          Navigations().nextScreen(
                            context,
                            const FavouritesPhone(),
                          );
                        },
                      ),
                      libraryTile(
                          context,
                          false,
                          true,
                          Icons.queue_music_rounded,
                          Icons.wifi_rounded,
                          AppLocalizations.of(context).playlists,
                          AppLocalizations.of(context).onlineplaylists, () {
                        Navigations().nextScreen(
                          context,
                          const OnlinePlaylistsPhone(),
                        );
                        /*   Navigations()
                            .nextScreen(context, OnlinePlaylistsScreen()); */
                        // widget.navigateToOnlinePLaylists();
                        /*  Navigations()
                            .nextScreen(context, '/online_playlists_screen', {}); */
                      }),
                      razh(25),
                      settingsText(AppLocalizations.of(context).offline),
                      libraryTile(
                        context,
                        true,
                        false,
                        Icons.music_note_rounded,
                        Icons.wifi_off_rounded,
                        AppLocalizations.of(context).songs,
                        AppLocalizations.of(context).offlinesongs,
                        () {
                          Navigations().nextScreen(
                            context,
                            const LocalsPhone(),
                          );
                          /*    Navigations()
                              .nextScreen(context, AllDownloadedSongsPhone()); */
                        },
                      ),
                      libraryTile(
                        context,
                        false,
                        true,
                        Icons.queue_music_rounded,
                        Icons.wifi_off_rounded,
                        AppLocalizations.of(context).playlists,
                        AppLocalizations.of(context).offlineplaylists,
                        () {
                          Navigations()
                              .nextScreen(context, const LocalPlaylistsPhone());
                        },
                      ),
                      razh(25),
                      settingsText(AppLocalizations.of(context).sleep),
                      libraryTile(
                        context,
                        true,
                        true,
                        AppIcons.sleep,
                        Icons.alarm,
                        AppLocalizations.of(context).sleep,
                        AppLocalizations.of(context).sleepandalarmclock,
                        () {
                          Navigations().nextScreen(
                            context,
                            const SleepAlarmPhone(),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
              childCount: 1,
            ),
          ),
        ],
      ),
    );
  }
}

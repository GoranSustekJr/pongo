import 'package:flutter/material.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:provider/provider.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../utils/platform.dart';
import '../../../../app/view_models/app_settings_view_model.dart';
import '../../../../core/app_icons.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/themes/dimens.dart';
import '../../../../core/ui/app_blur.dart';
import '../../../../core/ui/buttons/text_button.dart';
import '../../../../core/ui/phone/buttons/back_button.dart';
import '../../../../core/ui/phone/buttons/icon_button.dart';
import '../../../../core/ui/phone/liquid_glass_background.dart';
import '../../../../core/ui/phone/loading_scaffold.dart';
import '../../../../core/ui/phone/shimmer/song_shimmer.dart';
import '../../../../core/ui/phone/sticky_header_delegate.dart';
import '../../../../core/ui/space.dart';
import '../../../../player/widgets/phone/alerts/halt_alert.dart';
import '../../../../playlists/view_models/open_playlist.dart';
import '../../../../shell/view_models/shell_view_model.dart';
import '../../../view_models/favourites_view_model.dart';
import 'favourites_alert.dart';
import 'favourites_body_phone.dart';
import 'play_shuffle_halt_favourites.dart';

class FavouritesPhone extends StatefulWidget {
  const FavouritesPhone({super.key});

  @override
  State<FavouritesPhone> createState() => _FavouritesPhoneState();
}

class _FavouritesPhoneState extends State<FavouritesPhone> {
  late final FavouritesViewModel favouritesItemManager;
  final scrollController = ScrollController();
  double scrollControllerOffset = 0;

  @override
  void initState() {
    super.initState();
    favouritesItemManager = FavouritesViewModel(
      favourites: context.read(),
      downloads: context.read(),
      catalog: context.read(),
      player: context.read(),
    );
    scrollController.addListener(() {
      setState(() {
        scrollControllerOffset = scrollController.offset < 0
            ? 0
            : scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    favouritesItemManager.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return ListenableBuilder(
      listenable: favouritesItemManager,
      builder: (context, child) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: favouritesItemManager.showBody
              ? Container(
                  key: const ValueKey(true),
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  decoration: context.colors.backgroundBoxDecoration,
                  child: Scaffold(
                    extendBodyBehindAppBar: true,
                    extendBody: true,
                    body: Scrollbar(
                      controller: scrollController,
                      child: CustomScrollView(
                        controller: scrollController,
                        slivers: [
                          SliverAppBar(
                            // snap: true,
                            //floating: true,
                            pinned: true,
                            stretch: true,
                            backgroundColor: context.readSettings.useBlur
                                ? Col.transp
                                : context.colors.realBackground.withAlpha(
                                    ((MediaQuery.of(context).size.height / 2 <=
                                                    scrollControllerOffset
                                                ? 1
                                                : scrollControllerOffset /
                                                      (MediaQuery.of(context)
                                                              .size
                                                              .height /
                                                          2)) *
                                            150)
                                        .toInt(),
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
                              child: Stack(
                                children: [
                                  Opacity(
                                    opacity:
                                        MediaQuery.of(context).size.height /
                                                3 <=
                                            scrollControllerOffset
                                        ? 1
                                        : scrollControllerOffset /
                                              (MediaQuery.of(context)
                                                      .size
                                                      .height /
                                                  3),
                                    child: liquidGlassBackground(
                                      child: BackdropFilter(
                                        filter: nonAppleBlur(context, 10),
                                        child: Container(),
                                      ),
                                    ),
                                  ),
                                  FlexibleSpaceBar(
                                    centerTitle: true,
                                    title: Text(
                                      AppLocalizations.of(context)
                                          .favouritesongs,
                                      style: TextStyle(
                                        fontSize: kIsApple ? 25 : 30,
                                        fontWeight: kIsApple
                                            ? FontWeight.w700
                                            : FontWeight.w800,
                                        color: context.colors.text,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                    ),
                                    stretchModes: const [
                                      StretchMode.zoomBackground,
                                      StretchMode.blurBackground,
                                      StretchMode.fadeTitle,
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: StickyHeaderDelegate(
                              minHeight: 40,
                              maxHeight: 40,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 15,
                                  right: 15,
                                  top: 5,
                                ),
                                child: liquidGlassBackground(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(60),
                                      color: context.readSettings.useBlur
                                          ? Col.transp
                                          : context.colors.realBackground
                                                .withAlpha(Dimens.noBlur),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(60),
                                      child: BackdropFilter(
                                        filter: appBlur(context, 10),
                                        child: PlayShuffleHaltFavourites(
                                          missingTracks: favouritesItemManager
                                              .missingTracks,
                                          loadingShuffle: favouritesItemManager
                                              .loadingShuffle,
                                          edit: favouritesItemManager.edit,
                                          frontWidget: iconButton(
                                            AppIcons.heart,
                                            context.colors.icon,
                                            () {
                                              context
                                                      .shell
                                                      .navigationBarIndex
                                                      .value =
                                                  0;
                                              context.shell.searchFocusNode
                                                  .requestFocus();
                                            },
                                            edgeInsets: EdgeInsets.zero,
                                          ),
                                          endWidget: iconButton(
                                            AppIcons.edit,
                                            context.colors.icon,
                                            () async {
                                              if (favouritesItemManager
                                                  .isPlaying) {
                                                final CustomButton ok =
                                                    await haltAlert(context);
                                                if (ok !=
                                                        CustomButton
                                                            .positiveButton ||
                                                    !context.mounted) {
                                                  return;
                                                }
                                                context
                                                        .shell
                                                        .currentTrackHeight
                                                        .value =
                                                    0;
                                                await favouritesItemManager
                                                    .haltIfPlaying();
                                              }
                                              favouritesItemManager.changeEdit(
                                                editing: true,
                                              );
                                            },
                                            edgeInsets: EdgeInsets.zero,
                                          ),
                                          play: () {
                                            favouritesItemManager.play(
                                              index: 0,
                                            );
                                          },
                                          shuffle:
                                              favouritesItemManager.playShuffle,
                                          stopEdit: () {
                                            favouritesItemManager.changeEdit(
                                              editing: false,
                                            );
                                            favouritesItemManager
                                                .clearSelectedTrack();
                                          },
                                          download: () async {
                                            final handler =
                                                await favouritesItemManager
                                                    .downloadSelected();
                                            if (handler != null &&
                                                context.mounted) {
                                              OpenPlaylist().show(
                                                context,
                                                handler,
                                              );
                                            }
                                          },
                                          unfavourite: () async {
                                            if (favouritesItemManager
                                                .selectedTracks
                                                .isNotEmpty) {
                                              final CustomButton ok =
                                                  await removeFavouriteAlert(
                                                    context,
                                                  );
                                              if (ok ==
                                                  CustomButton.positiveButton) {
                                                await favouritesItemManager
                                                    .removeSelected();
                                              }
                                            }
                                          },
                                          addToPlaylist: () {
                                            final handler =
                                                favouritesItemManager
                                                    .addSelectedToPlaylist();
                                            if (handler != null) {
                                              OpenPlaylist().show(
                                                context,
                                                handler,
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child:
                                  favouritesItemManager.favourites.isNotEmpty ||
                                      favouritesItemManager.lengthOfFavourites <
                                          1
                                  ? SizedBox(
                                      key: const ValueKey(true),
                                      child:
                                          favouritesItemManager
                                              .favourites
                                              .isEmpty
                                          ? Center(
                                              child: Column(
                                                children: [
                                                  razh(150),
                                                  iconButton(
                                                    AppIcons.heartFill,
                                                    context.colors.icon,
                                                    () {
                                                      context
                                                              .shell
                                                              .navigationBarIndex
                                                              .value =
                                                          0;
                                                      context
                                                          .shell
                                                          .searchFocusNode
                                                          .requestFocus();
                                                    },
                                                    size: 60,
                                                  ),
                                                  textButton(
                                                    AppLocalizations.of(
                                                      context,
                                                    ).findyourfavouritesongsnow,
                                                    () {
                                                      context
                                                              .shell
                                                              .navigationBarIndex
                                                              .value =
                                                          0;
                                                      context
                                                          .shell
                                                          .searchFocusNode
                                                          .requestFocus();
                                                    },
                                                    TextStyle(
                                                      color:
                                                          context.colors.text,
                                                    ),
                                                    edgeInsets: EdgeInsets.zero,
                                                  ),
                                                ],
                                              ),
                                            )
                                          : FavouritesBodyPhone(
                                              favourites: favouritesItemManager
                                                  .favourites,
                                              numberOfSTIDS:
                                                  favouritesItemManager
                                                      .favourites
                                                      .length,
                                              missingTracks:
                                                  favouritesItemManager
                                                      .missingTracks,
                                              loading:
                                                  favouritesItemManager.loading,
                                              edit: favouritesItemManager.edit,
                                              play: (index) {
                                                favouritesItemManager.play(
                                                  index: index,
                                                );
                                              },
                                              selectedTracks:
                                                  favouritesItemManager
                                                      .selectedTracks,
                                              select:
                                                  favouritesItemManager.select,
                                            ),
                                    )
                                  : SingleChildScrollView(
                                      key: const ValueKey(false),
                                      child: Column(
                                        children: [
                                          ListView.builder(
                                            itemCount: favouritesItemManager
                                                .lengthOfFavourites,
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemBuilder: (context, index) {
                                              return songTileSchimmer(
                                                context,
                                                index == 0,
                                                index ==
                                                    favouritesItemManager
                                                            .lengthOfFavourites -
                                                        1,
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : loadingScaffold(context, const ValueKey(false)),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../data/repositories/library/library_sync.dart';
import '../../../../../data/services/media/blurhash_service.dart';
import '../../../../../domain/models/playlists/playlist_handler.dart';
import '../../../../../domain/models/playlists/user_playlist.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../routing/navigation.dart';
import '../../../../../utils/platform.dart';
import '../../../../app/view_models/app_settings_view_model.dart';
import '../../../../core/app_icons.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/themes/dimens.dart';
import '../../../../core/ui/app_blur.dart';
import '../../../../core/ui/buttons/text_button.dart';
import '../../../../core/ui/phone/action_sheets/continue_cancel_action_sheet.dart';
import '../../../../core/ui/phone/buttons/back_button.dart';
import '../../../../core/ui/phone/buttons/back_like_button.dart';
import '../../../../core/ui/phone/buttons/icon_button.dart';
import '../../../../core/ui/phone/liquid_glass_background.dart';
import '../../../../core/ui/phone/loading_scaffold.dart';
import '../../../../core/ui/space.dart';
import '../../../view_models/open_playlist.dart';
import '../../../view_models/user_playlists_view_model.dart';
import '../playlist_tile.dart';
import 'online_playlist_phone.dart';

class OnlinePlaylistsPhone extends StatefulWidget {
  const OnlinePlaylistsPhone({super.key});

  @override
  State<OnlinePlaylistsPhone> createState() => _OnlinePlaylistsPhoneState();
}

class _OnlinePlaylistsPhoneState extends State<OnlinePlaylistsPhone> {
  late final UserPlaylistsViewModel viewModel;

  // Scroll controller
  final scrollController = ScrollController();

  // Offset
  double scrollControllerOffset = 0;

  bool get showBody => viewModel.showBody;
  int get playlistsLength => viewModel.playlistsLength;
  List<UserPlaylist> get playlists => viewModel.playlists;

  @override
  void initState() {
    super.initState();
    viewModel = UserPlaylistsViewModel(
      type: PlaylistHandlerType.online,
      playlists: context.read(),
      libraryChanges: context.read<LibrarySync>(),
    );
    viewModel.addListener(_onViewModelChanged);
    scrollController.addListener(scrollControllerListener);
  }

  void _onViewModelChanged() => setState(() {});

  void scrollControllerListener() {
    setState(() {
      scrollControllerOffset = scrollController.offset < 0
          ? 0
          : scrollController.offset;
    });
  }

  @override
  void dispose() {
    viewModel.removeListener(_onViewModelChanged);
    viewModel.dispose();
    scrollController.removeListener(scrollControllerListener);
    scrollController.dispose();
    super.dispose();
  }

  Future<String> _blurhashOf(UserPlaylist playlist) async {
    final cover = playlist.cover;
    if (cover == null) return context.colors.defaultBlurhash;
    return context.read<BlurhashService>().encodeBytes(cover, detailed: false);
  }

  void newPlaylist() {
    OpenPlaylist().show(
      context,
      const PlaylistHandler(
        type: PlaylistHandlerType.online,
        function: PlaylistHandlerFunction.createPlaylist,
        track: null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
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
                body: Scrollbar(
                  controller: scrollController,
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      SliverAppBar(
                        //snap: true,
                        //floating: true,
                        pinned: true,
                        stretch: true,
                        backgroundColor: context.readSettings.useBlur
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
                            backLikeButton(context, AppIcons.add, newPlaylist),
                          ],
                        ),
                        flexibleSpace: ClipRRect(
                          child: Stack(
                            children: [
                              Opacity(
                                opacity:
                                    MediaQuery.of(context).size.height / 3 <=
                                        scrollControllerOffset
                                    ? 1
                                    : scrollControllerOffset /
                                          (MediaQuery.of(context).size.height /
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
                                  AppLocalizations.of(context).onlineplaylists,
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
                      SliverToBoxAdapter(
                        child: playlists.isNotEmpty
                            ? Column(
                                children: [
                                  ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: playlists.length,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          top: index == 0
                                              ? AppBar().preferredSize.height *
                                                    1.5
                                              : 0,
                                          bottom: index == playlists.length - 1
                                              ? MediaQuery.of(context)
                                                        .padding
                                                        .bottom +
                                                    10
                                              : 0,
                                        ),
                                        child: PlaylistTile(
                                          first: index == 0,
                                          last: index == playlists.length - 1,
                                          cover: playlists[index].cover,
                                          title: playlists[index].title,
                                          subtitle: AppLocalizations.of(context)
                                              .onlineplaylist,
                                          function: () async {
                                            final String blurHash =
                                                await _blurhashOf(
                                                  playlists[index],
                                                );
                                            if (!context.mounted) return;

                                            Navigations().nextScreen(
                                              context,
                                              OnlinePlaylistPhone(
                                                opid: playlists[index].id,
                                                title: playlists[index].title,
                                                cover:
                                                    playlists[index].cover ==
                                                        null
                                                    ? null
                                                    : MemoryImage(
                                                        playlists[index].cover!,
                                                      ),
                                                blurhash: blurHash,
                                                updateCover: (playlistCover) =>
                                                    viewModel.updateCover(
                                                      index,
                                                      playlistCover.bytes,
                                                    ),
                                                updateTitle: (newTitle) =>
                                                    viewModel.load(),
                                              ),
                                            );
                                          },
                                          removePlaylist: () {
                                            continueCancelActionSheet(
                                              context,
                                              AppLocalizations.of(context)
                                                  .areyousure,
                                              AppLocalizations.of(context)
                                                  .removeplaylist,
                                              () => viewModel.remove(index),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  razh(100),
                                  iconButton(
                                    AppIcons.add,
                                    context.colors.icon,
                                    newPlaylist,
                                    size: 60,
                                  ),
                                  textButton(
                                    AppLocalizations.of(context)
                                        .createnewplaylistnow,
                                    newPlaylist,
                                    TextStyle(color: context.colors.text),
                                    edgeInsets: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : loadingScaffold(context, const ValueKey(false)),
    );
  }
}

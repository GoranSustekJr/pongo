import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
import '../../../../core/ui/phone/loading_scaffold.dart';
import '../../../../core/ui/space.dart';
import '../../../view_models/open_playlist.dart';
import '../../../view_models/user_playlists_view_model.dart';
import '../playlist_tile.dart';
import 'local_playlist_phone.dart';

class LocalPlaylistsPhone extends StatefulWidget {
  const LocalPlaylistsPhone({super.key});

  @override
  State<LocalPlaylistsPhone> createState() => _LocalPlaylistsPhoneState();
}

class _LocalPlaylistsPhoneState extends State<LocalPlaylistsPhone> {
  late final UserPlaylistsViewModel viewModel;

  bool get showBody => viewModel.showBody;
  int get playlistsLength => viewModel.playlistsLength;
  List<UserPlaylist> get playlists => viewModel.playlists;

  @override
  void initState() {
    super.initState();
    viewModel = UserPlaylistsViewModel(
      type: PlaylistHandlerType.offline,
      playlists: context.read(),
    );
    viewModel.addListener(_onViewModelChanged);
  }

  void _onViewModelChanged() => setState(() {});

  @override
  void dispose() {
    viewModel.removeListener(_onViewModelChanged);
    viewModel.dispose();
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
        type: PlaylistHandlerType.offline,
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
                body: CustomScrollView(
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
                          backLikeButton(
                            context,
                            CupertinoIcons.add,
                            newPlaylist,
                          ),
                        ],
                      ),
                      flexibleSpace: ClipRRect(
                        child: BackdropFilter(
                          filter: appBlur(context, 10),
                          child: FlexibleSpaceBar(
                            centerTitle: true,
                            title: Text(
                              AppLocalizations.of(context).offlineplaylists,
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
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: playlists.isNotEmpty
                          ? Column(
                              children: [
                                ListView.builder(
                                  itemCount: playlists.length,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
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
                                            .offlineplaylist,
                                        function: () async {
                                          final String blurHash =
                                              await _blurhashOf(
                                                playlists[index],
                                              );
                                          if (!context.mounted) return;

                                          Navigations().nextScreen(
                                            context,
                                            LocalPlaylistPhone(
                                              lpid: playlists[index].id,
                                              title: playlists[index].title,
                                              cover:
                                                  playlists[index].cover == null
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
            )
          : loadingScaffold(context, const ValueKey(false)),
    );
  }
}

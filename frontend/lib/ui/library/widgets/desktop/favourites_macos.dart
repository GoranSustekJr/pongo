import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_desktop_context_menu/flutter_desktop_context_menu.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/library/library_sync.dart';
import '../../../../domain/models/playlists/playlist_handler.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/app_icons.dart';
import '../../../core/themes/colors.dart';
import '../../../core/ui/desktop/track_list_macos.dart';
import '../../../playlists/view_models/open_playlist.dart';
import '../../../shell/view_models/shell_view_model.dart';
import '../../view_models/favourites_view_model.dart';

/// The liked songs, as a playlist in the content area of the Mac window.
class FavouritesMacos extends StatefulWidget {
  /// Creates the favourites page.
  const FavouritesMacos({super.key});

  @override
  State<FavouritesMacos> createState() => _FavouritesMacosState();
}

class _FavouritesMacosState extends State<FavouritesMacos> {
  late final FavouritesViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = FavouritesViewModel(
      favourites: context.read(),
      downloads: context.read(),
      catalog: context.read(),
      player: context.read(),
      libraryChanges: context.read<LibrarySync>(),
    );
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  // Selects every favourite and returns what [action] makes of them
  Future<PlaylistHandler?> _forAll(
    FutureOr<PlaylistHandler?> Function() action,
  ) async {
    viewModel.clearSelectedTrack();
    for (final track in viewModel.favourites) {
      viewModel.select(track.id);
    }
    final handler = await action();
    viewModel.clearSelectedTrack();
    return handler;
  }

  Future<void> _open(FutureOr<PlaylistHandler?> Function() action) async {
    final handler = await _forAll(action);
    if (handler != null && mounted) OpenPlaylist().show(context, handler);
  }

  Future<void> _remove(String stid) async {
    viewModel.clearSelectedTrack();
    viewModel.select(stid);
    await viewModel.removeSelected();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MacosScaffold(
      backgroundColor: Col.transp,
      children: [
        ContentArea(
          builder: (context, scrollController) => ListenableBuilder(
            listenable: viewModel,
            builder: (context, _) {
              if (!viewModel.showBody) {
                return const Center(child: ProgressCircle());
              }
              final tracks = viewModel.favourites;
              if (tracks.isEmpty) {
                return EmptyStateMacos(
                  icon: CupertinoIcons.heart,
                  title: l10n.findyourfavouritesongsnow,
                  action: PushButton(
                    controlSize: ControlSize.large,
                    onPressed: () => context.shell.navigationBarIndex.value = 0,
                    child: Text(l10n.search),
                  ),
                );
              }
              final loading = viewModel.loading;
              return ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: tracks.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return CollectionHeaderMacos(
                      artwork: const CollectionArtworkMacos(
                        icon: CupertinoIcons.heart_fill,
                      ),
                      kind: l10n.playlist,
                      title: l10n.favouritesongs,
                      subtitle: '${tracks.length} ${l10n.plustracks}',
                      onPlay: viewModel.play,
                      onShuffle: viewModel.missingTracks.isEmpty
                          ? viewModel.playShuffle
                          : null,
                      actions: [
                        MacosPulldownButton(
                          icon: AppIcons.more,
                          items: [
                            MacosPulldownMenuItem(
                              title: Text(l10n.download),
                              onTap: () => _open(viewModel.downloadSelected),
                            ),
                            MacosPulldownMenuItem(
                              title: Text(l10n.addtoplaylist),
                              onTap: () =>
                                  _open(viewModel.addSelectedToPlaylist),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                  final track = tracks[index - 1];
                  final seconds = viewModel.existingTracks[track.id];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TrackRowMacos(
                      key: ValueKey(track.id),
                      index: index - 1,
                      track: track,
                      duration: seconds == null
                          ? null
                          : Duration(milliseconds: (seconds * 1000).round()),
                      loading: loading.contains(track.id),
                      onPlay: () => viewModel.play(index: index - 1),
                      onMenu: () => showTrackMenuMacos(
                        context,
                        track,
                        collectionId: FavouritesViewModel.collectionId,
                        like: false,
                        extra: [
                          MenuItem(
                            label: l10n.removefromfavourites,
                            onClick: (_) => _remove(track.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

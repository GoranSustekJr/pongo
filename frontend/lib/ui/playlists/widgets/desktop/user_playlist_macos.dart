import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ReorderableListView;
import 'package:flutter_desktop_context_menu/flutter_desktop_context_menu.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/playlists/playlist_handler.dart';
import '../../../../domain/models/playlists/user_playlist.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/app_icons.dart';
import '../../../core/ui/desktop/track_list_macos.dart';
import '../../view_models/local_playlist_view_model.dart';
import '../../view_models/online_playlist_view_model.dart';
import '../../view_models/open_playlist.dart';
import '../../view_models/user_playlist_view_model.dart';
import '../phone/pick_cover.dart';

/// One of the user's playlists, in the content area of the Mac window.
///
/// Tracks can be dragged into a new order while the playlist isn't playing.
class UserPlaylistMacos extends StatefulWidget {
  /// Creates the page of [playlist], an online or offline one by [type].
  const UserPlaylistMacos({
    super.key,
    required this.type,
    required this.playlist,
    required this.onDelete,
  });

  /// Whether the playlist holds catalog tracks or downloaded ones.
  final PlaylistHandlerType type;

  /// The playlist shown.
  final UserPlaylist playlist;

  /// Deletes the playlist and closes the page.
  final Future<void> Function() onDelete;

  @override
  State<UserPlaylistMacos> createState() => _UserPlaylistMacosState();
}

class _UserPlaylistMacosState extends State<UserPlaylistMacos> {
  late final UserPlaylistViewModel viewModel;

  bool get online => widget.type == PlaylistHandlerType.online;

  @override
  void initState() {
    super.initState();
    final playlist = widget.playlist;
    // Covers only tint the phone's background, which the Mac doesn't have
    viewModel = online
        ? OnlinePlaylistViewModel(
            id: playlist.id,
            title: playlist.title,
            cover: playlist.cover,
            blurhash: '',
            playlists: context.read(),
            player: context.read(),
            blurhashService: context.read(),
            catalog: context.read(),
            downloads: context.read(),
          )
        : LocalPlaylistViewModel(
            id: playlist.id,
            title: playlist.title,
            cover: playlist.cover,
            blurhash: '',
            playlists: context.read(),
            player: context.read(),
            blurhashService: context.read(),
          );
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  // Runs [action] on just the track with [stid]
  Future<void> _withOnly(String stid, FutureOr<void> Function() action) async {
    viewModel.stopEdit();
    viewModel.select(stid);
    await action();
    viewModel.stopEdit();
  }

  void _open(PlaylistHandler? handler) {
    if (handler != null) OpenPlaylist().show(context, handler);
  }

  Future<void> _rename() async {
    final l10n = AppLocalizations.of(context);
    final title = await promptTextMacos(
      context,
      title: l10n.changeplaylisttile,
      placeholder: l10n.playlistname,
      confirm: l10n.done,
      initial: viewModel.title,
    );
    if (title != null) await viewModel.rename(title);
  }

  Future<void> _changeCover() async {
    final bytes = await pickSquareCover(context);
    if (bytes != null) await viewModel.setCover(bytes);
  }

  Future<void> _downloadAll() async {
    final viewModel = this.viewModel;
    if (viewModel is! OnlinePlaylistViewModel) return;
    viewModel.selectAll();
    final handler = await viewModel.downloadSelected();
    viewModel.stopEdit();
    _open(handler);
  }

  Future<void> _deletePlaylist() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmMacos(
      context,
      title: viewModel.title,
      message: l10n.removeplaylist,
      confirm: l10n.delete,
    );
    if (confirmed) await widget.onDelete();
  }

  Future<void> _removeTrack(String stid) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmMacos(
      context,
      title: l10n.removefromplaylist,
      message: l10n.removetrackfromplaylist,
      confirm: l10n.delete,
    );
    if (!confirmed) return;
    // The playlist can't change while it's playing
    if (viewModel.isPlaying) await viewModel.startEdit(haltPlayback: true);
    await _withOnly(stid, viewModel.removeSelected);
  }

  Widget _header(AppLocalizations l10n) {
    final cover = viewModel.cover;
    final count = viewModel.tracks.length;
    final playable = viewModel.shownTracks.isNotEmpty;
    return CollectionHeaderMacos(
      artwork: cover == null
          ? CollectionArtworkMacos(
              icon: AppIcons.musicAlbums,
              colors: online
                  ? null
                  : const [
                      MacosColors.systemBlueColor,
                      MacosColors.systemTealColor,
                    ],
            )
          : Image.memory(cover, fit: BoxFit.cover),
      kind: online ? l10n.onlineplaylist : l10n.offlineplaylist,
      title: viewModel.title,
      subtitle: '$count ${l10n.plustracks}',
      onPlay: playable ? viewModel.play : null,
      onShuffle: playable ? viewModel.playShuffle : null,
      actions: [
        MacosPulldownButton(
          icon: AppIcons.more,
          items: [
            MacosPulldownMenuItem(title: Text(l10n.changename), onTap: _rename),
            MacosPulldownMenuItem(
              title: Text(l10n.changecover),
              onTap: _changeCover,
            ),
            if (online && count > 0)
              MacosPulldownMenuItem(
                title: Text(l10n.download),
                onTap: _downloadAll,
              ),
            const MacosPulldownMenuDivider(),
            MacosPulldownMenuItem(
              title: Text(l10n.delete),
              onTap: _deletePlaylist,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final viewModel = this.viewModel;
        if (!viewModel.showBody) {
          return const Center(child: ProgressCircle());
        }
        final tracks = viewModel.tracks;
        final loading = viewModel is OnlinePlaylistViewModel
            ? viewModel.loading
            : const <String>[];
        final reorderable = !viewModel.isPlaying;
        return ReorderableListView.builder(
          header: Column(
            children: [
              _header(l10n),
              if (tracks.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: EmptyStateMacos(
                    icon: AppIcons.musicAlbums,
                    title: l10n.addtrackstoyoutplaylist,
                  ),
                ),
            ],
          ),
          padding: const EdgeInsets.only(bottom: 24),
          buildDefaultDragHandles: false,
          itemCount: tracks.length,
          onReorder: viewModel.moveTrack,
          proxyDecorator: (child, _, _) => ColoredBox(
            color: MacosTheme.of(context).canvasColor.withAlpha(230),
            child: child,
          ),
          itemBuilder: (context, index) {
            final track = tracks[index];
            final hidden = viewModel.hidden[track.id] ?? false;
            final seconds = viewModel is OnlinePlaylistViewModel
                ? viewModel.existingTracks[track.id]
                : null;
            final Widget row = TrackRowMacos(
              index: index,
              track: track,
              hidden: hidden,
              duration: seconds == null
                  ? null
                  : Duration(milliseconds: (seconds * 1000).round()),
              loading: loading.contains(track.id),
              // Hidden tracks don't play, so they're left out of the index
              onPlay: hidden
                  ? () {}
                  : () => viewModel.play(
                      index: viewModel.shownTracks.indexOf(track),
                    ),
              onMenu: () => showTrackMenuMacos(
                context,
                track,
                collectionId: viewModel.collectionId,
                extra: [
                  if (!online)
                    MenuItem(
                      label: l10n.addtoplaylist,
                      onClick: (_) => _withOnly(
                        track.id,
                        () => _open(viewModel.addSelectedToPlaylist()),
                      ),
                    ),
                  MenuItem(
                    label: hidden ? l10n.show : l10n.hide,
                    onClick: (_) => _withOnly(
                      track.id,
                      hidden ? viewModel.showSelected : viewModel.hideSelected,
                    ),
                  ),
                  MenuItem(
                    label: l10n.removefromplaylist,
                    onClick: (_) => _removeTrack(track.id),
                  ),
                ],
              ),
            );
            return Padding(
              key: ValueKey(track.id),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: reorderable
                  ? ReorderableDragStartListener(index: index, child: row)
                  : row,
            );
          },
        );
      },
    );
  }
}

/// A playlist's cover in the grid: its picture or a placeholder.
class PlaylistCoverMacos extends StatelessWidget {
  /// Creates the cover of [playlist].
  const PlaylistCoverMacos({
    super.key,
    required this.playlist,
    required this.online,
  });

  /// The playlist whose cover is shown.
  final UserPlaylist playlist;

  /// Whether it's an online playlist, which sets the placeholder's colors.
  final bool online;

  @override
  Widget build(BuildContext context) {
    final cover = playlist.cover;
    if (cover != null) return Image.memory(cover, fit: BoxFit.cover);
    return CollectionArtworkMacos(
      icon: AppIcons.musicAlbums,
      colors: online
          ? null
          : const [MacosColors.systemBlueColor, MacosColors.systemTealColor],
    );
  }
}

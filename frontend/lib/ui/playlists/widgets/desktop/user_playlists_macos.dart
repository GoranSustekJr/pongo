import 'package:flutter/cupertino.dart';
import 'package:flutter_desktop_context_menu/flutter_desktop_context_menu.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/library/library_sync.dart';
import '../../../../domain/models/playlists/playlist_handler.dart';
import '../../../../domain/models/playlists/user_playlist.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/app_icons.dart';
import '../../../core/themes/colors.dart';
import '../../../core/ui/desktop/track_list_macos.dart';
import '../../view_models/open_playlist.dart';
import '../../view_models/user_playlists_view_model.dart';
import 'user_playlist_macos.dart';

/// The user's online or offline playlists as a grid of covers, in the
/// content area of the Mac window.
///
/// Opening one shows it in place, with a back button in the toolbar.
class UserPlaylistsMacos extends StatefulWidget {
  /// Creates the page of the playlists of [type].
  const UserPlaylistsMacos({super.key, required this.type});

  /// Whether the playlists hold catalog tracks or downloaded ones.
  final PlaylistHandlerType type;

  @override
  State<UserPlaylistsMacos> createState() => _UserPlaylistsMacosState();
}

class _UserPlaylistsMacosState extends State<UserPlaylistsMacos> {
  late final UserPlaylistsViewModel viewModel;

  /// The open playlist, or `null` while the grid is shown.
  UserPlaylist? open;

  bool get online => widget.type == PlaylistHandlerType.online;

  @override
  void initState() {
    super.initState();
    viewModel = UserPlaylistsViewModel(
      type: widget.type,
      playlists: context.read(),
      libraryChanges: context.read<LibrarySync>(),
    );
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  void _create() => OpenPlaylist().show(
    context,
    PlaylistHandler(
      type: widget.type,
      function: PlaylistHandlerFunction.createPlaylist,
      track: null,
    ),
  );

  void _close() {
    setState(() => open = null);
    // Picks up a new title or cover
    viewModel.load();
  }

  Future<void> _delete(UserPlaylist playlist) async {
    final index = viewModel.playlists.indexOf(playlist);
    if (index >= 0) await viewModel.remove(index);
  }

  Future<void> _confirmDelete(UserPlaylist playlist) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmMacos(
      context,
      title: playlist.title,
      message: l10n.removeplaylist,
      confirm: l10n.delete,
    );
    if (confirmed) await _delete(playlist);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = online ? l10n.onlineplaylists : l10n.offlineplaylists;
    final open = this.open;
    return MacosScaffold(
      backgroundColor: Col.transp,
      toolBar: ToolBar(
        title: Text(open?.title ?? title),
        titleWidth: 300,
        decoration: const BoxDecoration(color: Col.transp),
        enableBlur: true,
        automaticallyImplyLeading: false,
        leading: open == null
            ? null
            : MacosBackButton(onPressed: _close, fillColor: Col.transp),
        actions: [
          ToolBarIconButton(
            label: l10n.newplaylist,
            tooltipMessage: l10n.newplaylist,
            icon: const MacosIcon(CupertinoIcons.add),
            showLabel: false,
            onPressed: _create,
          ),
        ],
      ),
      children: [
        ContentArea(
          builder: (context, scrollController) {
            if (open != null) {
              return UserPlaylistMacos(
                key: ValueKey(open.id),
                type: widget.type,
                playlist: open,
                onDelete: () async {
                  await _delete(open);
                  if (mounted) setState(() => this.open = null);
                },
              );
            }
            return ListenableBuilder(
              listenable: viewModel,
              builder: (context, _) {
                if (!viewModel.showBody) {
                  return const Center(child: ProgressCircle());
                }
                final playlists = viewModel.playlists;
                if (playlists.isEmpty) {
                  return EmptyStateMacos(
                    icon: AppIcons.musicAlbums,
                    title: l10n.createnewplaylistnow,
                    action: PushButton(
                      controlSize: ControlSize.large,
                      onPressed: _create,
                      child: Text(l10n.newplaylist),
                    ),
                  );
                }
                return GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 20,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return _PlaylistTile(
                      key: ValueKey(playlist.id),
                      playlist: playlist,
                      online: online,
                      onOpen: () => setState(() => this.open = playlist),
                      onMenu: () => popUpContextMenu(
                        Menu(
                          items: [
                            MenuItem(
                              label: l10n.delete,
                              onClick: (_) => _confirmDelete(playlist),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _PlaylistTile extends StatefulWidget {
  const _PlaylistTile({
    super.key,
    required this.playlist,
    required this.online,
    required this.onOpen,
    required this.onMenu,
  });

  final UserPlaylist playlist;
  final bool online;
  final VoidCallback onOpen;
  final VoidCallback onMenu;

  @override
  State<_PlaylistTile> createState() => _PlaylistTileState();
}

class _PlaylistTileState extends State<_PlaylistTile> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    final l10n = AppLocalizations.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: GestureDetector(
        onTap: widget.onOpen,
        onSecondaryTap: widget.onMenu,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: AnimatedScale(
                scale: hovering ? 1.03 : 1,
                duration: const Duration(milliseconds: 150),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: MacosColors.black.withAlpha(hovering ? 90 : 50),
                        blurRadius: hovering ? 16 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: PlaylistCoverMacos(
                      playlist: widget.playlist,
                      online: widget.online,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.playlist.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.online ? l10n.onlineplaylist : l10n.offlineplaylist,
              maxLines: 1,
              style: theme.typography.subheadline.copyWith(
                color: secondaryTextMacos,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

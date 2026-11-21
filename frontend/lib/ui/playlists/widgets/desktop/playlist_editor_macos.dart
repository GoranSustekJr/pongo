import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/playlists/playlist_handler.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/app_icons.dart';
import '../../../core/ui/desktop/track_list_macos.dart';
import '../../../core/ui/image/image_compatible.dart';
import '../../view_models/playlist_handler_view_model.dart';
import '../phone/pick_cover.dart';

/// Adds tracks to the user's playlists, or makes a new playlist for them, in
/// a Mac sheet.
///
/// The sheet closes itself when it's done or cancelled.
class PlaylistEditorMacos extends StatefulWidget {
  /// Creates the editor for [playlistHandler].
  const PlaylistEditorMacos({super.key, required this.playlistHandler});

  /// What the editor was opened to do.
  final PlaylistHandler playlistHandler;

  @override
  State<PlaylistEditorMacos> createState() => _PlaylistEditorMacosState();
}

class _PlaylistEditorMacosState extends State<PlaylistEditorMacos> {
  late final PlaylistHandlerViewModel viewModel;
  final titleController = TextEditingController();

  /// Whether a new playlist is being made rather than chosen.
  late bool creating =
      widget.playlistHandler.function == PlaylistHandlerFunction.createPlaylist;

  /// The new playlist's cover: a URL, or the path of a picked image.
  String? cover;

  bool get online => widget.playlistHandler.type == PlaylistHandlerType.online;

  @override
  void initState() {
    super.initState();
    viewModel = PlaylistHandlerViewModel(
      handler: widget.playlistHandler,
      playlists: context.read(),
      downloads: context.read(),
      images: context.read(),
      messages: context.read(),
    );
    cover = viewModel.suggestedCover;
  }

  @override
  void dispose() {
    viewModel.dispose();
    titleController.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  Future<void> _pickCover() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;
    final square = await squareCover(context, picked.path, 500);
    if (square != null) setState(() => cover = square.path);
  }

  Future<void> _save() async {
    final done = creating
        ? await viewModel.createPlaylist(titleController.text, cover: cover)
        : await viewModel.addToSelectedPlaylists();
    if (done && mounted) _close();
  }

  Widget _coverPreview() {
    final cover = this.cover;
    final Widget image = cover == null || cover.isEmpty
        ? const CollectionArtworkMacos(icon: AppIcons.musicAlbums)
        : cover.startsWith('http') || cover.startsWith('file://')
        ? ImageCompatible(image: cover)
        : Image.file(File(cover), fit: BoxFit.cover);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox.square(dimension: 96, child: image),
    );
  }

  Widget _create(AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            _coverPreview(),
            const SizedBox(height: 8),
            PushButton(
              controlSize: ControlSize.regular,
              secondary: true,
              onPressed: _pickCover,
              child: Text(l10n.changecover),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: MacosTextField(
            controller: titleController,
            placeholder: l10n.playlistname,
            autofocus: true,
            onSubmitted: (_) => _save(),
          ),
        ),
      ],
    );
  }

  Widget _choose(AppLocalizations l10n) {
    final theme = MacosTheme.of(context);
    final trackIds = [
      for (final track in widget.playlistHandler.track ?? const []) track.id,
    ];
    final playlists = viewModel.currentPlaylists;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: playlists.isEmpty
              ? Center(
                  child: Text(
                    l10n.createnewplaylistnow,
                    style: theme.typography.body.copyWith(
                      color: secondaryTextMacos,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    final contained =
                        viewModel.playlistTracks[playlist.id] ?? const {};
                    final already = trackIds.every(contained.contains);
                    final selected = viewModel.selectedPlaylists.contains(
                      playlist.id,
                    );
                    final cover = playlist.cover;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: already
                            ? null
                            : () => viewModel.selectPlaylist(playlist.id),
                        child: Opacity(
                          opacity: already ? 0.5 : 1,
                          child: Row(
                            children: [
                              MacosCheckbox(
                                value: already || selected,
                                onChanged: already
                                    ? null
                                    : (_) =>
                                          viewModel.selectPlaylist(playlist.id),
                              ),
                              const SizedBox(width: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: SizedBox.square(
                                  dimension: 32,
                                  child: cover == null
                                      ? const CollectionArtworkMacos(
                                          icon: AppIcons.musicAlbums,
                                        )
                                      : Image.memory(cover, fit: BoxFit.cover),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  playlist.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.typography.body,
                                ),
                              ),
                              if (already)
                                Text(
                                  l10n.alreadyinplaylist,
                                  style: theme.typography.caption1.copyWith(
                                    color: secondaryTextMacos,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 8),
        PushButton(
          controlSize: ControlSize.regular,
          secondary: true,
          onPressed: () => setState(() => creating = true),
          child: Text(l10n.createnewplaylist),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = MacosTheme.of(context);
    final size = MediaQuery.sizeOf(context);
    final height = creating ? 260.0 : 440.0;
    return MacosSheet(
      insetPadding: EdgeInsets.symmetric(
        horizontal: (size.width - 460).clamp(0, double.infinity) / 2,
        vertical: (size.height - height).clamp(0, double.infinity) / 2,
      ),
      child: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                creating
                    ? (online ? l10n.newplaylist : l10n.newplaylistlocal)
                    : l10n.addtoplaylist,
                style: theme.typography.headline,
              ),
              const SizedBox(height: 16),
              Expanded(child: creating ? _create(l10n) : _choose(l10n)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (viewModel.working) ...[
                    const ProgressCircle(radius: 8),
                    const SizedBox(width: 12),
                  ],
                  PushButton(
                    controlSize: ControlSize.large,
                    secondary: true,
                    onPressed: _close,
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 8),
                  PushButton(
                    controlSize: ControlSize.large,
                    onPressed: viewModel.working ? null : _save,
                    child: Text(creating ? l10n.create : l10n.done),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

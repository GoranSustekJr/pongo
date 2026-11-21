import 'package:flutter/cupertino.dart';
import 'package:flutter_desktop_context_menu/flutter_desktop_context_menu.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/catalog/track.dart';
import '../../../../domain/models/settings/app_settings.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../app/view_models/app_settings_view_model.dart';
import '../../../core/themes/colors.dart';
import '../../../core/ui/desktop/track_list_macos.dart';
import '../../../playlists/view_models/open_playlist.dart';
import '../../view_models/locals_view_model.dart';

/// The downloaded songs, in the content area of the Mac window.
class LocalsMacos extends StatefulWidget {
  /// Creates the downloaded songs page.
  const LocalsMacos({super.key});

  @override
  State<LocalsMacos> createState() => _LocalsMacosState();
}

class _LocalsMacosState extends State<LocalsMacos> {
  late final LocalsViewModel viewModel;
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    viewModel = LocalsViewModel(
      downloads: context.read(),
      settings: context.read(),
      player: context.read(),
    );
  }

  @override
  void dispose() {
    viewModel.dispose();
    searchController.dispose();
    super.dispose();
  }

  String _sortLabel(AppLocalizations l10n, LocalsSort sort) => switch (sort) {
    LocalsSort.firstAdded => l10n.firstadded,
    LocalsSort.lastAdded => l10n.lastadded,
    LocalsSort.titleAscending ||
    LocalsSort.titleDescending => sort.storageValue,
  };

  void _addToPlaylist(Track track) {
    viewModel.stopEdit();
    viewModel.select(track.id);
    final handler = viewModel.addSelectedToPlaylist();
    viewModel.stopEdit();
    if (handler != null) OpenPlaylist().show(context, handler);
  }

  Future<void> _remove(Track track) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmMacos(
      context,
      title: l10n.removefromdownloaded,
      message: l10n.removefromdownloadedbody,
      confirm: l10n.delete,
    );
    if (!confirmed) return;
    // The downloads can't change while they're playing
    await viewModel.startEdit(haltPlayback: viewModel.isPlaying);
    viewModel.select(track.id);
    await viewModel.removeSelected();
  }

  Widget _header(AppLocalizations l10n, int count) {
    return CollectionHeaderMacos(
      artwork: const CollectionArtworkMacos(
        icon: CupertinoIcons.arrow_down_circle_fill,
        colors: [MacosColors.systemBlueColor, MacosColors.systemTealColor],
      ),
      kind: l10n.offline,
      title: l10n.offlinesongs,
      subtitle: '$count ${l10n.plustracks}',
      onPlay: count == 0 ? null : viewModel.play,
      onShuffle: count == 0 ? null : viewModel.shuffle,
      actions: [
        MacosPopupButton<LocalsSort>(
          value: context.settings.localsSort,
          items: [
            for (final sort in LocalsSort.values)
              MacosPopupMenuItem(
                value: sort,
                child: Text(_sortLabel(l10n, sort)),
              ),
          ],
          onChanged: (sort) {
            if (sort != null) viewModel.sort(sort);
          },
        ),
        SizedBox(
          width: 200,
          child: MacosSearchField<void>(
            controller: searchController,
            placeholder: l10n.search,
            onChanged: viewModel.onSearched,
          ),
        ),
      ],
    );
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
              if (viewModel.tracksBackup.isEmpty) {
                return EmptyStateMacos(
                  icon: CupertinoIcons.arrow_down_circle,
                  title: l10n.downloadtracksnow,
                );
              }
              final tracks = viewModel.tracks;
              return ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: tracks.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _header(l10n, viewModel.tracksBackup.length);
                  }
                  final track = tracks[index - 1];
                  final milliseconds = viewModel.durations[track.id];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TrackRowMacos(
                      key: ValueKey(track.id),
                      index: index - 1,
                      track: track,
                      duration: milliseconds == null
                          ? null
                          : Duration(milliseconds: milliseconds),
                      onPlay: () => viewModel.play(index: index - 1),
                      onMenu: () => showTrackMenuMacos(
                        context,
                        track,
                        collectionId: LocalsViewModel.collectionId,
                        extra: [
                          MenuItem(
                            label: l10n.addtoplaylist,
                            onClick: (_) => _addToPlaylist(track),
                          ),
                          MenuItem(
                            label: l10n.removefromdownloaded,
                            onClick: (_) => _remove(track),
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

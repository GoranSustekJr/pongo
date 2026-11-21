import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_desktop_context_menu/flutter_desktop_context_menu.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../domain/models/catalog/track.dart';
import '../../../../domain/models/playlists/playlist_handler.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../utils/image_resolution.dart';
import '../../../player/view_models/player_view_model.dart';
import '../../../playlists/view_models/open_playlist.dart';
import '../../app_icons.dart';
import '../../view_models/track_actions_view_model.dart';
import '../image/image_compatible.dart';

/// Secondary text on the window's dark gradient, where macOS' own secondary
/// label colour is too dark to read.
const secondaryTextMacos = Color(0xA6FFFFFF);

/// Formats [duration] like the Music app, such as 3:07 or 1:02:45.
String formatTrackDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString();
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (duration.inHours == 0) return '$minutes:$seconds';
  return '${duration.inHours}:${minutes.padLeft(2, '0')}:$seconds';
}

/// The artwork of [track]: the album cover, or the saved cover of a
/// downloaded track.
class TrackArtworkMacos extends StatelessWidget {
  /// Creates a square artwork of [size] points.
  const TrackArtworkMacos({super.key, required this.track, this.size = 36});

  /// The track whose artwork is shown.
  final Track track;

  /// The width and height.
  final double size;

  @override
  Widget build(BuildContext context) {
    final localImage = track.image?.path;
    final url = imageUrlForSize(
      track.album?.images ?? const [],
      (size * 2).round(),
      (size * 2).round(),
    );
    final Widget image = localImage != null
        ? Image.file(File(localImage), fit: BoxFit.cover)
        : url.isNotEmpty
        ? ImageCompatible(image: url, width: size, height: size)
        : ColoredBox(
            color: MacosColors.systemGrayColor.withAlpha(60),
            child: Icon(
              AppIcons.blankTrack,
              size: size / 2,
              color: MacosColors.systemGrayColor,
            ),
          );
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 9),
      child: SizedBox.square(dimension: size, child: image),
    );
  }
}

/// The right click menu of [track], with [extra] items for the list it's in.
///
/// [collectionId] marks the queue entries the menu adds. Lists of
/// favourites leave out [like], since they offer their own way to remove one.
Future<void> showTrackMenuMacos(
  BuildContext context,
  Track track, {
  required String collectionId,
  bool like = true,
  List<MenuItem> extra = const [],
}) async {
  final l10n = AppLocalizations.of(context);
  final actions = context.trackActions;
  final favourite = await actions.isFavourite(track.id);
  if (!context.mounted) return;
  await popUpContextMenu(
    Menu(
      items: [
        MenuItem(
          label: l10n.firsttoqueue,
          onClick: (_) => actions.addNext(track, collectionId: collectionId),
        ),
        MenuItem(
          label: l10n.lasttoqueue,
          onClick: (_) => actions.addLast(track, collectionId: collectionId),
        ),
        MenuItem.separator(),
        if (like)
          MenuItem(
            label: favourite ? l10n.unlike : l10n.like,
            onClick: (_) => actions.toggleFavourite(track),
          ),
        if (track.type == TrackType.online) ...[
          MenuItem(
            label: l10n.download,
            onClick: (_) => actions.download(track),
          ),
          MenuItem(
            label: l10n.addtoplaylist,
            onClick: (_) => OpenPlaylist().show(
              context,
              PlaylistHandler(
                type: PlaylistHandlerType.online,
                function: PlaylistHandlerFunction.addToPlaylist,
                track: [onlineHandlerTrack(track)],
              ),
            ),
          ),
        ],
        if (extra.isNotEmpty) ...[MenuItem.separator(), ...extra],
      ],
    ),
  );
}

/// A row of a track list, like a song in the Music app.
///
/// Double clicking plays the track and right clicking calls [onMenu].
class TrackRowMacos extends StatefulWidget {
  /// Creates the row of [track] at [index].
  const TrackRowMacos({
    super.key,
    required this.index,
    required this.track,
    required this.onPlay,
    required this.onMenu,
    this.duration,
    this.available = true,
    this.hidden = false,
    this.loading = false,
  });

  /// The position in the list, counting from 0.
  final int index;

  /// The track shown.
  final Track track;

  /// The length, if it's known.
  final Duration? duration;

  /// Whether the track can play now; tracks the server doesn't have yet are
  /// dimmed.
  final bool available;

  /// Whether the track is hidden from playback in its playlist.
  final bool hidden;

  /// Whether the server is fetching the track.
  final bool loading;

  /// Plays the list from this track.
  final VoidCallback onPlay;

  /// Shows the right click menu.
  final VoidCallback onMenu;

  @override
  State<TrackRowMacos> createState() => _TrackRowMacosState();
}

class _TrackRowMacosState extends State<TrackRowMacos> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    final track = widget.track;
    return ValueListenableBuilder(
      valueListenable: context.player.currentStid,
      builder: (context, currentStid, _) {
        final current = currentStid == track.id;
        final Color titleColor = current
            ? theme.primaryColor
            : theme.typography.body.color!;
        return MouseRegion(
          onEnter: (_) => setState(() => hovering = true),
          onExit: (_) => setState(() => hovering = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTap: widget.onPlay,
            onSecondaryTap: widget.onMenu,
            child: Opacity(
              opacity: widget.available && !widget.hidden ? 1 : 0.45,
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: hovering
                      ? MacosColors.systemGrayColor.withAlpha(40)
                      : widget.index.isOdd
                      ? MacosColors.systemGrayColor.withAlpha(14)
                      : MacosColors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Center(child: _leading(theme, current)),
                    ),
                    const SizedBox(width: 8),
                    TrackArtworkMacos(track: track),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.typography.body.copyWith(
                              color: titleColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            track.artistNames,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.typography.subheadline.copyWith(
                              color: secondaryTextMacos,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.duration != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          formatTrackDuration(widget.duration!),
                          style: theme.typography.subheadline.copyWith(
                            color: secondaryTextMacos,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                    Opacity(
                      opacity: hovering ? 1 : 0,
                      child: MacosIconButton(
                        icon: const MacosIcon(CupertinoIcons.ellipsis),
                        boxConstraints: const BoxConstraints.tightFor(
                          width: 28,
                          height: 28,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: widget.onMenu,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _leading(MacosThemeData theme, bool current) {
    if (widget.loading) return const ProgressCircle(radius: 7);
    if (hovering) {
      return MacosIconButton(
        icon: MacosIcon(
          CupertinoIcons.play_fill,
          size: 14,
          color: theme.typography.body.color,
        ),
        boxConstraints: const BoxConstraints.tightFor(width: 28, height: 28),
        padding: EdgeInsets.zero,
        onPressed: widget.onPlay,
      );
    }
    if (current) {
      return MacosIcon(
        CupertinoIcons.speaker_2_fill,
        size: 14,
        color: theme.primaryColor,
      );
    }
    return Text(
      '${widget.index + 1}',
      style: theme.typography.subheadline.copyWith(
        color: secondaryTextMacos,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// The top of a track collection: its artwork, title and play buttons, like
/// a playlist in the Music app.
class CollectionHeaderMacos extends StatelessWidget {
  /// Creates a header for the collection named [title].
  const CollectionHeaderMacos({
    super.key,
    required this.artwork,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.onPlay,
    required this.onShuffle,
    this.actions = const [],
  });

  /// The cover, about 180 points square.
  final Widget artwork;

  /// What the collection is, such as "Playlist".
  final String kind;

  /// The name of the collection.
  final String title;

  /// A line under the title, such as the number of songs.
  final String subtitle;

  /// Plays the collection, or `null` when there's nothing to play.
  final VoidCallback? onPlay;

  /// Plays the collection shuffled, or `null` when there's nothing to play.
  final VoidCallback? onShuffle;

  /// More buttons after the play buttons.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox.square(dimension: 180, child: artwork),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kind.toUpperCase(),
                  style: theme.typography.caption1.copyWith(
                    color: secondaryTextMacos,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.largeTitle.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.typography.body.copyWith(
                    color: secondaryTextMacos,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    PushButton(
                      controlSize: ControlSize.large,
                      onPressed: onPlay,
                      child: _label(CupertinoIcons.play_fill, l10n.play),
                    ),
                    PushButton(
                      controlSize: ControlSize.large,
                      secondary: true,
                      onPressed: onShuffle,
                      child: _label(CupertinoIcons.shuffle, l10n.shuffle),
                    ),
                    ...actions,
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      MacosIcon(icon, size: 13, color: MacosColors.white),
      const SizedBox(width: 6),
      Text(text),
    ],
  );
}

/// The artwork of a collection without a cover: a gradient with [icon].
class CollectionArtworkMacos extends StatelessWidget {
  /// Creates a placeholder artwork showing [icon].
  const CollectionArtworkMacos({super.key, required this.icon, this.colors});

  /// The symbol in the middle.
  final IconData icon;

  /// The gradient colors, top left to bottom right.
  final List<Color>? colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              colors ??
              const [
                MacosColors.systemPinkColor,
                MacosColors.systemPurpleColor,
              ],
        ),
      ),
      child: Center(child: MacosIcon(icon, size: 72, color: MacosColors.white)),
    );
  }
}

/// A message in the middle of an empty list, with an optional [action].
class EmptyStateMacos extends StatelessWidget {
  /// Creates the message [title] under [icon].
  const EmptyStateMacos({
    super.key,
    required this.icon,
    required this.title,
    this.action,
  });

  /// The symbol above the message.
  final IconData icon;

  /// The message.
  final String title;

  /// A button under the message.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MacosIcon(icon, size: 48, color: MacosColors.systemGrayColor),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.typography.title3.copyWith(
                color: secondaryTextMacos,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

/// Asks to confirm [message] in a Mac alert and returns whether the user
/// chose [confirm].
Future<bool> confirmMacos(
  BuildContext context, {
  required String title,
  required String message,
  required String confirm,
}) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showMacosAlertDialog<bool>(
    context: context,
    builder: (context) => MacosAlertDialog(
      appIcon: const MacosIcon(CupertinoIcons.music_note_2, size: 56),
      title: Text(title),
      message: Text(message, textAlign: TextAlign.center),
      primaryButton: PushButton(
        controlSize: ControlSize.large,
        onPressed: () => Navigator.of(context).pop(true),
        child: Text(confirm),
      ),
      secondaryButton: PushButton(
        controlSize: ControlSize.large,
        secondary: true,
        onPressed: () => Navigator.of(context).pop(false),
        child: Text(l10n.cancel),
      ),
    ),
  );
  return confirmed ?? false;
}

/// Asks for a text in a Mac sheet, starting with [initial], and returns it,
/// or `null` if the user cancelled.
Future<String?> promptTextMacos(
  BuildContext context, {
  required String title,
  required String placeholder,
  required String confirm,
  String initial = '',
}) {
  return showMacosSheet<String>(
    context: context,
    builder: (context) => _TextPromptSheet(
      title: title,
      placeholder: placeholder,
      confirm: confirm,
      initial: initial,
    ),
  );
}

class _TextPromptSheet extends StatefulWidget {
  const _TextPromptSheet({
    required this.title,
    required this.placeholder,
    required this.confirm,
    required this.initial,
  });

  final String title;
  final String placeholder;
  final String confirm;
  final String initial;

  @override
  State<_TextPromptSheet> createState() => _TextPromptSheetState();
}

class _TextPromptSheetState extends State<_TextPromptSheet> {
  late final controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _done() {
    final text = controller.text.trim();
    if (text.isNotEmpty) Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MacosSheet(
      insetPadding: EdgeInsets.symmetric(
        horizontal: (MediaQuery.sizeOf(context).width - 420) / 2,
        vertical: (MediaQuery.sizeOf(context).height - 190) / 2,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: MacosTheme.of(context).typography.headline,
            ),
            const SizedBox(height: 16),
            MacosTextField(
              controller: controller,
              placeholder: widget.placeholder,
              autofocus: true,
              onSubmitted: (_) => _done(),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PushButton(
                  controlSize: ControlSize.large,
                  secondary: true,
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                PushButton(
                  controlSize: ControlSize.large,
                  onPressed: _done,
                  child: Text(widget.confirm),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

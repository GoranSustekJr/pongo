import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';

import '../../../app/view_models/app_settings_view_model.dart';
import '../../../core/app_icons.dart';
import '../../../core/ui/image/image_compatible.dart';
import '../../../core/ui/marquee.dart';
import '../../../core/ui/phone/liquid_glass_background.dart';
import '../../../core/ui/phone/liquid_glass_render.dart';
import '../../../core/ui/space.dart';
import '../../../core/ui/swipe_to_snap_back.dart';
import '../../../shell/view_models/shell_view_model.dart';
import '../../view_models/player_view_model.dart';
import 'alerts/halt_alert.dart';
import 'play_pause_mini.dart';

class TrackInfo extends StatefulWidget {
  const TrackInfo({super.key});

  @override
  State<TrackInfo> createState() => _TrackInfoState();
}

class _TrackInfoState extends State<TrackInfo> {
  // Text styles
  final TextStyle bottomTitle = const TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w500,
  );

  final TextStyle bottomArtist = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w300,
    color: Colors.white.withAlpha(200),
  );

  ValueNotifier<double> get _panelHeight => context.shell.currentTrackHeight;

  Future<void> _halt() async {
    final CustomButton ok = await haltAlert(context);
    if (ok != CustomButton.positiveButton || !mounted) return;
    _panelHeight.value = 0;
    await context.player.halt();
  }

  // Moves the panel with the finger, keeping it on screen.
  void _drag(DragUpdateDetails details, double maxHeight) {
    _panelHeight.value = (_panelHeight.value - details.delta.dy).clamp(
      0,
      maxHeight,
    );
  }

  // Opens or closes the panel depending on how fast and far it was dragged.
  void _snap(DragEndDetails details, double maxHeight) {
    // Flings faster than this open or close the panel outright.
    const flingVelocity = 40;
    final velocity = details.primaryVelocity ?? 0;
    final open = velocity < -flingVelocity
        ? true
        : velocity > flingVelocity
        ? false
        : _panelHeight.value > 40;
    setState(() => _panelHeight.value = open ? maxHeight : 0);
  }

  Widget _trackRow(
    MediaItem currentMediaItem,
    AsyncSnapshot<PlaybackState> playbackState,
    Size size,
  ) {
    final player = context.player;
    final playing = playbackState.data?.playing ?? false;
    final artUri = currentMediaItem.artUri?.toString() ?? '';
    return Row(
      children: [
        SizedBox(
          width: 50,
          height: 50,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7.5),
            child: artUri != ''
                ? ImageCompatible(image: artUri, width: 40, height: 40)
                : SizedBox(
                    height: 40,
                    width: 40,
                    child: Center(child: Icon(AppIcons.blankTrack)),
                  ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: size.width - 155,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              marquee(
                '${currentMediaItem.title}  ',
                bottomTitle,
                1,
                null,
                height: 22,
              ),
              marquee(
                '${currentMediaItem.artist}  ',
                bottomArtist,
                1,
                null,
                height: 20,
              ),
            ],
          ),
        ),
        const Expanded(child: SizedBox()),
        PlayPauseMini(
          playbackState: playbackState,
          function: () => playing ? player.pause() : player.play(),
        ),
        razw(10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = context.player;
    final Size size = MediaQuery.of(context).size;
    return liquidGlassLayer(
      child: SafeArea(
        child: StreamBuilder(
          stream: player.playbackState,
          builder: (context, playbackState) {
            return StreamBuilder(
              stream: player.currentItemStream,
              builder: (context, AsyncSnapshot<MediaItem?> mediaItem) {
                // Get the current media item
                final currentMediaItem = mediaItem.data;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.decelerate,
                  margin: const EdgeInsets.fromLTRB(10, 0, 10, 11),
                  padding: const EdgeInsets.all(1),
                  height: currentMediaItem == null || playbackState.data == null
                      ? 0
                      : 58,
                  constraints: const BoxConstraints(maxWidth: 768),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.transparent,
                  ),
                  child: liquidGlass(
                    radius: 24,
                    child: liquidGlassBackground(
                      enabled: context.readSettings.useLiquidGlass,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child:
                            currentMediaItem == null ||
                                playbackState.data == null
                            ? Container(key: const ValueKey(true))
                            : ClipRRect(
                                key: ValueKey(currentMediaItem.id),
                                borderRadius: BorderRadius.circular(24),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: GestureDetector(
                                        onLongPress: _halt,
                                        onVerticalDragUpdate: (details) =>
                                            _drag(details, size.height),
                                        onVerticalDragEnd: (details) =>
                                            _snap(details, size.height),
                                        onTap: () =>
                                            _panelHeight.value = size.height,
                                        child: SwipeToSnapBack(
                                          swipeLeft: () async {
                                            await player.skipToNext();
                                          },
                                          swipeRight: () async {
                                            await player.skipToPrevious();
                                          },
                                          child: Stack(
                                            children: [
                                              Positioned(
                                                left: 0,
                                                child: RepaintBoundary(
                                                  child: Container(
                                                    height: 70,
                                                    width: size.width - 10,
                                                    color: Colors.transparent,
                                                    child: Column(
                                                      children: [
                                                        Container(
                                                          height: 55,
                                                          width:
                                                              size.width - 10,
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 15,
                                                                vertical: 5,
                                                              ),
                                                          child: _trackRow(
                                                            currentMediaItem,
                                                            playbackState,
                                                            size,
                                                          ),
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
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

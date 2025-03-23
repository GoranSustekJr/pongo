import '../../../../exports.dart';
import 'package:flutter/cupertino.dart';
import 'package:interactive_slider_path/interactive_slider.dart' as isf;

class DesktopTrackProgress extends StatefulWidget {
  final String album;
  final Duration? duration;
  final Function(String) showAlbum;
  const DesktopTrackProgress({
    super.key,
    required this.album,
    required this.duration,
    required this.showAlbum,
  });

  @override
  State<DesktopTrackProgress> createState() => _DesktopTrackProgressState();
}

class _DesktopTrackProgressState extends State<DesktopTrackProgress> {
  // Slider controller
  isf.InteractiveSliderController progressController =
      isf.InteractiveSliderController(0);

  // Notifiers for progress and time
  final ValueNotifier<double> progressNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<String> formattedTimeNotifier =
      ValueNotifier<String>('0:00');
  final ValueNotifier<String> remainingTimeNotifier =
      ValueNotifier<String>('-0:00');

  @override
  void initState() {
    super.initState();
    updateProgress(0); // Initial progress setup
  }

  void updateProgress(double progress) {
    // Update progress values
    progressNotifier.value = progress;
    formattedTimeNotifier.value = formatTime(
        Duration(seconds: (progress * widget.duration!.inSeconds).toInt()));
    remainingTimeNotifier.value = formatTime(widget.duration! -
        Duration(seconds: (progress * widget.duration!.inSeconds).toInt()));
  }

  String formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds < 10 ? '0' : ''}$seconds';
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final audioServiceHandler =
        Provider.of<AudioHandler>(context) as AudioServiceHandler;
    return StreamBuilder<Duration>(
      stream: audioServiceHandler.audioPlayer.positionStream,
      builder: (context, position) {
        // Update progress only if there's a change
        if (position.hasData && widget.duration != null) {
          double progress =
              position.data!.inSeconds / widget.duration!.inSeconds;
          if (progress != progressNotifier.value) {
            progressController.value = progress;
            updateProgress(progress);
          }
        }

        return Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 5),
          child: Column(
            children: [
              // Progress slider widget
              SizedBox(
                width: (size.width - 180) / 2,
                height: 15,
                child: isf.InteractiveSlider(
                  padding: EdgeInsets.zero,
                  initialProgress: progressNotifier.value,
                  controller: progressController,
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withAlpha(50),
                  focusedHeight: 11.5,
                  enabled: premium.value || kIsDesktop,
                  onProgressUpdated: (position) async {
                    updateProgress(position);
                    await audioServiceHandler.seek(
                      Duration(
                          seconds:
                              (position * widget.duration!.inSeconds).toInt()),
                    );
                  },
                ),
              ),

              // Time display and album name
              SizedBox(
                height: 30,
                width: (size.width - 180) / 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ValueListenableBuilder<double>(
                      valueListenable: progressNotifier,
                      builder: (context, progress, child) {
                        return Text(
                          formattedTimeNotifier.value,
                          style: TextStyle(
                              color: Colors.white.withAlpha(200), fontSize: 14),
                        );
                      },
                    ),
                    SizedBox(
                      child: Center(
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () async {
                            await widget
                                .showAlbum(widget.album.split("..Ææ..")[0]);
                          },
                          child: marquee(
                            widget.album.split("..Ææ..")[1],
                            TextStyle(
                                color: Colors.white.withAlpha(200),
                                fontSize: 12),
                            null,
                            null,
                          ),
                        ),
                      ),
                    ),
                    ValueListenableBuilder<String>(
                      valueListenable: remainingTimeNotifier,
                      builder: (context, remainingTime, child) {
                        return Text(
                          remainingTime,
                          style: TextStyle(
                              color: Colors.white.withAlpha(200), fontSize: 14),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

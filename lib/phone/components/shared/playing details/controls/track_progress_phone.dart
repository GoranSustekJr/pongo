import 'package:flutter/cupertino.dart';
import 'package:interactive_slider_path/interactive_slider.dart' as isf;
import '../../../../../exports.dart';

class TrackProgressPhone extends StatefulWidget {
  final String album;
  final String released;
  final Duration? duration;
  final Function(String) showAlbum;

  const TrackProgressPhone({
    super.key,
    required this.album,
    required this.released,
    required this.duration,
    required this.showAlbum,
  });

  @override
  State<TrackProgressPhone> createState() => _TrackProgressPhoneState();
}

class _TrackProgressPhoneState extends State<TrackProgressPhone> {
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
    final audioServiceHandler =
        Provider.of<AudioHandler>(context, listen: false)
            as AudioServiceHandler;

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
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Column(
            children: [
              // Progress slider widget
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 15,
                child: isf.InteractiveSlider(
                  padding: EdgeInsets.zero,
                  initialProgress: progressNotifier.value,
                  controller: progressController,
                  focusedHeight: 11.5,
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
                width: MediaQuery.of(context).size.width - 35,
                height: 30,
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
                      width: MediaQuery.of(context).size.width - 150,
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

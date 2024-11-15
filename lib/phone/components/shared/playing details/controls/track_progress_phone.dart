import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
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
      isf.InteractiveSliderController(VolumeManager().currentVolume);

  @override
  void initState() {
    super.initState();
    updateProgress(0);
  }

  void updateProgress(double progress) async {
    setState(() {
      progressController.value = progress;
    });
  }

  @override
  Widget build(BuildContext context) {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context, listen: true) as AudioServiceHandler;
    return StreamBuilder(
        stream: audioServiceHandler.audioPlayer.positionStream,
        builder: (context, position) {
          double progress = position.data != null
              ? widget.duration != null
                  ? double.parse(
                      (position.data!.inSeconds / widget.duration!.inSeconds)
                          .toString())
                  : 0.0
              : 0.0;

          /* print("progress; $progress");
          print("duration; ${widget.duration}"); */

          progressController.value = progress;
          SchedulerBinding.instance.addPostFrameCallback((_) {});

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Column(
              children: [
                SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: 15,
                    child: isf.InteractiveSlider(
                      padding: EdgeInsets.zero,
                      initialProgress: 0.5,
                      controller: progressController,
                      focusedHeight: 11.5,
                      onProgressUpdated: (position) async {
                        updateProgress(position);
                        await audioServiceHandler.seek(
                          Duration(
                            seconds: widget.duration != null
                                ? double.parse(
                                        (position * widget.duration!.inSeconds)
                                            .toString())
                                    .toInt()
                                : 0,
                          ),
                        );
                      },
                    )),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 35,
                  height: 30,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (position.data != null)
                        Text(
                          position.data!.inHours > 0
                              ? "${(position.data!).inHours}:${(position.data!).inMinutes % 60 < 10 ? "0" : ""}${(position.data!).inMinutes % 60}:${(position.data!).inSeconds % 3600 < 10 ? "0" : ""}${(position.data!).inSeconds % 3600}"
                              : "${(position.data!).inMinutes}:${(position.data!).inSeconds % 60 < 10 ? "0" : ""}${(position.data!).inSeconds % 60}",
                          style: TextStyle(
                              color: Colors.white.withAlpha(200), fontSize: 14),
                        ),
                      if (position.data == null)
                        Text(
                          "0:00",
                          style: TextStyle(
                              color: Colors.white.withAlpha(200), fontSize: 14),
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
                                  fontSize: 12,
                                ),
                                null,
                                null),
                          ),
                        ),
                      ),
                      if (position.data != null && widget.duration != null)
                        Text(
                          (widget.duration! - position.data!).inHours > 0
                              ? "-${(widget.duration! - position.data!).inHours}:${(widget.duration! - position.data!).inMinutes % 60 < 10 ? "0" : ""}${(widget.duration! - position.data!).inMinutes % 60}:${(widget.duration! - position.data!).inSeconds % 3600 < 10 ? "0" : ""}${(widget.duration! - position.data!).inSeconds % 3600}"
                              : "-${(widget.duration! - position.data!).inMinutes}:${(widget.duration! - position.data!).inSeconds % 60 < 10 ? "0" : ""}${(widget.duration! - position.data!).inSeconds % 60}",
                          style: TextStyle(
                            color: Colors.white.withAlpha(200),
                            fontSize: 14,
                          ),
                        ),
                      if (position.data == null && widget.duration != null)
                        Text(
                          (widget.duration!).inHours > 0
                              ? "-${(widget.duration!).inHours}:${(widget.duration!).inMinutes % 60 < 10 ? "0" : ""}${(widget.duration!).inMinutes % 60}:${(widget.duration!).inSeconds % 3600 < 10 ? "0" : ""}${(widget.duration!).inSeconds % 3600}"
                              : "-${(widget.duration!).inMinutes}:${(widget.duration!).inSeconds % 60 < 10 ? "0" : ""}${(widget.duration!).inSeconds % 60}",
                          style: TextStyle(
                              color: Colors.white.withAlpha(200), fontSize: 14),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
    /*  }); */
  }
}

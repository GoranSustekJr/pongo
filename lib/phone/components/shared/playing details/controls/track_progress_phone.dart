import 'package:audio_video_progress_bar/audio_video_progress_bar.dart'
    as progressbutton;
import 'package:flutter/cupertino.dart';

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
  double progressBarHeight = 12.5;
  @override
  Widget build(BuildContext context) {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context) as AudioServiceHandler;
    return StreamBuilder(
        stream: audioServiceHandler.positionStream,
        builder: (context, position) {
          return StreamBuilder(
              stream: audioServiceHandler.bufferStream,
              builder: (context, buffer) {
                //  print ("Duration: ${buffer.data}");
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Column(
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: AnimatedContainer(
                          duration: const Duration(
                              milliseconds: 300), // Adjust duration as needed
                          height: 10,
                          child: Center(
                            child: progressbutton.ProgressBar(
                              progress:
                                  position.data ?? const Duration(seconds: 0),
                              total:
                                  widget.duration ?? const Duration(seconds: 0),
                              buffered: buffer.data,
                              barHeight: progressBarHeight,
                              thumbRadius: 5,
                              thumbColor: Colors.white,
                              progressBarColor: Colors.white,
                              thumbGlowColor: Col.primary.withAlpha(50),
                              baseBarColor: Colors.white.withAlpha(50),
                              bufferedBarColor: Colors.white.withAlpha(75),
                              thumbGlowRadius: 0,
                              onSeek: (value) {
                                audioServiceHandler.seek(value);
                              },
                              onDragStart: (details) {
                                setState(() {
                                  progressBarHeight =
                                      20; // Adjust the height for dragging
                                });
                              },
                              onDragEnd: () {
                                setState(() {
                                  progressBarHeight =
                                      12.5; // Restore the height after dragging
                                });
                              },
                              timeLabelLocation:
                                  progressbutton.TimeLabelLocation.none,
                            ),
                          ),
                        ),
                      ),
                      razh(15),
                      SizedBox(
                        width: MediaQuery.of(context).size.width - 35,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (position.data != null)
                              Text(
                                position.data!.inHours > 0
                                    ? "${(position.data!).inHours}:${(position.data!).inMinutes % 60 < 10 ? "0" : ""}${(position.data!).inMinutes % 60}:${(position.data!).inSeconds % 3600 < 10 ? "0" : ""}${(position.data!).inSeconds % 3600}"
                                    : "${(position.data!).inMinutes}:${(position.data!).inSeconds % 60 < 10 ? "0" : ""}${(position.data!).inSeconds % 60}",
                                style: TextStyle(
                                    color: Colors.white.withAlpha(200),
                                    fontSize: 14),
                              ),
                            if (position.data == null)
                              Text(
                                "0:00",
                                style: TextStyle(
                                    color: Colors.white.withAlpha(200),
                                    fontSize: 14),
                              ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width - 150,
                              child: Center(
                                child: CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () async {
                                    await widget.showAlbum(
                                        widget.album.split("..Ææ..")[0]);
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
                            if (position.data != null &&
                                widget.duration != null)
                              Text(
                                (widget.duration! - position.data!).inHours > 0
                                    ? "-${(widget.duration! - position.data!).inHours}:${(widget.duration! - position.data!).inMinutes % 60 < 10 ? "0" : ""}${(widget.duration! - position.data!).inMinutes % 60}:${(widget.duration! - position.data!).inSeconds % 3600 < 10 ? "0" : ""}${(widget.duration! - position.data!).inSeconds % 3600}"
                                    : "-${(widget.duration! - position.data!).inMinutes}:${(widget.duration! - position.data!).inSeconds % 60 < 10 ? "0" : ""}${(widget.duration! - position.data!).inSeconds % 60}",
                                style: TextStyle(
                                  color: Colors.white.withAlpha(200),
                                  fontSize: 14,
                                ),
                              ),
                            /* if (position.data == null &&
                                    widget.duration == null ||
                                !widget.thisTrackPlaying)
                              Text(
                                "-0:00",
                                style: TextStyle(
                                    color: Colors.white.withAlpha(200),
                                    fontSize: 14),
                              ), */
                            if (position.data == null &&
                                widget.duration != null)
                              Text(
                                (widget.duration!).inHours > 0
                                    ? "-${(widget.duration!).inHours}:${(widget.duration!).inMinutes % 60 < 10 ? "0" : ""}${(widget.duration!).inMinutes % 60}:${(widget.duration!).inSeconds % 3600 < 10 ? "0" : ""}${(widget.duration!).inSeconds % 3600}"
                                    : "-${(widget.duration!).inMinutes}:${(widget.duration!).inSeconds % 60 < 10 ? "0" : ""}${(widget.duration!).inSeconds % 60}",
                                style: TextStyle(
                                    color: Colors.white.withAlpha(200),
                                    fontSize: 14),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              });
        });
  }
}

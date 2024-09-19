import 'package:pongo/exports.dart';
import 'package:pongo/phone/components/shared/tiles/queue_tile.dart';

class QueuePhone extends StatefulWidget {
  final bool showQueue;
  final bool lyricsOn;
  const QueuePhone(
      {super.key, required this.showQueue, required this.lyricsOn});

  @override
  State<QueuePhone> createState() => _QueuePhoneState();
}

class _QueuePhoneState extends State<QueuePhone> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    final audioServiceHandler =
        Provider.of<AudioHandler>(context, listen: false)
            as AudioServiceHandler;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 0),
      top: widget.showQueue && !widget.lyricsOn ? 0 : size.height,
      child: AnimatedOpacity(
        opacity: widget.showQueue && !widget.lyricsOn ? 1 : 0,
        duration: Duration(milliseconds: widget.lyricsOn ? 500 : 150),
        child: RepaintBoundary(
          child: StreamBuilder(
              stream: audioServiceHandler.queue.stream,
              builder: (context, snapshot) {
                final queue = snapshot.data;

                return StreamBuilder(
                    stream:
                        audioServiceHandler.audioPlayer.shuffleIndicesStream,
                    builder: (context, snap) {
                      final shuffleIndices = snap.data;

                      return StreamBuilder(
                          stream: audioServiceHandler
                              .audioPlayer.shuffleModeEnabledStream,
                          builder: (context, snp) {
                            final shuffleModeEnabled = (snp.data ?? false) &&
                                (shuffleIndices != null
                                    ? shuffleIndices.isNotEmpty
                                    : false);

                            print("SHUFFLE ENABLED; $shuffleModeEnabled");
                            print(snp.data);

                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: SizedBox(
                                height: size.height,
                                width: size.width - 20,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: queue != null
                                      ? SingleChildScrollView(
                                          key: const ValueKey(true),
                                          child: Column(
                                            children: <Widget>[
                                              razh(kToolbarHeight),
                                              ListView.builder(
                                                itemCount: queue.length,
                                                shrinkWrap: true,
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                itemBuilder: (context, index) {
                                                  int ind = shuffleModeEnabled
                                                      ? shuffleIndices[index]
                                                      : index;
                                                  return AnimatedSwitcher(
                                                    duration: const Duration(
                                                        milliseconds: 200),
                                                    child: QueueTile(
                                                      key: ValueKey(ind),
                                                      title: queue[ind].title,
                                                      artist:
                                                          queue[ind].artist ??
                                                              "",
                                                      imageUrl: queue[ind]
                                                          .artUri
                                                          .toString(),
                                                      trailing: SizedBox(
                                                        height: 40,
                                                        width: 20,
                                                        child: AnimatedSwitcher(
                                                          duration:
                                                              const Duration(
                                                                  milliseconds:
                                                                      200),
                                                          child: StreamBuilder(
                                                            key: const ValueKey(
                                                                false),
                                                            stream:
                                                                audioServiceHandler
                                                                    .mediaItem
                                                                    .stream,
                                                            builder: (context,
                                                                snapshot) {
                                                              final String id =
                                                                  snapshot.data !=
                                                                          null
                                                                      ? snapshot
                                                                          .data!
                                                                          .id
                                                                      : "";

                                                              return id ==
                                                                      queue[ind]
                                                                          .id
                                                                  ? StreamBuilder(
                                                                      stream: audioServiceHandler
                                                                          .audioPlayer
                                                                          .playingStream,
                                                                      builder:
                                                                          (context,
                                                                              playingStream) {
                                                                        return SizedBox(
                                                                          width:
                                                                              20,
                                                                          height:
                                                                              40,
                                                                          child:
                                                                              MiniMusicVisualizer(
                                                                            color:
                                                                                Colors.white,
                                                                            radius:
                                                                                60,
                                                                            animate:
                                                                                playingStream.data ?? false,
                                                                          ),
                                                                        );
                                                                      })
                                                                  : const SizedBox();
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                      onTap: () {},
                                                    ),
                                                  );
                                                },
                                              ),
                                              razh(300 -
                                                  MediaQuery.of(context)
                                                      .padding
                                                      .bottom),
                                            ],
                                          ),
                                        )
                                      : const SizedBox(
                                          key: ValueKey(false),
                                        ),
                                ),
                              ),
                            );
                          });
                    });
              }),
        ),
      ),
    );
  }
}

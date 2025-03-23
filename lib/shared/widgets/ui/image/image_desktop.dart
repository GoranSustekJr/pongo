import 'package:pongo/exports.dart';

class TrackImageDesktop extends StatelessWidget {
  final String image;
  final String stid;
  final AudioServiceHandler audioServiceHandler;
  const TrackImageDesktop(
      {super.key,
      required this.image,
      required this.stid,
      required this.audioServiceHandler});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(mainContext.value!).size;
    return Container(
      height: size.height > 685
          ? (size.height - 60) - 190 < (size.width - 200) / 2
              ? (size.height - 60) - 190
              : (size.width - 200) / 2
          : (size.height - 60) - 130 < (size.width - 200) / 2
              ? (size.height - 60) - 130
              : (size.width - 200) / 2,

      /* (size.height - 60) - 130 < (size.width - 200) / 2
            ? (size.height - 60) - 130
            : size.height - 60 > 685
                ? (size.height - 60) - 190 < (size.width - 200) / 2
                    ? (size.height - 60) - 190
                    : null
                : (size.height - 60) - 130, */
      key: ValueKey<String>(image), // Unique key for each image
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(75),
            spreadRadius: 0.1,
            blurRadius: 15,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7.5),
        child: StreamBuilder<Object>(
            key: ValueKey(image),
            stream: audioServiceHandler.audioPlayer.playingStream,
            builder: (context, snapshot) {
              return GestureDetector(
                onTap: () {
                  if (audioServiceHandler.audioPlayer.playing) {
                    audioServiceHandler.pause();
                  } else {
                    audioServiceHandler.play();
                  }
                },
                child: AnimatedScale(
                  scale: audioServiceHandler.audioPlayer.playing ? 1.0 : 0.85,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.fastEaseInToSlowEaseOut,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      audioServiceHandler.audioPlayer.playing
                          ? Colors.transparent
                          : Colors.black.withAlpha(25),
                      BlendMode.srcOver,
                    ),
                    child: ImageCompatible(
                      image: image,
                      height: size.height > 685
                          ? (size.height - 60) - 190 < (size.width - 200) / 2
                              ? (size.height - 60) - 190
                              : null
                          : (size.height - 60) - 130 < (size.width - 200) / 2
                              ? (size.height - 60) - 130
                              : null,
                      width: size.height > 685
                          ? (size.height - 60) - 190 < (size.width - 200) / 2
                              ? (size.height - 60) - 190
                              : null
                          : (size.height - 60) - 130 < (size.width - 200) / 2
                              ? (size.height - 60) - 130
                              : null,
                    ),
                  ),
                ),
              );
            }),
      ),
    );
  }
}

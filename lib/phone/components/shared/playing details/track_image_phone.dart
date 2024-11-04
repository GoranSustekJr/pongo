import 'package:pongo/exports.dart';

class TrackImagePhone extends StatelessWidget {
  final bool lyricsOn;
  final bool showQueue;
  final List frequency;
  final AudioServiceHandler audioServiceHandler;
  final String image;
  const TrackImagePhone({
    super.key,
    required this.lyricsOn,
    required this.image,
    required this.showQueue,
    required this.audioServiceHandler,
    required this.frequency,
  });

  @override
  Widget build(BuildContext context) {
    List freqs = [50, 120, 210, 320, 400, 480];
    Size size = MediaQuery.of(context).size;
    return AnimatedPositioned(
      duration: Duration(milliseconds: lyricsOn || showQueue ? 200 : 600),
      //top: lyricsOn || showQueue ? 0 : MediaQuery.of(context).padding.top + 30,
      bottom: lyricsOn || showQueue
          ? size.height /*  - 200 */
          : size.height -
              (MediaQuery.of(context).padding.top +
                  30 +
                  size.width -
                  60) /*  -
              200 */
      ,
      curve: Curves.decelerate,
      child: AnimatedOpacity(
        opacity: lyricsOn || showQueue ? 0 : 1,
        duration: const Duration(milliseconds: 1000),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: size.width - 60,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      switchInCurve: Curves.fastOutSlowIn,
                      switchOutCurve: Curves.fastEaseInToSlowEaseOut,
                      child: StreamBuilder<Object>(
                          key: ValueKey(image),
                          stream: audioServiceHandler.audioPlayer.playingStream,
                          builder: (context, snapshot) {
                            return /*  StreamBuilder(
                                stream: audioServiceHandler.positionStream,
                                builder: (context, snapshot) {
                                  //print((snapshot.data!.inMilliseconds / 200)
                                  //  .toInt());
                                  if (!snapshot.hasData) {
                                    return const SizedBox(
                                      child: Center(
                                        child: Text("data"),
                                      ),
                                    );
                                  }
                                  print(frequency[
                                      (snapshot.data!.inMilliseconds / 200)
                                          .toInt()]);
                                  return  */
                                AnimatedScale(
                              scale: /* frequency[
                                            (snapshot.data!.inMilliseconds /
                                                    200)
                                                .toInt()]["50"] /
                                        100, */
                                  audioServiceHandler.audioPlayer.playing
                                      ? 1.0
                                      : 0.85,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.fastEaseInToSlowEaseOut,
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (audioServiceHandler
                                          .audioPlayer.playing) {
                                        audioServiceHandler.pause();
                                      } else {
                                        audioServiceHandler.play();
                                      }
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: ColorFiltered(
                                        colorFilter: ColorFilter.mode(
                                          audioServiceHandler
                                                  .audioPlayer.playing
                                              ? Colors.transparent
                                              : Colors.black.withAlpha(25),
                                          BlendMode.srcOver,
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          child: CachedNetworkImage(
                                            imageUrl: image,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  /* TweenAnimationBuilder(
                                          tween: ListTween(
                                              begin: freqs
                                                  .map((freq) => frequency[
                                                          (snapshot.data!.inMilliseconds / 200)
                                                              .toInt()]["$freq"]
                                                      as double)
                                                  .toList(),
                                              end: freqs
                                                  .map((freq) => frequency[(snapshot
                                                              .data!
                                                              .inMilliseconds /
                                                          200)
                                                      .toInt()]["$freq"] as double)
                                                  .toList()),
                                          duration:
                                              const Duration(milliseconds: 150),
                                          builder: (context,
                                              List<double> animatedHeights, _) {
                                            return CustomPaint(
                                              size: Size(size.width,
                                                  200), // Set the size of the wave
                                              painter: WavePainter(
                                                heights: animatedHeights,
                                              ),
                                            );
                                          },
                                        ), */
                                ],
                              ),
                            );
                            /*  }); */
                          }),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final List<double> heights;

  WavePainter({required this.heights});

  @override
  void paint(Canvas canvas, Size size) {
    // Create a gradient from blue to transparent blue
    final Paint fillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Colors.blue,
          Colors.transparent,
        ],
        begin: Alignment.topCenter, // Change to top to bottom
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    double canvasHeight = size.height;
    double canvasWidth = size.width;
    double pointSpacing = canvasWidth /
        (heights.length + 1); // Account for start and end zero points

    // Create a smooth path for the wave using cubic Bezier curves
    Path path = Path();
    path.moveTo(0, 0); // Start from the top left

    for (int i = 0; i < heights.length; i++) {
      // Current and next points
      double x1 = pointSpacing * (i + 1); // Offset by 1 for extra start point
      double y1 = (heights[i] / 100) * canvasHeight; // Inverted y-coordinate
      double x2 = pointSpacing * (i + 2);
      double y2 = i + 1 < heights.length
          ? (heights[i + 1] / 100) * canvasHeight // Inverted y-coordinate
          : 0; // End at baseline

      // Control points for smooth curve
      double controlX1 = x1 + pointSpacing / 3;
      double controlY1 = y1;
      double controlX2 = x2 - pointSpacing / 3;
      double controlY2 = y2;

      path.cubicTo(controlX1, controlY1, controlX2, controlY2, x2, y2);
    }

    path.lineTo(canvasWidth, 0); // Close to top right
    path.lineTo(0, 0); // Close to top left

    // Fill the area under the wave with the gradient
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class ListTween extends Tween<List<double>> {
  ListTween({required List<double> begin, required List<double> end})
      : super(begin: begin, end: end);

  @override
  List<double> lerp(double t) {
    // Interpolates each element in the list individually
    return List.generate(begin!.length, (i) {
      return begin![i] + (end![i] - begin![i]) * t;
    });
  }
}

import 'package:pongo/exports.dart';

LayoutBuilder marquee(
    String text, TextStyle style, int? maxLines, TextOverflow? textOverflow,
    {double height = 28}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final textSpan = TextSpan(text: (text), style: style);

      final textPainter = TextPainter(
        text: textSpan,
        maxLines: 1,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(maxWidth: constraints.maxWidth);

      return /*  isOverflowing
          ? SizedBox(
              height: height,
              child: Marquee(
                text: "$text     ",
                style: style,
                fadingEdgeStartFraction: 0.3,
                fadingEdgeEndFraction: 0.3,
                velocity: 30,
              ),
            )
          :  */
          Text(
        (text),
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    },
  );
}

import '../../../../exports.dart';

class SwipeToSnapBack extends StatefulWidget {
  final Function() swipeLeft;
  final Function() swipeRight;
  final Widget child;

  const SwipeToSnapBack(
      {super.key,
      required this.child,
      required this.swipeLeft,
      required this.swipeRight});

  @override
  _SwipeToSnapBackState createState() => _SwipeToSnapBackState();
}

class _SwipeToSnapBackState extends State<SwipeToSnapBack> {
  // To track horizontal movement
  double offsetX = 0;

  // Threshold to consider for snapping
  double swipeThreshold = 80;

  // Function to handle swipe movement
  void onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      offsetX += details.delta.dx; // Move widget by delta
    });
  }

  // Function to handle the snap-back animation when swipe ends
  void onHorizontalDragEnd(DragEndDetails details) {
    if (offsetX.abs() > swipeThreshold) {
      if (details.primaryVelocity! > 0) {
        print("Drag right");
        widget.swipeRight();
      } else if (details.primaryVelocity! < 0) {
        print("Drag left");
        widget.swipeLeft();
      }
    }
    // Animate back to the center when letting go
    setState(() {
      offsetX = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: GestureDetector(
          onHorizontalDragUpdate: onHorizontalDragUpdate,
          onHorizontalDragEnd: onHorizontalDragEnd,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            transform:
                Matrix4.translationValues(offsetX, 0, 0), // Move horizontally
            curve: Curves.easeOut,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

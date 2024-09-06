import 'dart:async';
import 'package:flutter/material.dart';

class FadingNetworkImage extends StatefulWidget {
  final String imageUrl;

  const FadingNetworkImage({Key? key, required this.imageUrl})
      : super(key: key);

  @override
  _FadingNetworkImageState createState() => _FadingNetworkImageState();
}

class _FadingNetworkImageState extends State<FadingNetworkImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();

    // Initialize the AnimationController
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Precache the image to ensure it is loaded before starting the animation
    precacheImage(NetworkImage(widget.imageUrl), context).then((_) {
      if (mounted) {
        setState(() {
          _imageLoaded = true;
          _animationController.forward(); // Start the fade-in animation
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Image.network(
        widget.imageUrl,
        fit: BoxFit.cover,
      ),
    );
  }
}

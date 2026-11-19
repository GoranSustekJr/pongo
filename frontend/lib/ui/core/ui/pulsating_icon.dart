// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';

class PulsatingIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color color;
  final Duration duration;

  const PulsatingIcon({
    super.key,
    required this.icon,
    this.size = 24.0,
    this.color = Colors.white,
    this.duration = const Duration(milliseconds: 750),
  });

  @override
  _PulsatingIconState createState() => _PulsatingIconState();
}

class _PulsatingIconState extends State<PulsatingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.8, end: 1.3).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Icon(
            widget.icon,
            size: widget.size,
            color: widget.color,
          ),
        );
      },
    );
  }
}

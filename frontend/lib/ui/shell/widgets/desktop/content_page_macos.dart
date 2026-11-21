import 'package:flutter/material.dart';

/// Gives [child] the size of the area it's laid out in as the screen size.
///
/// Phone screens size themselves from [MediaQuery], which on a Mac is the
/// whole window, sidebars included.
class ContentSizeMacos extends StatelessWidget {
  /// Creates the size override for [child].
  const ContentSizeMacos({super.key, required this.child});

  /// The content that sizes itself from [MediaQuery].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => MediaQuery(
        data: MediaQuery.of(context).copyWith(size: constraints.biggest),
        child: child,
      ),
    );
  }
}

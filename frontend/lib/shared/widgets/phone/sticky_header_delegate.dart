import 'package:pongo/exports.dart';

class StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;
  final EdgeInsetsGeometry padding;

  StickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
    this.padding = EdgeInsets.zero, // default padding
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Padding(
      padding: padding, // Apply the padding here
      child: SizedBox.expand(child: child),
    );
  }

  @override
  bool shouldRebuild(StickyHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child ||
        padding != oldDelegate.padding; // Include padding in rebuild condition
  }
}

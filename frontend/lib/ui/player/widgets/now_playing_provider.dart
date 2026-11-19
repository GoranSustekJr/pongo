import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../core/themes/colors.dart';
import '../view_models/now_playing_view_model.dart';
import '../view_models/player_view_model.dart';

/// Gives [builder] a [NowPlayingViewModel] that lives as long as this widget.
class NowPlayingProvider extends StatelessWidget {
  /// Creates a provider that builds its child with [builder].
  const NowPlayingProvider({super.key, required this.builder});

  /// Builds the child, rebuilding it when the view model changes.
  final Widget Function(BuildContext context, NowPlayingViewModel nowPlaying)
  builder;

  @override
  Widget build(BuildContext context) {
    // Read here: `create` must not depend on inherited widgets like the theme.
    final defaultBlurhash = context.colors.defaultBlurhash;
    return ChangeNotifierProvider(
      create: (context) => NowPlayingViewModel(
        player: context.read(),
        lyrics: context.read(),
        settings: context.read(),
        connectivity: context.read(),
        messages: context.read(),
        blurhash: context.read<PlayerViewModel>().currentBlurhash,
        defaultBlurhash: defaultBlurhash,
      ),
      child: Consumer<NowPlayingViewModel>(
        builder: (context, nowPlaying, _) => builder(context, nowPlaying),
      ),
    );
  }
}

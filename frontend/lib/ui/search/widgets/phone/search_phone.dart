import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../utils/platform.dart';
import '../../../app/view_models/app_settings_view_model.dart';
import '../../../core/themes/colors.dart';
import '../../../player/view_models/player_view_model.dart';
import '../../../shell/view_models/shell_view_model.dart';
import '../../view_models/search_view_model.dart';
import 'search_body_phone.dart';

/// The results of the search [query].
class SearchPhone extends StatefulWidget {
  /// Creates the results screen.
  const SearchPhone({super.key, required this.query});

  /// The submitted query.
  final String query;

  @override
  State<SearchPhone> createState() => _SearchPhoneState();
}

class _SearchPhoneState extends State<SearchPhone> {
  late final SearchViewModel viewModel;
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    viewModel = SearchViewModel(
      catalog: context.read(),
      settings: context.read(),
      searchRequests: context.shell.searchRequests,
    );
  }

  @override
  void didUpdateWidget(covariant SearchPhone oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) viewModel.search(widget.query);
  }

  @override
  void dispose() {
    viewModel.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([viewModel, context.player.fetchingTracks]),
      builder: (context, child) {
        return AnimatedSwitcher(
          duration: Duration(
            milliseconds: context.readSettings.useAnimations ? 250 : 0,
          ),
          child: viewModel.tracks.isEmpty
              ? SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  key: const ValueKey(true),
                )
              : SearchBodyPhone(
                  tracks: viewModel.tracks,
                  artists: viewModel.artists,
                  albums: viewModel.albums,
                  playlists: viewModel.playlists,
                  loading: context.player.fetchingTracks.value.toList(),
                  scrollController: scrollController,
                  suggestionHeader: TextStyle(
                    fontSize: kIsDesktop
                        ? 24
                        : kIsApple
                        ? 17
                        : 19,
                    fontWeight: kIsDesktop
                        ? FontWeight.w800
                        : kIsApple
                        ? FontWeight.w600
                        : FontWeight.w700,
                    color: context.colors.text,
                  ),
                ),
        );
      },
    );
  }
}

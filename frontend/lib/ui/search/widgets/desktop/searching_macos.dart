import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../utils/platform.dart';
import '../../../core/themes/colors.dart';
import '../../../player/view_models/player_view_model.dart';
import '../../../shell/view_models/shell_view_model.dart';
import '../../view_models/search_view_model.dart';
import 'searching_body_macos.dart';

class SearchingMacos extends StatefulWidget {
  final String query;
  const SearchingMacos({super.key, required this.query});

  @override
  State<SearchingMacos> createState() => _SearchingMacosState();
}

class _SearchingMacosState extends State<SearchingMacos> {
  late final SearchViewModel searchDataManager;
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    searchDataManager = SearchViewModel(
      catalog: context.read(),
      settings: context.read(),
      searchRequests: context.shell.searchRequests,
    );
    if (widget.query.isNotEmpty) searchDataManager.search(widget.query);
  }

  @override
  void dispose() {
    searchDataManager.dispose();
    scrollController.dispose();
    super.dispose();
  }

  // Listen For Query Parameter Change
  @override
  void didUpdateWidget(covariant SearchingMacos oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      // If Query Parameter Changed Do Search Function
      searchDataManager.search(widget.query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return ListenableBuilder(
      listenable: Listenable.merge([
        searchDataManager,
        context.player.fetchingTracks,
      ]),
      builder: (context, child) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: searchDataManager.tracks.isEmpty
              ? SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  key: const ValueKey(true), // TODO: Shimmer
                )
              : SizedBox(
                  height: size.height, // Constrain height
                  width: size.width,
                  child: Scaffold(
                    extendBody: true,
                    extendBodyBehindAppBar: true,
                    backgroundColor: Col.transp,
                    body: SearchingBodyMacos(
                      tracks: searchDataManager.tracks,
                      artists: searchDataManager.artists,
                      albums: searchDataManager.albums,
                      playlists: searchDataManager.playlists,
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
                  ),
                ),
        );
      },
    );
  }
}

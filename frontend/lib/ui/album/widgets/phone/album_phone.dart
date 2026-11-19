import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/catalog/album.dart';
import '../../../../utils/platform.dart';
import '../../../app/view_models/app_settings_view_model.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/dimens.dart';
import '../../../core/ui/app_blur.dart';
import '../../../core/ui/phone/liquid_glass_background.dart';
import '../../../core/ui/phone/loading_scaffold.dart';
import '../../../core/ui/phone/sliver_app_bar.dart';
import '../../../core/ui/phone/sticky_header_delegate.dart';
import '../../view_models/album_view_model.dart';
import 'album_body_phone.dart';
import 'play_shuffle_halt_album.dart';

class AlbumPhone extends StatefulWidget {
  final BuildContext context;
  final Album album;
  const AlbumPhone({super.key, required this.album, required this.context});

  @override
  State<AlbumPhone> createState() => _AlbumPhoneState();
}

class _AlbumPhoneState extends State<AlbumPhone> {
  late final AlbumViewModel viewModel;

  // Scroll controller
  final scrollController = ScrollController();

  // Offset
  double scrollControllerOffset = 0;

  @override
  void initState() {
    super.initState();
    viewModel = AlbumViewModel(
      album: widget.album,
      catalog: context.read(),
      player: context.read(),
      blurhash: context.read(),
    );
    scrollController.addListener(scrollControllerListener);
  }

  void scrollControllerListener() {
    setState(() {
      scrollControllerOffset = scrollController.offset < 0
          ? 0
          : scrollController.offset;
    });
  }

  @override
  void dispose() {
    viewModel.dispose();
    scrollController.removeListener(scrollControllerListener);
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => _buildBody(context, size),
    );
  }

  Widget _buildBody(BuildContext context, Size size) {
    final blurhash = viewModel.blurhash ?? context.colors.defaultBlurhash;
    final tracks = viewModel.tracks;
    final missingTracks = viewModel.missingTracks;
    return ClipRRect(
      borderRadius: kIsDesktop ? BorderRadius.circular(15) : BorderRadius.zero,
      child: SizedBox(
        width: kIsDesktop ? 800 : size.width,
        height: kIsDesktop ? 500 : size.height,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: viewModel.showBody
              ? Stack(
                  key: ValueKey(blurhash),
                  children: [
                    SizedBox(
                      width: kIsDesktop ? 800 : size.width,
                      height: kIsDesktop ? 500 : size.height,
                      child: ClipRRect(
                        borderRadius: kIsDesktop
                            ? BorderRadius.circular(15)
                            : BorderRadius.zero,
                        child: BlurHash(hash: blurhash),
                      ),
                    ),
                    Container(
                      width: kIsDesktop ? 800 : size.width,
                      height: kIsDesktop ? 500 : size.height,
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(50),
                        borderRadius: kIsDesktop
                            ? BorderRadius.circular(15)
                            : null,
                      ),
                      child: Scaffold(
                        extendBodyBehindAppBar: true,
                        extendBody: true,
                        backgroundColor: Col.transp,
                        body: Theme(
                          data: ThemeData(
                            scrollbarTheme: kIsDesktop
                                ? ScrollbarThemeData(
                                    thumbColor: WidgetStateProperty.all(
                                      Colors.white.withAlpha(100),
                                    ),
                                  )
                                : null,
                          ),
                          child: Scrollbar(
                            controller: scrollController,
                            child: CustomScrollView(
                              controller: scrollController,
                              slivers: <Widget>[
                                SliverAppBarPhone(
                                  name: widget.album.name,
                                  tracks: tracks,
                                  scrollControllerOffset:
                                      scrollControllerOffset,
                                  image: widget.album.image,
                                ),
                                SliverPersistentHeader(
                                  pinned: true,
                                  delegate: StickyHeaderDelegate(
                                    minHeight: 40,
                                    maxHeight: 40,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        left: 15,
                                        right: 15,
                                        top: 5,
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            60,
                                          ),
                                          color: context.readSettings.useBlur
                                              ? Col.transp
                                              : context.colors.realBackground
                                                    .withAlpha(Dimens.noBlur),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            60,
                                          ),
                                          child: liquidGlassBackground(
                                            child: BackdropFilter(
                                              filter: nonAppleBlur(context, 10),
                                              child: PlayShuffleHaltAlbum(
                                                album: widget.album,
                                                missingTracks: missingTracks,
                                                loadingShuffle:
                                                    viewModel.loadingShuffle,
                                                play: viewModel.play,
                                                shuffle: viewModel.shuffle,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SliverToBoxAdapter(
                                  child: AlbumBodyPhone(
                                    album: widget.album,
                                    tracks: tracks,
                                    missingTracks: missingTracks,
                                    loading: viewModel.loading,
                                    play: (index) =>
                                        viewModel.play(index: index),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : loadingScaffold(context, const ValueKey(false)),
        ),
      ),
    );
  }
}

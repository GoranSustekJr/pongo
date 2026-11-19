import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/catalog/artist.dart';
import '../../../../utils/platform.dart';
import '../../../app/view_models/app_settings_view_model.dart';
import '../../../core/app_icons.dart';
import '../../../core/themes/colors.dart';
import '../../../core/ui/app_blur.dart';
import '../../../core/ui/image/image_compatible.dart';
import '../../../core/ui/phone/buttons/back_button.dart';
import '../../../core/ui/phone/liquid_glass_background.dart';
import '../../../core/ui/phone/loading_scaffold.dart';
import '../../../core/ui/space.dart';
import '../../../player/view_models/player_view_model.dart';
import '../../view_models/artist_view_model.dart';
import 'artist_body_phone.dart';

class ArtistPhone extends StatefulWidget {
  final BuildContext context;
  final Artist artist;
  const ArtistPhone({super.key, required this.artist, required this.context});

  @override
  State<ArtistPhone> createState() => _ArtistPhoneState();
}

class _ArtistPhoneState extends State<ArtistPhone> {
  late final ArtistViewModel viewModel;

  // Scroll controller
  final scrollController = ScrollController();

  // Offset
  double scrollControllerOffset = 0;

  @override
  void initState() {
    super.initState();
    viewModel = ArtistViewModel(
      artist: widget.artist,
      catalog: context.read(),
      history: context.read(),
      settings: context.read(),
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
      listenable: Listenable.merge([viewModel, context.player.fetchingTracks]),
      builder: (context, _) => _buildBody(context, size),
    );
  }

  Widget _buildBody(BuildContext context, Size size) {
    final blurhash = viewModel.blurhash ?? context.colors.defaultBlurhash;
    return ClipRRect(
      borderRadius: kIsDesktop ? BorderRadius.circular(15) : BorderRadius.zero,
      child: SizedBox(
        width: kIsDesktop ? 800 : size.width,
        height: kIsDesktop ? 500 : size.height,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: viewModel.showBody
              ? Stack(
                  children: [
                    SizedBox(
                      width: kIsDesktop ? 800 : size.width,
                      height: kIsDesktop ? 500 : size.height,
                      child: ClipRRect(
                        borderRadius: kIsDesktop
                            ? BorderRadius.circular(15)
                            : BorderRadius.zero,
                        child: BlurHash(
                          key: ValueKey(blurhash),
                          hash: blurhash,
                        ),
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
                              slivers: [
                                SliverAppBar(
                                  snap: false,
                                  collapsedHeight: kToolbarHeight,
                                  expandedHeight: kIsMacOS
                                      ? 400
                                      : MediaQuery.of(context).size.height / 2,
                                  floating: false,
                                  pinned: true,
                                  stretch: true,
                                  backgroundColor: Col.transp,
                                  surfaceTintColor: Col.transp,
                                  automaticallyImplyLeading: false,
                                  title: Row(
                                    children: [
                                      backButton(context),
                                      razw(15),
                                      Expanded(
                                        child: Text(
                                          widget.artist.name,
                                          style: const TextStyle(
                                            fontSize: 23,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  flexibleSpace: ClipRRect(
                                    borderRadius: kIsDesktop
                                        ? BorderRadius.circular(15)
                                        : BorderRadius.zero,
                                    child: FlexibleSpaceBar(
                                      titlePadding: EdgeInsets.zero,
                                      centerTitle: true,
                                      title: AppBar(
                                        surfaceTintColor: Col.transp,
                                        backgroundColor:
                                            context.readSettings.useBlur
                                            ? Col.transp
                                            : context.colors.realBackground.withAlpha(
                                                ((MediaQuery.of(context)
                                                                        .size
                                                                        .height /
                                                                    2 <=
                                                                scrollControllerOffset
                                                            ? 1
                                                            : scrollControllerOffset /
                                                                  (MediaQuery.of(
                                                                        context,
                                                                      ).size.height /
                                                                      2)) *
                                                        150)
                                                    .toInt(),
                                              ),
                                        automaticallyImplyLeading: false,
                                        flexibleSpace: Opacity(
                                          opacity:
                                              size.height / 2 <=
                                                  scrollControllerOffset
                                              ? 1
                                              : scrollControllerOffset /
                                                    (size.height / 2),
                                          child: ClipRRect(
                                            borderRadius: kIsDesktop
                                                ? BorderRadius.circular(15)
                                                : BorderRadius.zero,
                                            child: liquidGlassBackground(
                                              child: BackdropFilter(
                                                filter: nonAppleBlur(
                                                  context,
                                                  10,
                                                ),
                                                child: Container(),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      background: Stack(
                                        children: [
                                          Center(
                                            child: SizedBox(
                                              width: kIsMacOS
                                                  ? 300
                                                  : MediaQuery.of(context)
                                                            .size
                                                            .width -
                                                        60,
                                              height: kIsMacOS
                                                  ? 300
                                                  : MediaQuery.of(context)
                                                            .size
                                                            .width -
                                                        60,
                                              child: Center(
                                                child: Padding(
                                                  padding: EdgeInsets.only(
                                                    top: MediaQuery.of(context)
                                                        .padding
                                                        .top,
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          15,
                                                        ),
                                                    child:
                                                        widget.artist.image !=
                                                            ''
                                                        ? ImageCompatible(
                                                            image: widget
                                                                .artist
                                                                .image,
                                                          )
                                                        : Container(
                                                            width:
                                                                MediaQuery.of(
                                                                  context,
                                                                ).size.width -
                                                                60,
                                                            height:
                                                                MediaQuery.of(
                                                                  context,
                                                                ).size.width -
                                                                60,
                                                            decoration: BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    15,
                                                                  ),
                                                              color: context
                                                                  .colors
                                                                  .primaryCard,
                                                            ),
                                                            child: Center(
                                                              child: Icon(
                                                                AppIcons
                                                                    .blankArtist,
                                                                size: 70,
                                                              ),
                                                            ),
                                                          ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                SliverToBoxAdapter(
                                  child: ArtistBodyPhone(
                                    context: widget.context,
                                    artist: widget.artist,
                                    tracks: viewModel.tracks,
                                    albums: viewModel.albums,
                                    otherAlbums: viewModel.otherAlbums,
                                    artists: viewModel.artists,
                                    loading: context.player.fetchingTracks.value
                                        .toList(),
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

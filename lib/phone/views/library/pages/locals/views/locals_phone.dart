import 'dart:ui';

import 'package:pongo/exports.dart';
import 'package:pongo/phone/components/library/locals/play_shuffle_halt_locals.dart';
import 'package:pongo/phone/views/library/pages/locals/data/locals_data_manager.dart';
import 'package:pongo/phone/views/library/pages/locals/views/locals_body_phone.dart';

class LocalsPhone extends StatefulWidget {
  const LocalsPhone({super.key});

  @override
  State<LocalsPhone> createState() => _LocalsPhoneState();
}

class _LocalsPhoneState extends State<LocalsPhone> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return ChangeNotifierProvider(
      create: (_) => LocalsDataManager(
        context,
      ),
      child: Consumer<LocalsDataManager>(
        builder: (context, localsDataManager, child) {
          return AnimatedSwitcher(
            key: ValueKey(localsDataManager.showBody),
            duration: const Duration(milliseconds: 400),
            child: localsDataManager.showBody
                ? Container(
                    key: const ValueKey(true),
                    width: size.width,
                    height: size.height,
                    decoration: AppConstants().backgroundBoxDecoration,
                    child: Scaffold(
                      extendBodyBehindAppBar: true,
                      extendBody: true,
                      body: Scrollbar(
                          controller: localsDataManager.scrollController,
                          child: CustomScrollView(
                            controller: localsDataManager.scrollController,
                            slivers: [
                              SliverAppBar(
                                snap: true,
                                floating: true,
                                pinned: true,
                                stretch: true,
                                automaticallyImplyLeading: false,
                                expandedHeight: kIsApple
                                    ? size.height / 5
                                    : size.height / 4,
                                title: Row(
                                  children: [
                                    backButton(context),
                                    Expanded(
                                      child: Container(),
                                    ),
                                  ],
                                ),
                                flexibleSpace: ClipRRect(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 10, sigmaY: 10),
                                    child: FlexibleSpaceBar(
                                      centerTitle: true,
                                      title: Text(
                                        AppLocalizations.of(context)!
                                            .offlinesongs,
                                        style: TextStyle(
                                          fontSize: kIsApple ? 25 : 30,
                                          fontWeight: kIsApple
                                              ? FontWeight.w700
                                              : FontWeight.w800,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                      ),
                                      stretchModes: const [
                                        StretchMode.zoomBackground,
                                        StretchMode.blurBackground,
                                        StretchMode.fadeTitle,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SliverPersistentHeader(
                                pinned: true,
                                delegate: StickyHeaderDelegate(
                                  minHeight: 40,
                                  maxHeight: 40,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 15, right: 15, top: 5),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(60),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                            sigmaX: 10, sigmaY: 10),
                                        child: PlayShuffleHaltLocals(
                                          missingTracks: const [],
                                          loadingShuffle: false,
                                          edit: false,
                                          frontWidget: const SizedBox(),
                                          endWidget: const SizedBox(),
                                          play: localsDataManager.play,
                                          shuffle: localsDataManager.shuffle,
                                          stopEdit: () {},
                                          unfavourite: () {},
                                          addToPlaylist: () {},
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: localsDataManager.tracks.isNotEmpty
                                      ? SizedBox(
                                          key: const ValueKey(true),
                                          child:
                                              localsDataManager.tracks.isEmpty
                                                  ? Column(
                                                      children: [
                                                        razh(size.height / 3),
                                                        const Text("Empty"),
                                                      ],
                                                    )
                                                  : LocalsBodyPhone(
                                                      localsDataManager:
                                                          localsDataManager,
                                                    ),
                                        )
                                      : SingleChildScrollView(
                                          key: const ValueKey(false),
                                          child: Column(
                                            children: [
                                              ListView.builder(
                                                itemCount: localsDataManager
                                                    .numOfTracks,
                                                shrinkWrap: true,
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                itemBuilder: (context, index) {
                                                  return songTileSchimmer(
                                                      context,
                                                      index == 0,
                                                      index ==
                                                          localsDataManager
                                                              .numOfTracks--);
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          )),
                    ),
                  )
                : loadingScaffold(context, const ValueKey(false)),
          );
        },
      ),
    );
  }
}

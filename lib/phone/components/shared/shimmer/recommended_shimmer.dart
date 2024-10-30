import 'package:shimmer/shimmer.dart';

import '../../../../exports.dart';

class RecommendedShimmer extends StatelessWidget {
  final bool forYou;
  final bool pongo;
  const RecommendedShimmer(
      {super.key, required this.forYou, required this.pongo});

  @override
  Widget build(BuildContext context) {
    const double radius = 7.5;
    final TextStyle suggestionHeader = TextStyle(
      fontSize: kIsApple ? 24 : 19,
      fontWeight: kIsApple ? FontWeight.w700 : FontWeight.w700,
      color: Colors.white,
    );
    if (!forYou && !pongo) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Text(
            AppLocalizations.of(context)!.recommendationsdisabled,
            style: const TextStyle(fontSize: 17.5, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      return SizedBox(
        height: MediaQuery.of(context).size.height,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
                top: Scaffold.of(context).appBarMaxHeight == null
                    ? MediaQuery.of(context).padding.top +
                        AppBar().preferredSize.height +
                        20
                    : Scaffold.of(context).appBarMaxHeight! + 20,
                bottom: MediaQuery.of(context).padding.bottom + 10
                // bottom: MediaQuery.of(context).padding.bottom,
                ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                if (forYou)
                  searchResultText(
                      AppLocalizations.of(context)!.foryou, suggestionHeader),
                if (forYou) razh(10),
                if (forYou)
                  Shimmer.fromColors(
                    baseColor: Col.onIcon,
                    highlightColor: Col.background.withAlpha(50),
                    child: SizedBox(
                      height: 160,
                      width: MediaQuery.of(context).size.width,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(left: 10, right: 10),
                        itemCount: 25,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 7.5),
                            child: SizedBox(
                              height: 160,
                              width: 120,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  shimmContainer(120, 120, radius),
                                  razh(7.5),
                                  shimmContainer(100, 8, radius),
                                  razh(5),
                                  shimmContainer(70, 5, radius),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                if (forYou) razh(10),
                if (forYou)
                  Shimmer.fromColors(
                    baseColor: Col.onIcon,
                    highlightColor: Col.background.withAlpha(50),
                    child: SizedBox(
                      height: 160,
                      width: MediaQuery.of(context).size.width,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(left: 10, right: 10),
                        itemCount: 25,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 7.5),
                            child: SizedBox(
                              height: 160,
                              width: 120,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  shimmContainer(120, 120, radius),
                                  razh(7.5),
                                  shimmContainer(100, 8, radius),
                                  razh(5),
                                  shimmContainer(70, 5, radius),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                if (forYou) razh(30),
                if (forYou)
                  Shimmer.fromColors(
                    baseColor: Col.onIcon,
                    highlightColor: Col.background.withAlpha(50),
                    child: SizedBox(
                      height: 160,
                      width: MediaQuery.of(context).size.width,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(left: 10, right: 10),
                        itemCount: 25,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 7.5),
                            child: SizedBox(
                              height: 160,
                              width: 120,
                              child: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      shimmContainer(120, 120, 360),
                                      razh(7.5),
                                      shimmContainer(100, 8, radius),
                                      razh(5),
                                      shimmContainer(70, 5, radius),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                if (pongo) razh(30),
                if (pongo)
                  searchResultText(
                      AppLocalizations.of(context)!.tracks, suggestionHeader),
                if (pongo) razh(10),
                if (pongo)
                  Shimmer.fromColors(
                    baseColor: Col.onIcon,
                    highlightColor: Col.background.withAlpha(50),
                    child: SizedBox(
                      height: 160,
                      width: MediaQuery.of(context).size.width,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(left: 10, right: 10),
                        itemCount: 25,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 7.5),
                            child: SizedBox(
                              height: 160,
                              width: 120,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  shimmContainer(120, 120, radius),
                                  razh(7.5),
                                  shimmContainer(100, 8, radius),
                                  razh(5),
                                  shimmContainer(70, 5, radius),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                if (pongo) razh(10),
                if (pongo)
                  Shimmer.fromColors(
                    baseColor: Col.onIcon,
                    highlightColor: Col.background.withAlpha(50),
                    child: SizedBox(
                      height: 160,
                      width: MediaQuery.of(context).size.width,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(left: 10, right: 10),
                        itemCount: 25,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 7.5),
                            child: SizedBox(
                              height: 160,
                              width: 120,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  shimmContainer(120, 120, radius),
                                  razh(7.5),
                                  shimmContainer(100, 8, radius),
                                  razh(5),
                                  shimmContainer(70, 5, radius),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                if (pongo) razh(30),
                if (pongo)
                  searchResultText(
                      AppLocalizations.of(context)!.artists, suggestionHeader),
                if (pongo) razh(10),
                if (pongo)
                  Shimmer.fromColors(
                    baseColor: Col.onIcon,
                    highlightColor: Col.background.withAlpha(50),
                    child: SizedBox(
                      height: 160,
                      width: MediaQuery.of(context).size.width,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(left: 10, right: 10),
                        itemCount: 25,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 7.5),
                            child: SizedBox(
                              height: 160,
                              width: 120,
                              child: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      shimmContainer(120, 120, 360),
                                      razh(7.5),
                                      shimmContainer(100, 8, radius),
                                      razh(5),
                                      shimmContainer(70, 5, radius),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                if (pongo) razh(30),
                if (pongo)
                  searchResultText(AppLocalizations.of(context)!.newalbums,
                      suggestionHeader),
                if (pongo) razh(10),
                if (pongo)
                  Shimmer.fromColors(
                    baseColor: Col.onIcon,
                    highlightColor: Col.background.withAlpha(50),
                    child: SizedBox(
                      height: 160,
                      width: MediaQuery.of(context).size.width,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(left: 10, right: 10),
                        itemCount: 25,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 7.5),
                            child: SizedBox(
                              height: 160,
                              width: 120,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  shimmContainer(120, 120, radius),
                                  razh(7.5),
                                  shimmContainer(100, 8, radius),
                                  razh(5),
                                  shimmContainer(70, 5, radius),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                if (pongo) razh(30),
                if (pongo)
                  searchResultText(AppLocalizations.of(context)!.playlists,
                      suggestionHeader),
                if (pongo) razh(10),
                if (pongo)
                  Shimmer.fromColors(
                    baseColor: Col.onIcon,
                    highlightColor: Col.background.withAlpha(50),
                    child: SizedBox(
                      height: 160,
                      width: MediaQuery.of(context).size.width,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(left: 10, right: 10),
                        itemCount: 25,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 7.5),
                            child: SizedBox(
                              height: 160,
                              width: 120,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  shimmContainer(120, 120, radius),
                                  razh(7.5),
                                  shimmContainer(100, 8, radius),
                                  razh(5),
                                  shimmContainer(70, 5, radius),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
  }
}

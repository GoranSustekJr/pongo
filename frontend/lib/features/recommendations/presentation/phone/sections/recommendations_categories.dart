// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

class RecommendationsCategories extends StatelessWidget {
  final RecommendationsDataManager dataManager;
  final AudioServiceHandler audioServiceHandler;

  const RecommendationsCategories({
    super.key,
    required this.dataManager,
    required this.audioServiceHandler,
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Column(
      children: [
        if (dataManager.categories.isNotEmpty ||
            dataManager.newReleases.isNotEmpty)
          searchResultText(
              AppLocalizations.of(context).explore,
              TextStyle(
                fontSize: kIsApple ? 24 : 25,
                fontWeight: kIsApple ? FontWeight.w700 : FontWeight.w700,
                color: Col.text,
              )),
        if (dataManager.categories.isNotEmpty ||
            dataManager.newReleases.isNotEmpty)
          razh(10),
        if (dataManager.newReleases.isNotEmpty)
          SizedBox(
            height: kIsDesktop ? 200 : 160,
            width: MediaQuery.of(context).size.width,
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 10, right: 10),
              itemCount: dataManager.newReleases.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return RecommendedTile(
                  data: dataManager.newReleases[index],
                  type: TileType.album,
                  showLoading: false,
                  onTap: () {
                    if (kIsMobile) {
                      Navigations().nextScreen(
                          context,
                          AlbumPhone(
                            album: dataManager.newReleases[index],
                            context: context,
                          ));
                    } else {
                      showMacosSheet(
                        context: context,
                        builder: (contextt) => AlbumPhone(
                          album: dataManager.newReleases[index],
                          context: contextt,
                        ),
                        routeSettings: const RouteSettings(),
                      );
                    }
                  },
                );
              },
            ),
          ),
        if (dataManager.categories.isNotEmpty) razh(10),
        if (dataManager.categories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7.5),
            child: GridView.builder(
              padding: const EdgeInsets.only(
                top: 0,
                // bottom: MediaQuery.of(context).padding.bottom + 10,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: kIsDesktop
                    ? size.width > 1200
                        ? 4
                        : 3
                    : 2,
                childAspectRatio: 120 / 80,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: dataManager.categories.length,
              itemBuilder: (context, index) {
                Widget child = Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7.5),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(7.5),
                        child: ImageCompatible(
                          image: dataManager
                              .categories[index].categoryIcons[0].url,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7.5),
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.5),
                                Colors.black.withOpacity(0.8),
                                Colors.black.withOpacity(0.5),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              dataManager.categories[index].name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
                return kIsApple
                    ? CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          if (searchDataManagr.value != null) {
                            if (kIsMobile) {
                              searchDataManagr.value!.search(
                                dataManager.categories[index].name,
                              );
                              navigationBarIndex.value = 0;
                              searchBarIsSearching.value = true;
                            } else {
                              searchDataManagr.value!.search(
                                dataManager.categories[index].name,
                              );
                              navigationBarIndex.value = 0;
                              searchBarIsSearching.value = true;
                            }
                          }
                        },
                        child: child,
                      )
                    : CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          if (searchDataManagr.value != null) {
                            searchDataManagr.value!.search(
                              dataManager.categories[index].name,
                            );
                            navigationBarIndex.value = 0;
                            searchBarIsSearching.value = true;
                          }
                        },
                        child: child,
                      );
              },
            ),
          ),
      ],
    );
  }
}

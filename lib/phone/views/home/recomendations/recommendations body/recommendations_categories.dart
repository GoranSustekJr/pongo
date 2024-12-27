import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';
import 'package:pongo/phone/views/home/recomendations/recommendations_data_manager.dart';

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
    return Column(
      children: [
        if (dataManager.history.isNotEmpty)
          searchResultText(AppLocalizations.of(context)!.explore,
              dataManager.suggestionHeader),
        if (dataManager.history.isNotEmpty) razh(10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7.5),
          child: GridView.builder(
            padding: const EdgeInsets.only(
              top: 0,
              // bottom: MediaQuery.of(context).padding.bottom + 10,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
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
                        image:
                            dataManager.categories[index].categoryIcons[0].url,
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
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                      onPressed: () async {
                        print(dataManager.categories[index].name);
                        print(dataManager.categories[index].id);
                        if (searchDataManagr.value != null) {
                          searchDataManagr.value!.search(
                            "tag:${dataManager.categories[index].name}",
                          );
                          navigationBarIndex.value = 0;
                          searchBarIsSearching.value = true;
                        }
                      },
                      child: child,
                    )
                  : CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {},
                      child: child,
                    );
            },
          ),
        ),
      ],
    );
  }
}

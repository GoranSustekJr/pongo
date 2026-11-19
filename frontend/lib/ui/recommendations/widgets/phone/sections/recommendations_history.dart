import 'package:flutter/material.dart';

import 'package:pongo/app/theme/colors.dart';
import 'package:pongo/core/audio/audio_service_handler.dart';
import 'package:pongo/core/constants/platform.dart';
import 'package:pongo/core/state/globals.dart';
import 'package:pongo/features/player/data/mix_api.dart';
import 'package:pongo/features/player/data/play.dart';
import 'package:pongo/features/recommendations/data/recommendations_data_manager.dart';
import 'package:pongo/features/recommendations/presentation/phone/recommended_tile.dart';
import 'package:pongo/features/search/presentation/phone/search_result_text.dart';
import 'package:pongo/features/search/presentation/phone/search_result_tile.dart';
import 'package:pongo/l10n/app_localizations.dart';
import 'package:pongo/shared/widgets/phone/trailing.dart';
import 'package:pongo/shared/widgets/space.dart';

class RecommendationsHistory extends StatelessWidget {
  final RecommendationsDataManager dataManager;
  final AudioServiceHandler audioServiceHandler;
  const RecommendationsHistory(
      {super.key,
      required this.dataManager,
      required this.audioServiceHandler});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (dataManager.history.isNotEmpty)
          searchResultText(
              AppLocalizations.of(context).lastlistenedto,
              TextStyle(
                fontSize: kIsApple ? 24 : 25,
                fontWeight: kIsApple ? FontWeight.w700 : FontWeight.w700,
                color: Col.text,
              )),
        if (dataManager.history.isNotEmpty) razh(10),
        if (dataManager.history.isNotEmpty)
          SizedBox(
            height: kIsDesktop ? 200 : 160,
            width: MediaQuery.of(context).size.width,
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 10, right: 10),
              itemCount: dataManager.history.length > 25
                  ? 25
                  : dataManager.history.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return RecommendedTile(
                  data: dataManager.history[index],
                  showLoading: dataManager.loading
                      .contains(dataManager.history[index].id),
                  type: TileType.track,
                  onTap: () async {
                    //print(calculateBestImageForTrack(dataManager.history[index]));
                    await PlaySingle().onlineTrack(
                      context,
                      audioServiceHandler,
                      "recommended.single.",
                      dataManager.history[index],
                      dataManager.loadingAdd,
                      dataManager.loadingRemove,
                    );
                    if (useMix.value) {
                      MixApi().getMix(context, dataManager.history[index]);
                    }
                  },
                  doesNotExist: dataManager.loadingAdd,
                  doesNowExist: dataManager.loadingRemove,
                  trailing: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: dataManager.loading
                            .contains(dataManager.history[index].id)
                        ? const CircularProgressIndicator.adaptive(
                            key: ValueKey(true),
                          )
                        : StreamBuilder(
                            key: const ValueKey(false),
                            stream: audioServiceHandler.mediaItem.stream,
                            builder: (context, snapshot) {
                              final String id = snapshot.data != null
                                  ? snapshot.data!.id.split(".")[2]
                                  : "";

                              return id == dataManager.history[index].id
                                  ? StreamBuilder(
                                      stream: audioServiceHandler
                                          .audioPlayer.playingStream,
                                      builder: (context, playingStream) {
                                        return Trailing(
                                          forceWhite: false,
                                          show: !dataManager.loading.contains(
                                              dataManager.history[index].id),
                                          showThis: id ==
                                              dataManager.history[index].id,
                                          trailing: const Padding(
                                            padding: EdgeInsets.only(right: 10),
                                            child: CircularProgressIndicator
                                                .adaptive(
                                              key: ValueKey(true),
                                            ),
                                          ),
                                        );
                                      })
                                  : const SizedBox();
                            },
                          ),
                  ),
                );
              },
            ),
          ),
        if (dataManager.history.isNotEmpty && dataManager.history.length > 25)
          razh(10),
        if (dataManager.history.isNotEmpty && dataManager.history.length > 25)
          SizedBox(
            height: kIsDesktop ? 200 : 160,
            width: MediaQuery.of(context).size.width,
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 10, right: 10),
              itemCount: dataManager.history.length - 25 > 0
                  ? dataManager.history.length - 25
                  : 0,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return RecommendedTile(
                  data: dataManager.history[25 + index],
                  showLoading: dataManager.loading
                      .contains(dataManager.history[25 + index].id),
                  type: TileType.track,
                  onTap: () async {
                    await PlaySingle().onlineTrack(
                      context,
                      audioServiceHandler,
                      "recommended.single.",
                      dataManager.history[25 + index],
                      dataManager.loadingAdd,
                      dataManager.loadingRemove,
                    );
                    if (useMix.value) {
                      MixApi().getMix(context, dataManager.history[25 + index]);
                    }
                  },
                  doesNotExist: dataManager.loadingAdd,
                  doesNowExist: dataManager.loadingRemove,
                  trailing: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: dataManager.loading
                            .contains(dataManager.history[25 + index].id)
                        ? const CircularProgressIndicator.adaptive(
                            key: ValueKey(true),
                          )
                        : StreamBuilder(
                            key: const ValueKey(false),
                            stream: audioServiceHandler.mediaItem.stream,
                            builder: (context, snapshot) {
                              final String id = snapshot.data != null
                                  ? snapshot.data!.id.split(".")[2]
                                  : "";

                              return id == dataManager.history[25 + index].id
                                  ? StreamBuilder(
                                      stream: audioServiceHandler
                                          .audioPlayer.playingStream,
                                      builder: (context, playingStream) {
                                        return Trailing(
                                          forceWhite: false,
                                          show: !dataManager.loading.contains(
                                              dataManager
                                                  .history[25 + index].id),
                                          showThis: id ==
                                              dataManager
                                                  .history[25 + index].id,
                                          trailing: const Padding(
                                            padding: EdgeInsets.only(right: 10),
                                            child: CircularProgressIndicator
                                                .adaptive(
                                              key: ValueKey(true),
                                            ),
                                          ),
                                        );
                                      })
                                  : const SizedBox();
                            },
                          ),
                  ),
                );
              },
            ),
          ),
        if (dataManager.history.isNotEmpty) razh(30),
      ],
    );
  }
}

import 'package:fading_edge_scrollview/fading_edge_scrollview.dart';
import '../../../../exports.dart';

class TrackPlainLyricsPhone extends StatelessWidget {
  final List<dynamic> lyrics;
  TrackPlainLyricsPhone({super.key, required this.lyrics});

  // Scroll controler for fade
  final ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: SizedBox(
        height: size.height,
        width: size.width - 20,
        child: Center(
          child: Scrollbar(
            controller: scrollController,
            child: FadingEdgeScrollView.fromSingleChildScrollView(
              gradientFractionOnStart: 0.8,
              gradientFractionOnEnd: 0.8,
              child: SingleChildScrollView(
                controller: scrollController,
                physics: const ScrollPhysics(),
                child: lyrics[0] == ""
                    ? Column(
                        children: [
                          Text(
                            AppLocalizations.of(context)!.noplainlyrics,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 29),
                          ),
                          Text(
                            AppLocalizations.of(context)!.wanttohelpoutlyrics,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 15),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          razh(size.height / 2 -
                              AppBar().preferredSize.height -
                              MediaQuery.of(context).padding.top),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            itemCount: lyrics.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 0),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: SizedBox(
                                            width: size.width - 20,
                                            child: Text(
                                              "${lyrics[index]}\n\n",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize:
                                                      lyrics[index] == " \n"
                                                          ? 15
                                                          : 35,
                                                  height: lyrics[index] == " "
                                                      ? 0.5
                                                      : 1.5),
                                              maxLines: null,
                                              softWrap: true,
                                              textAlign: TextAlign
                                                  .center, // TODO: Left or center lyrics on SETTINGS!
                                            ),
                                          ),
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
                          razh(size.height / 2),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

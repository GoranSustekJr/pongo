import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';
import 'package:pongo/phone/components/shared/tiles/search_history_tile.dart';

class SearchHistoryPhone extends StatefulWidget {
  final List<String> searchHistory;
  final Function(String) search;
  final Function() removeItem;
  const SearchHistoryPhone({
    super.key,
    required this.search,
    required this.searchHistory,
    required this.removeItem,
  });

  @override
  State<SearchHistoryPhone> createState() => _SearchHistoryPhoneState();
}

class _SearchHistoryPhoneState extends State<SearchHistoryPhone> {
  bool clear = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height -
          MediaQuery.of(context).viewInsets.bottom,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Col.primaryCard.withAlpha(150),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(
                top: 0,
                left: 20,
              ),
              child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    razh(
                      Scaffold.of(context).appBarMaxHeight == null
                          ? MediaQuery.of(context).padding.top +
                              AppBar().preferredSize.height +
                              20
                          : Scaffold.of(context).appBarMaxHeight! + 20,
                    ),
                    if (widget.searchHistory.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.zero,
                        child: Row(
                          children: [
                            textButtonNoPadding(
                              clear
                                  ? AppLocalizations.of(context)!.cancel
                                  : AppLocalizations.of(context)!
                                      .clearallhistory,
                              () {
                                setState(() {
                                  clear = !clear;
                                });
                              },
                              TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w300,
                                color: Colors.white.withAlpha(200),
                              ),
                            ),
                            const Expanded(child: SizedBox()),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              width: !clear ? 50 : 0,
                              child: SizedBox(
                                width: 50,
                                height: 40,
                                child: CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () async {
                                    await DatabaseHelper().clearSearchHistory();
                                    widget.removeItem();
                                  },
                                  child:
                                      Icon(AppIcons.trash, color: Colors.red),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.searchHistory.length,
                      itemBuilder: (context, index) {
                        return searchHistoryTile(widget.searchHistory[index],
                            widget.searchHistory.length - 1 == index, () {
                          widget.search(widget.searchHistory[index]);
                        }, () {
                          widget.removeItem();
                        });
                      },
                    ),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}

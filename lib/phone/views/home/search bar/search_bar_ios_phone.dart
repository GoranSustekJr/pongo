import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';
import 'package:pongo/phone/widgets/special/liquid_glass_background.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:pongo/phone/widgets/special/liquid_glass_render.dart';

class SearchBarIOSPhone extends StatefulWidget {
  final Function(String) onFieldSubmitted;
  final Function(bool) setShowSearchHistory;
  final Function(String) onChanged;
  final FocusNode focusNode;
  final TextEditingController searchController;
  const SearchBarIOSPhone({
    super.key,
    required this.onFieldSubmitted,
    required this.setShowSearchHistory,
    required this.onChanged,
    required this.focusNode,
    required this.searchController,
  });

  @override
  State<SearchBarIOSPhone> createState() => _SearchBarIOSPhoneState();
}

class _SearchBarIOSPhoneState extends State<SearchBarIOSPhone> {
  // Is Searching
  bool searching = false;

  // Search Text Controller
  TextEditingController searchController = TextEditingController(text: '');

  // Query / Inserted Text
  String? query;

  // Constant Text Form Field Border
  OutlineInputBorder border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(
      color: Col.transp,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Scaffold.of(context).appBarMaxHeight == null
          ? MediaQuery.of(context).padding.top + AppBar().preferredSize.height
          : Scaffold.of(context).appBarMaxHeight! + 20,
      child: AppBar(
        backgroundColor: Col.transp,
        shadowColor: Col.transp,
        surfaceTintColor: Col.transp,
        title: liquidGlassLayer(
          thickness: 15,
          child: liquidGlass(
            child: Row(
              children: [
                Flexible(
                  child: AnimatedPadding(
                    duration: Duration(milliseconds: animations ? 150 : 0),
                    padding: EdgeInsets.only(
                        right: searchBarIsSearching.value ? 5 : 0),
                    child: Focus(
                      onFocusChange: (hasFocus) {
                        if (widget.focusNode.hasFocus) {
                          widget.setShowSearchHistory(true);
                        } else {
                          widget.setShowSearchHistory(false);
                        }
                        setState(() {
                          searching = hasFocus;
                        });
                      },
                      child: liquidGlass(
                        blur: 0,
                        child: CupertinoSearchTextField(
                          controller: widget.searchController,
                          focusNode: widget.focusNode,
                          onChanged: (value) {
                            setState(() {
                              query = value;
                            });
                            widget.onChanged(value);
                          },
                          onTap: () {
                            setState(() {
                              searching = true;
                              searchBarIsSearching.value = true;
                            });
                          },
                          onSubmitted: (qry) {
                            widget.setShowSearchHistory(false);
                            widget.onFieldSubmitted(qry); // Callback
                            widget.focusNode.unfocus();
                          },
                          placeholder: AppLocalizations.of(context).search,
                          placeholderStyle:
                              TextStyle(color: Col.text.withAlpha(215)),
                          /* backgroundColor: Col.primaryCard
                              .withAlpha(useBlur.value ? 150 : 245), */
                          style: TextStyle(color: Col.text),
                          itemColor: Col.icon,
                        ),
                      ),
                    ),
                  ),
                ),
                if (searchBarIsSearching.value || widget.focusNode.hasFocus)
                  liquidGlass(
                    blur: 0,
                    child: CupertinoButton(
                      sizeStyle: CupertinoButtonSize.medium,
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        if (searchBarIsSearching.value ||
                            widget.focusNode.hasFocus) {
                          setState(() {
                            searching = false;
                            searchBarIsSearching.value = false;
                          });
                          widget.focusNode.unfocus();
                          searchController.clear();
                          widget.onFieldSubmitted(
                              ""); // Set Empty Query In Parent Widget
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 5, left: 5),
                        child: Text(
                          AppLocalizations.of(context).cancel,
                          style: TextStyle(
                              color: Col.text.withAlpha(200), fontSize: 20),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // flexibleSpace: kIsApple ? liquidGlassBackground() : appBarBlur(),
      ),
    );
  }
}

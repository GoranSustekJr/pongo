import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../app/view_models/app_settings_view_model.dart';
import '../../../../core/themes/colors.dart';
import '../../../../shell/view_models/shell_view_model.dart';

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
  static const double height = 44;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(onFocusChange);
    super.dispose();
  }

  void onFocusChange() {
    final hasFocus = widget.focusNode.hasFocus;
    widget.setShowSearchHistory(hasFocus);
    if (hasFocus) context.shell.searchBarIsSearching.value = true;
  }

  // Leaves search and returns to the home screen
  void cancel() {
    context.shell.searchBarIsSearching.value = false;
    widget.focusNode.unfocus();
    widget.setShowSearchHistory(false);
    widget.searchController.clear();
    widget.onChanged('');
    widget.onFieldSubmitted(''); // Set Empty Query In Parent Widget
  }

  // Glass dark enough that the field stays readable over artwork
  LiquidGlassSettings get settings => context.readSettings.darkMode
      ? LiquidGlassSettings.ios27Dark.copyWith(
          glassColor: const Color(0x991C1C1E),
        )
      : LiquidGlassSettings.ios27Light.copyWith(
          glassColor: const Color(0xB3F2F2F7),
        );

  Widget clearButton() {
    return ValueListenableBuilder(
      valueListenable: widget.searchController,
      builder: (context, value, child) {
        if (value.text.isEmpty) return const SizedBox.shrink();
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            widget.searchController.clear();
            widget.onChanged('');
            widget.focusNode.requestFocus();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              CupertinoIcons.clear_circled_solid,
              size: 18,
              color: context.colors.text.withAlpha(150),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.readSettings.useLiquidGlass;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
        child: ValueListenableBuilder(
          valueListenable: context.shell.searchBarIsSearching,
          builder: (context, searching, child) {
            return Row(
              children: [
                Expanded(
                  // The whole capsule focuses the field, not only the text
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.focusNode.requestFocus,
                    child: GlassTextField.search(
                      controller: widget.searchController,
                      focusNode: widget.focusNode,
                      height: height,
                      shape: const LiquidRoundedRectangle(
                        borderRadius: height / 2,
                      ),
                      useOwnLayer: true,
                      settings: glass ? settings : null,
                      surfaceStyle: glass
                          ? GlassSurfaceStyle.glass
                          : GlassSurfaceStyle.solid,
                      color: glass ? null : Col.searchBarBackground,
                      placeholder: AppLocalizations.of(context).search,
                      placeholderStyle: TextStyle(
                        color: context.colors.text.withAlpha(150),
                      ),
                      textStyle: TextStyle(
                        color: context.colors.text,
                        fontSize: 17,
                      ),
                      prefixIcon: Icon(
                        CupertinoIcons.search,
                        size: 20,
                        color: context.colors.text.withAlpha(150),
                      ),
                      suffixIcon: clearButton(),
                      // Keep the keyboard while a history entry is tapped
                      onTapOutside: (_) {},
                      onChanged: widget.onChanged,
                      onSubmitted: (qry) {
                        widget.setShowSearchHistory(false);
                        widget.onFieldSubmitted(qry); // Callback
                        widget.focusNode.unfocus();
                      },
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: Duration(
                    milliseconds: context.readSettings.useAnimations ? 250 : 0,
                  ),
                  curve: Curves.easeInOutCubic,
                  child: searching
                      ? Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: GlassButton(
                            onTap: cancel,
                            label: AppLocalizations.of(context).cancel,
                            width: height,
                            height: height,
                            useOwnLayer: true,
                            settings: glass ? settings : null,
                            icon: Icon(
                              CupertinoIcons.xmark,
                              size: 18,
                              color: context.colors.text,
                            ),
                          ),
                        )
                      : const SizedBox(height: height),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

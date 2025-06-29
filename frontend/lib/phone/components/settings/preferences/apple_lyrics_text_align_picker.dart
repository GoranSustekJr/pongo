import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

appleLyricsTextAlignPicker(context, int initial, Function(int) onChanged) {
  showCupertinoModalPopup(
    context: context,
    builder: (context) {
      return ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            height: 300,
            width: MediaQuery.of(context).size.width,
            color: Col.primaryCard.withAlpha(150),
            child: CupertinoPicker(
              itemExtent: 50,
              onSelectedItemChanged: onChanged,
              scrollController: FixedExtentScrollController(
                initialItem: initial,
              ),
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 20,
                    ),
                    Center(
                      child: Text(
                        AppLocalizations.of(context).leftalignment,
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
                Center(
                  child: Text(
                    AppLocalizations.of(context).centeralignment,
                    textAlign: TextAlign.center,
                  ),
                ),
                Row(
                  children: [
                    Expanded(child: Container()),
                    Center(
                      child: Text(
                        AppLocalizations.of(context).rightalignment,
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context).justify,
                          textAlign: TextAlign.justify,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context).alignment,
                          textAlign: TextAlign.justify,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

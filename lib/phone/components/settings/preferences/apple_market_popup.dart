import 'package:flutter/cupertino.dart';
import '../../../../exports.dart';

appleMarketPopup(context, String market, Function(String) function) {
  showCupertinoModalPopup(
    context: context,
    builder: (context) => CupertinoActionSheet(
      title: Text(AppLocalizations.of(context).selectmarket),
      message: Text(AppLocalizations.of(context).selectmarketbody),
      actions: List.generate(
        markets.length,
        (index) => CupertinoActionSheetAction(
          isDestructiveAction: true,
          isDefaultAction: true,
          onPressed: () {
            function(markets[index]);
            Navigator.of(context).pop();
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "${markets[index]} - ${marketsCountryNames[markets[index]]}",
              style: TextStyle(
                  color: market == markets[index] ? Colors.blue : Colors.white,
                  fontWeight: FontWeight.w400),
            ),
          ),
        ),
      ),
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        onPressed: () {
          Navigator.pop(context);
        },
        child: Text(
          AppLocalizations.of(context).cancel,
          style: TextStyle(
            fontSize: kIsApple ? 22.5 : 18,
            fontWeight: kIsApple ? FontWeight.w500 : FontWeight.w600,
            color: Col.error.withAlpha(175),
          ),
        ),
      ),
    ),
  );
}

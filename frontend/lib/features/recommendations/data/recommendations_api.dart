import 'package:pongo/core/network/api_client.dart';
import 'package:pongo/core/storage/database/database_helper.dart';
import 'package:pongo/core/storage/secure_storage.dart';

class Recommendations {
  Future<Map> get(context) async {
    return const ApiClient().postBuilt(context, "get_recommendations",
        () async {
      String market = await Storage().getMarket() ?? 'US';
      List<String> history = await DatabaseHelper().queryTrackHistoryNum(50);

      int categoriesNum = await Storage().getNumOfCategories();
      String locale = await Storage().getLocale() ?? 'en';
      return {
        "market": market,
        "history": history,
        "category_num": categoriesNum,
        "locale": locale,
      };
    });
  }
}

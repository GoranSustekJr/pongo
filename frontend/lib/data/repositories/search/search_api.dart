import 'package:pongo/core/network/api_client.dart';
import 'package:pongo/core/storage/secure_storage.dart';

class SearchApi {
  Future<Map> search(context, String q) async {
    return const ApiClient().postBuilt(context, "search_spotify", () async {
      String market = await Storage().getMarket() ?? 'US';
      return {
        "query": q,
        "market": market,
      };
    });
  }
}

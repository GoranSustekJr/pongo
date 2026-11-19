import 'package:pongo/core/network/api_client.dart';
import 'package:pongo/core/storage/secure_storage.dart';

class ArtistApi {
  // Initialize the API

  Future<Map> get(context, String said) async {
    return const ApiClient().postBuilt(context, "get_artist_metadata",
        () async {
      String market = await Storage().getMarket() ?? 'US';
      return {
        "said": said,
        "market": market,
      };
    });
  }

// Get artist image
  Future<Map> getImage(context, String said) async {
    return const ApiClient().post(context,
        "caf5cc332d474f35ff74e94af44f2a7801b620b2ce0196560e038b511d14986e", {
      "said": said,
    });
  }
}

import 'package:pongo/core/network/api_client.dart';

class PlaylistSpotify {
  // Initialize the API

  Future<Map> get(context, String spid) async {
    return const ApiClient().postBuilt(context, "get_playlist", () async {
      //print(accessTokenHandler.accessToken);
      return {
        "spid": spid,
      };
    });
  }

  Future<Map> getShuffle(context, String spid) async {
    return const ApiClient().post(context, "get_playlist_shuffle", {
      "spid": spid,
    });
  }
}

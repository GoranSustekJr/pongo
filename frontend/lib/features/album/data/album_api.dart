import 'package:pongo/core/network/api_client.dart';

class AlbumSpotify {
  // Initialize the API

  Future<Map> getData(context, String salid) async {
    return const ApiClient().post(context, "get_album_data", {
      "salid": salid,
    });
  }

  Future<Map> getTracks(context, String salid) async {
    return const ApiClient().post(context, "get_album", {
      "salid": salid,
    });
  }

  Future<Map> getShuffle(context, String said) async {
    return const ApiClient().post(context, "get_album_shuffle", {
      "said": said,
    });
  }
}

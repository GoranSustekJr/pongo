import 'package:pongo/core/network/api_client.dart';

class SearializedData {
  Future<Map> tracks(context, List<String> stids) async {
    return const ApiClient().post(context, "get_serialized_tracks", {
      "stids": stids,
    });
  }

  Future<Map> getShuffle(context, List<String> stids) async {
    return const ApiClient().post(context, "get_serialized_shuffle", {
      "stids": stids,
    });
  }
}

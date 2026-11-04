import 'package:pongo/core/network/api_client.dart';

class Tracks {
  Future<Map> getDurations(context, List<String> stids) async {
    return const ApiClient().post(context, "get_serialized_shuffle", {
      "stids": stids,
    });
  }
}

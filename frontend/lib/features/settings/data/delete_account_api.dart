import 'package:pongo/core/network/api_client.dart';
import 'package:pongo/features/auth/data/sign_in_handler.dart';

class DeleteAccount {
  // Initialize the API

  Future delete(context) async {
    try {
      final response = await const ApiClient()
          .send(context, "delete_account", () async => {});
      if (response != null) await SignInHandler().signOut(context);
    } catch (e) {
      return {};
    }
    return {};
  }
}
